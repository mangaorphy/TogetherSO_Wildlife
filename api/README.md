# 🚀 FastAPI Backend Setup Guide - EcoSight

## 📋 Overview

This FastAPI backend serves the YAMNet model for real-time wildlife threat detection. It receives audio files from the Flutter app, processes them through the model, and returns predictions.

---

## 📁 Project Structure

```
TogetherSO_Wildlife/
├── api/
│   ├── main.py              # FastAPI application
│   ├── requirements.txt     # Python dependencies
│   └── .env (optional)      # Environment variables
├── togetherso_yamnet_model.tflite  # TFLite model
└── togetherso_app/          # Flutter app
    └── lib/services/
        └── api_service.dart  # API client for Flutter
```

---

## 🔧 Setup Instructions

### Step 1: Install Python Dependencies

```bash
cd /Users/cococe/Desktop/TogetherSO_Wildlife/api

# Create virtual environment (recommended)
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Copy Model File

```bash
# Make sure the model is in the root directory
cd /Users/cococe/Desktop/TogetherSO_Wildlife

# Verify model exists
ls -lh togetherso_yamnet_model.tflite

# If model is elsewhere, copy it
# cp path/to/model/togetherso_yamnet_model.tflite .
```

### Step 3: Start the API Server

```bash
cd /Users/cococe/Desktop/TogetherSO_Wildlife/api

# Make sure virtual environment is activated
python main.py

# Alternative: Use uvicorn directly
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Loading model from togetherso_yamnet_model.tflite...
INFO:     Model loaded successfully!
INFO:     Input shape: [1, 48000]
INFO:     Output shape: [1, 4]
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

---

## 🌐 API Endpoints

### 1. **Health Check**
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "timestamp": "2025-11-09T16:30:00"
}
```

### 2. **Predict Audio Threat**
```http
POST /predict
```

**Parameters:**
- `file` (required): Audio file (WAV, MP3, etc.)
- `latitude` (optional): GPS latitude (default: -1.2921)
- `longitude` (optional): GPS longitude (default: 36.8219)

**Response:**
```json
{
  "id": "1699521234567",
  "predicted_class": "gun_shot",
  "confidence": 0.94,
  "timestamp": "2025-11-09T16:25:06",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "status": "critical",
  "priority": "CRITICAL",
  "all_predictions": {
    "gun_shot": 0.94,
    "human_voices": 0.03,
    "engine_idling": 0.02,
    "dog_bark": 0.01
  }
}
```

### 3. **Batch Predict**
```http
POST /batch-predict
```

**Parameters:**
- `files` (required): Multiple audio files

**Response:**
```json
{
  "results": [
    {
      "filename": "audio1.wav",
      "predicted_class": "gun_shot",
      "confidence": 0.94,
      "priority": "CRITICAL"
    },
    {
      "filename": "audio2.wav",
      "predicted_class": "human_voices",
      "confidence": 0.87,
      "priority": "HIGH"
    }
  ],
  "total": 2
}
```

### 4. **Get Classes**
```http
GET /classes
```

**Response:**
```json
{
  "classes": {
    "0": "gun_shot",
    "1": "human_voices",
    "2": "engine_idling",
    "3": "dog_bark"
  },
  "priorities": {
    "gun_shot": "CRITICAL",
    "human_voices": "HIGH",
    "engine_idling": "MEDIUM",
    "dog_bark": "LOW"
  }
}
```

### 5. **Get Model Info**
```http
GET /model-info
```

**Response:**
```json
{
  "model_path": "togetherso_yamnet_model.tflite",
  "input_shape": [1, 48000],
  "output_shape": [1, 4],
  "input_dtype": "float32",
  "output_dtype": "float32",
  "num_classes": 4,
  "classes": {...},
  "sample_rate": 16000,
  "audio_duration": 3
}
```

---

## 🧪 Testing the API

### Using cURL

#### 1. Health Check
```bash
curl http://localhost:8000/health
```

#### 2. Predict Audio
```bash
curl -X POST "http://localhost:8000/predict" \
  -F "file=@path/to/audio.wav" \
  -F "latitude=-1.2921" \
  -F "longitude=36.8219"
```

#### 3. Get Classes
```bash
curl http://localhost:8000/classes
```

### Using Python Requests

```python
import requests

# Health check
response = requests.get('http://localhost:8000/health')
print(response.json())

# Predict audio
files = {'file': open('audio.wav', 'rb')}
data = {'latitude': -1.2921, 'longitude': 36.8219}
response = requests.post('http://localhost:8000/predict', files=files, data=data)
print(response.json())
```

### Using Postman

1. Open Postman
2. Create new POST request to `http://localhost:8000/predict`
3. Go to "Body" tab → Select "form-data"
4. Add key "file" with type "File" and select audio file
5. Add key "latitude" with value "-1.2921"
6. Add key "longitude" with value "36.8219"
7. Click "Send"

---

## 📱 Connecting Flutter App

### Update API URL

Edit `lib/services/api_service.dart`:

```dart
class ApiService {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:8000';
  
  // For Real Device (use your computer's IP)
  // static const String baseUrl = 'http://192.168.1.100:8000';
  
  // ...
}
```

### Find Your Computer's IP Address

**On macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows:**
```bash
ipconfig
```

Look for your local IP (usually starts with 192.168.x.x)

### Usage in Flutter

```dart
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

// Initialize API service
final apiService = ApiService();

// Test connection
bool isConnected = await apiService.testConnection();

// Pick audio file
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.audio,
);

if (result != null) {
  File audioFile = File(result.files.single.path!);
  
  // Predict threat
  try {
    ThreatDetection detection = await apiService.predictAudio(
      audioFile: audioFile,
      latitude: -1.2921,
      longitude: 36.8219,
    );
    
    print('Detected: ${detection.displayName}');
    print('Confidence: ${(detection.confidence * 100).toStringAsFixed(0)}%');
    print('Priority: ${detection.priority}');
    
    // Save to Firestore
    await provider.addDetection(detection);
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 🔐 Security Considerations

### 1. **CORS Configuration**

Currently allows all origins (`*`). For production, specify your Flutter app's URL:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",
        "https://yourdomain.com"
    ],
    # ...
)
```

### 2. **API Authentication**

Add API key authentication:

```python
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

API_KEY = "your-secret-api-key"
api_key_header = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != API_KEY:
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return api_key

# Use in endpoints
@app.post("/predict")
async def predict_audio(
    file: UploadFile = File(...),
    api_key: str = Security(verify_api_key)
):
    # ...
```

### 3. **Rate Limiting**

Install slowapi:
```bash
pip install slowapi
```

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/predict")
@limiter.limit("10/minute")
async def predict_audio(request: Request, file: UploadFile):
    # ...
```

---

## 🐛 Troubleshooting

### Issue: "Model not loaded"
**Solution:** 
- Check model file path is correct
- Ensure model file exists: `ls -lh togetherso_yamnet_model.tflite`
- Check file permissions

### Issue: "Connection refused" from Flutter app
**Solution:**
- Verify API is running: `curl http://localhost:8000/health`
- Check firewall settings
- Use correct URL for your platform:
  - Android Emulator: `http://10.0.2.2:8000`
  - iOS Simulator: `http://localhost:8000`
  - Real Device: `http://YOUR_IP:8000`

### Issue: "Audio preprocessing failed"
**Solution:**
- Ensure audio file is valid (WAV, MP3, etc.)
- Check audio duration (3 seconds recommended)
- Verify sample rate (16kHz expected)

### Issue: "Import error: No module named..."
**Solution:**
```bash
pip install -r requirements.txt --upgrade
```

---

## 📊 Performance Optimization

### 1. **Enable GPU Acceleration**

Install TensorFlow with GPU support:
```bash
pip install tensorflow-gpu
```

### 2. **Batch Processing**

Process multiple files at once using `/batch-predict` endpoint

### 3. **Caching**

Add Redis caching for repeated predictions:
```bash
pip install redis
```

### 4. **Async Processing**

Use background tasks for long-running predictions:
```python
from fastapi import BackgroundTasks

@app.post("/predict-async")
async def predict_async(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...)
):
    background_tasks.add_task(process_audio, file)
    return {"status": "processing"}
```

---

## 🚀 Deployment

### Deploy to Production Server

#### 1. **Using Docker**

Create `Dockerfile`:
```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:
```bash
docker build -t ecosight-api .
docker run -p 8000:8000 ecosight-api
```

#### 2. **Using systemd (Linux)**

Create `/etc/systemd/system/ecosight-api.service`:
```ini
[Unit]
Description=EcoSight API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/api
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable ecosight-api
sudo systemctl start ecosight-api
```

#### 3. **Using Heroku**

Create `Procfile`:
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

Deploy:
```bash
heroku create ecosight-api
git push heroku main
```

---

## 📈 Monitoring

### Add Logging

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('api.log'),
        logging.StreamHandler()
    ]
)
```

### Add Prometheus Metrics

```bash
pip install prometheus-fastapi-instrumentator
```

```python
from prometheus_fastapi_instrumentator import Instrumentator

Instrumentator().instrument(app).expose(app)
```

---

## ✅ Checklist

- [ ] Install Python dependencies
- [ ] Copy model file to root directory
- [ ] Start API server
- [ ] Test health endpoint
- [ ] Test predict endpoint with sample audio
- [ ] Update Flutter app API URL
- [ ] Test connection from Flutter app
- [ ] Configure CORS for production
- [ ] Add authentication (optional)
- [ ] Set up monitoring (optional)
- [ ] Deploy to production server (optional)

---

## 📞 Support

For issues or questions:
- Check logs: `tail -f api.log`
- Test API: `curl http://localhost:8000/health`
- Verify model: `python -c "import tensorflow as tf; print(tf.__version__)"`

---

**Status:** Ready to Deploy ✅  
**Next Step:** Start the API server and test predictions!
