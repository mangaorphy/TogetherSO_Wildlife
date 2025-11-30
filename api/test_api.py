"""
Test script for the EcoSight API
"""
import requests
import numpy as np
import soundfile as sf
import os

# API endpoint
API_URL = "http://localhost:8000"

def create_test_audio(filename="test_audio.wav", duration=3, sample_rate=16000):
    """Create a test audio file"""
    # Generate a simple sine wave
    t = np.linspace(0, duration, int(sample_rate * duration))
    frequency = 440  # A4 note
    audio = 0.5 * np.sin(2 * np.pi * frequency * t)
    
    # Save as WAV file
    sf.write(filename, audio, sample_rate)
    print(f"✅ Created test audio file: {filename}")
    return filename

def test_health():
    """Test the health endpoint"""
    try:
        response = requests.get(f"{API_URL}/health")
        if response.status_code == 200:
            print(f"✅ Health check passed: {response.json()}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_get_classes():
    """Test the get classes endpoint"""
    try:
        response = requests.get(f"{API_URL}/classes")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Classes retrieved:")
            print(f"   Classes: {data['classes']}")
            print(f"   Priorities: {data['priorities']}")
            return True
        else:
            print(f"❌ Get classes failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Get classes error: {e}")
        return False

def test_model_info():
    """Test the model info endpoint"""
    try:
        response = requests.get(f"{API_URL}/model-info")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Model info retrieved:")
            print(f"   Input shape: {data['input_shape']}")
            print(f"   Output shape: {data['output_shape']}")
            print(f"   Number of classes: {data['num_classes']}")
            return True
        else:
            print(f"❌ Model info failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Model info error: {e}")
        return False

def test_predict(audio_file):
    """Test the prediction endpoint"""
    try:
        with open(audio_file, 'rb') as f:
            files = {'file': (audio_file, f, 'audio/wav')}
            data = {
                'latitude': -1.2921,
                'longitude': 36.8219
            }
            
            response = requests.post(f"{API_URL}/predict", files=files, data=data)
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Prediction successful:")
                print(f"   Predicted class: {result['predicted_class']}")
                print(f"   Confidence: {result['confidence']:.2%}")
                print(f"   Priority: {result['priority']}")
                print(f"   All predictions: {result['all_predictions']}")
                return True
            else:
                print(f"❌ Prediction failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 50)
    print("🧪 Testing EcoSight API")
    print("=" * 50)
    
    # Test 1: Health check
    print("\n1️⃣ Testing Health Endpoint...")
    if not test_health():
        print("⚠️  Server may not be running. Start it with: python3 main.py")
        return
    
    # Test 2: Get classes
    print("\n2️⃣ Testing Get Classes Endpoint...")
    test_get_classes()
    
    # Test 3: Model info
    print("\n3️⃣ Testing Model Info Endpoint...")
    test_model_info()
    
    # Test 4: Create test audio and predict
    print("\n4️⃣ Testing Prediction Endpoint...")
    audio_file = create_test_audio()
    test_predict(audio_file)
    
    # Cleanup
    if os.path.exists(audio_file):
        os.remove(audio_file)
        print(f"\n🧹 Cleaned up test file: {audio_file}")
    
    print("\n" + "=" * 50)
    print("✅ All tests completed!")
    print("=" * 50)

if __name__ == "__main__":
    main()
