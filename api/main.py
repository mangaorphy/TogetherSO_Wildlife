"""
FastAPI Backend for EcoSight Wildlife Threat Detection
Uses YAMNet model to classify audio threats
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import numpy as np
import librosa
import io
import datetime
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
import logging
import os
import tensorflow_hub as hub
import tensorflow as tf

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="EcoSight Wildlife Detection API",
    description="Audio threat detection using YAMNet model",
    version="1.0.0"
)

# Configure CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables
KERAS_MODEL_PATH = "/Users/cococe/Desktop/TogetherSO_Wildlife/togetherso_yamnet_model_v2_improved.keras"
YAMNET_MODEL_URL = 'https://tfhub.dev/google/yamnet/1'
keras_classifier = None  # Keras model for classification
yamnet_model = None  # YAMNet for feature extraction

# Threat classes mapping
THREAT_CLASSES = {
    0: "gun_shot",
    1: "human_voices",
    2: "engine_idling",
    3: "dog_bark"
}

# Priority mapping
PRIORITY_MAP = {
    "gun_shot": "CRITICAL",
    "human_voices": "HIGH",
    "engine_idling": "MEDIUM",
    "dog_bark": "LOW"
}

# Audio preprocessing parameters
SAMPLE_RATE = 16000  # YAMNet uses 16kHz
MAX_DURATION = 4  # seconds (same as training)


class DetectionResponse(BaseModel):
    """Response model for detection"""
    id: str
    predicted_class: str
    confidence: float
    timestamp: str
    latitude: float
    longitude: float
    status: str
    priority: str
    all_predictions: Dict[str, float]


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    model_loaded: bool
    timestamp: str


def load_model():
    """Load YAMNet and Keras classifier models"""
    global keras_classifier, yamnet_model
    
    try:
        # Load YAMNet for feature extraction
        logger.info(f"Loading YAMNet model from TensorFlow Hub...")
        yamnet_model = hub.load(YAMNET_MODEL_URL)
        logger.info("✓ YAMNet model loaded successfully!")
        
        # Load Keras classifier
        logger.info(f"Loading Keras classifier from {KERAS_MODEL_PATH}...")
        import tensorflow as tf
        keras_classifier = tf.keras.models.load_model(KERAS_MODEL_PATH)
        
        logger.info("✓ Keras classifier loaded successfully!")
        logger.info(f"Input shape: {keras_classifier.input_shape}")
        logger.info(f"Output shape: {keras_classifier.output_shape}")
        
        return True
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        import traceback
        traceback.print_exc()
        return False


def preprocess_audio(audio_bytes: bytes) -> np.ndarray:
    """
    Preprocess audio file and extract YAMNet embeddings
    
    Args:
        audio_bytes: Raw audio file bytes
        
    Returns:
        YAMNet embeddings (1024-dimensional vector) ready for classifier
    """
    try:
        # Check if audio bytes are valid
        if len(audio_bytes) == 0:
            raise ValueError("Empty audio file received")
        
        logger.info(f"Loading audio file ({len(audio_bytes)} bytes)...")
        
        # Load audio from bytes at 16kHz (YAMNet requirement)
        audio_data, sr = librosa.load(io.BytesIO(audio_bytes), sr=SAMPLE_RATE, mono=True)
        
        # Check if audio loaded successfully
        if audio_data is None or len(audio_data) == 0:
            raise ValueError("Failed to load audio or audio is empty")
        
        logger.info(f"Audio loaded: {len(audio_data)} samples at {sr} Hz ({len(audio_data)/sr:.2f} seconds)")
        
        # Limit to max duration
        max_samples = SAMPLE_RATE * MAX_DURATION
        if len(audio_data) > max_samples:
            audio_data = audio_data[:max_samples]
            logger.info(f"Audio trimmed to {MAX_DURATION} seconds")
        
        # Check if audio has content
        if len(audio_data) < 160:  # Minimum ~10ms at 16kHz
            raise ValueError(f"Audio too short: {len(audio_data)} samples ({len(audio_data)/sr*1000:.1f}ms)")
        
        # Normalize to [-1, 1] range (YAMNet requirement)
        max_val = np.max(np.abs(audio_data))
        if max_val > 0:
            audio_data = audio_data / max_val
        else:
            logger.warning("Audio is silent (all zeros), using as-is")
            # For silent audio, just use zeros - YAMNet can handle it
        
        # Convert to float32
        audio_tensor = audio_data.astype(np.float32)
        
        logger.info(f"Audio prepared: shape {audio_tensor.shape}, range [{audio_tensor.min():.3f}, {audio_tensor.max():.3f}]")
        
        # Extract YAMNet embeddings
        # YAMNet returns: (scores, embeddings, spectrogram)
        logger.info("Extracting YAMNet embeddings...")
        scores, embeddings, spectrogram = yamnet_model(audio_tensor)
        
        # Average embeddings across time (if multiple frames)
        # Shape: (num_frames, 1024) -> (1024,)
        embedding = np.mean(embeddings.numpy(), axis=0)
        
        # Reshape for model input: (1, 1024)
        embedding = embedding.reshape(1, -1).astype(np.float32)
        
        logger.info(f"✓ YAMNet embedding extracted: {embedding.shape}")
        return embedding
        
    except ValueError as e:
        logger.error(f"Audio validation error: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid audio file: {str(e)}")
    except Exception as e:
        logger.error(f"Error preprocessing audio: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=f"Error preprocessing audio: {str(e)}")


def predict_threat(embedding: np.ndarray) -> Dict[str, Any]:
    """
    Run model inference on YAMNet embedding
    
    Args:
        embedding: YAMNet embedding (1024-dimensional vector)
        
    Returns:
        Dictionary with prediction results
    """
    try:
        # Use Keras model for prediction (output is already softmax probabilities)
        probabilities = keras_classifier.predict(embedding, verbose=0)[0]
        
        # Get predicted class
        predicted_idx = np.argmax(probabilities)
        predicted_class = THREAT_CLASSES[predicted_idx]
        confidence = float(probabilities[predicted_idx])
        
        # Get all predictions
        all_predictions = {
            THREAT_CLASSES[i]: float(probabilities[i]) 
            for i in range(len(THREAT_CLASSES))
        }
        
        logger.info(f"Prediction: {predicted_class} ({confidence:.2%})")
        logger.info(f"All predictions: {all_predictions}")
        
        return {
            "predicted_class": predicted_class,
            "confidence": confidence,
            "all_predictions": all_predictions,
            "priority": PRIORITY_MAP[predicted_class]
        }
        
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")


@app.on_event("startup")
async def startup_event():
    """Load model on startup"""
    success = load_model()
    if not success:
        logger.error("Failed to load model on startup!")


@app.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint - Health check"""
    return HealthResponse(
        status="ok",
        message="EcoSight Wildlife Detection API",
        model_loaded=keras_classifier is not None,
        timestamp=datetime.datetime.now().isoformat()
    )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy" if keras_classifier is not None else "unhealthy",
        "model_loaded": keras_classifier is not None,
        "timestamp": datetime.datetime.now().isoformat()
    }


@app.post("/predict", response_model=DetectionResponse)
async def predict_audio(
    file: UploadFile = File(...),
    latitude: Optional[float] = -1.2921,
    longitude: Optional[float] = 36.8219
):
    """
    Predict threat from audio file
    
    Args:
        file: Audio file (WAV, MP3, etc.)
        latitude: GPS latitude (optional)
        longitude: GPS longitude (optional)
        
    Returns:
        Detection response with prediction results
    """
    # Check if model is loaded
    if keras_classifier is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate file type
    if not file.content_type.startswith('audio/'):
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type: {file.content_type}. Expected audio file."
        )
    
    try:
        # Read audio file
        logger.info(f"Processing file: {file.filename}")
        audio_bytes = await file.read()
        
        # Preprocess audio
        audio_data = preprocess_audio(audio_bytes)
        
        # Run prediction
        prediction = predict_threat(audio_data)
        
        # Create response
        response = DetectionResponse(
            id=str(int(datetime.datetime.now().timestamp() * 1000)),
            predicted_class=prediction["predicted_class"],
            confidence=prediction["confidence"],
            timestamp=datetime.datetime.now().isoformat(),
            latitude=latitude,
            longitude=longitude,
            status="critical" if prediction["priority"] == "CRITICAL" else "pending",
            priority=prediction["priority"],
            all_predictions=prediction["all_predictions"]
        )
        
        logger.info(f"Detection created: {response.id}")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/batch-predict")
async def batch_predict(files: list[UploadFile] = File(...)):
    """
    Predict threats from multiple audio files
    
    Args:
        files: List of audio files
        
    Returns:
        List of detection results
    """
    if keras_classifier is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    results = []
    
    for file in files:
        try:
            # Read and process each file
            audio_bytes = await file.read()
            audio_data = preprocess_audio(audio_bytes)
            prediction = predict_threat(audio_data)
            
            results.append({
                "filename": file.filename,
                "predicted_class": prediction["predicted_class"],
                "confidence": prediction["confidence"],
                "priority": prediction["priority"]
            })
            
        except Exception as e:
            logger.error(f"Error processing {file.filename}: {e}")
            results.append({
                "filename": file.filename,
                "error": str(e)
            })
    
    return {"results": results, "total": len(files)}


@app.get("/classes")
async def get_classes():
    """Get available threat classes"""
    return {
        "classes": THREAT_CLASSES,
        "priorities": PRIORITY_MAP
    }


@app.get("/model-info")
async def get_model_info():
    """Get model information"""
    if keras_classifier is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model_path": KERAS_MODEL_PATH,
        "model_type": "Keras Sequential",
        "input_shape": str(keras_classifier.input_shape),
        "output_shape": str(keras_classifier.output_shape),
        "num_classes": len(THREAT_CLASSES),
        "classes": THREAT_CLASSES,
        "sample_rate": SAMPLE_RATE,
        "max_duration": MAX_DURATION,
        "feature_extraction": "YAMNet embeddings (1024-dim)",
        "total_parameters": keras_classifier.count_params()
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
