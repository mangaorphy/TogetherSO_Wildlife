# Audio Data Preprocessing Guide

## TogetherSO Wildlife Protection System

This guide explains how audio data preprocessing and augmentation works in the TogetherSO anti-poaching system.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Audio File Formats](#audio-file-formats)
3. [Loading Audio Data](#loading-audio-data)
4. [Audio Augmentation Techniques](#audio-augmentation-techniques)
5. [Preprocessing Pipeline](#preprocessing-pipeline)
6. [Feature Extraction (Next Phase)](#feature-extraction-next-phase)
7. [Best Practices](#best-practices)

---

## Overview

### What is Audio Preprocessing?

Audio preprocessing is the process of preparing raw audio data for machine learning models. It involves:
- **Loading** audio files in various formats
- **Augmenting** data to increase dataset size and diversity
- **Extracting features** that represent audio characteristics
- **Normalizing** data for consistent model training

### Why Do We Need It?

1. **Increase Dataset Size**: Transform 13 guineafowl samples → 143 samples
2. **Improve Model Robustness**: Handle variations in real-world conditions
3. **Reduce Overfitting**: More diverse training data
4. **Handle Imbalanced Classes**: Balance small datasets with larger ones

---

## Audio File Formats

### Supported Formats

Our preprocessing pipeline supports:

#### 1. **WAV (Waveform Audio File Format)**
- **Encoding**: Uncompressed PCM
- **Quality**: Lossless
- **File Size**: Large (~10MB per minute)
- **Best For**: Training data, analysis
- **Usage**: Primary format for model training

```python
# Example WAV file properties
Sample Rate: 22,050 Hz or 44,100 Hz
Bit Depth: 16-bit or 24-bit
Channels: Mono (1) or Stereo (2)
```

#### 2. **MP3 (MPEG Audio Layer III)**
- **Encoding**: Lossy compression
- **Quality**: Good (320 kbps) to Excellent
- **File Size**: Small (~1MB per minute)
- **Best For**: Storage, distribution
- **Usage**: Input format (converted to WAV internally)

```python
# Example MP3 file properties
Bitrate: 128-320 kbps
Sample Rate: 44,100 Hz (typical)
Channels: Mono or Stereo
```

### Format Conversion

Our pipeline automatically handles format conversion:

```python
import librosa

# librosa loads both WAV and MP3
audio, sr = librosa.load("audio_file.wav", sr=None)   # WAV
audio, sr = librosa.load("audio_file.mp3", sr=None)   # MP3

# Both produce the same output:
# - audio: numpy array of samples
# - sr: sample rate (Hz)
```

**Key Point**: All augmented outputs are saved as **WAV format** for consistency and quality.

---

## Loading Audio Data

### Step 1: File Discovery

Scan directories for audio files:

```python
from pathlib import Path

# Find both WAV and MP3 files
audio_dir = Path("extracted_audio/gun_shot")
wav_files = list(audio_dir.glob("*.wav"))
mp3_files = list(audio_dir.glob("*.mp3"))
all_files = wav_files + mp3_files
```

### Step 2: Loading with Librosa

```python
import librosa

# Load audio file
audio, sample_rate = librosa.load(
    "audio_file.wav",
    sr=22050,        # Target sample rate (None = keep original)
    mono=True,       # Convert to mono
    duration=None    # Load entire file (or specify seconds)
)
```

**Output:**
- `audio`: NumPy array of audio samples (float32, range: -1.0 to 1.0)
- `sample_rate`: Samples per second (Hz)

### Step 3: Audio Properties

```python
# Get audio information
duration = len(audio) / sample_rate  # Duration in seconds
num_samples = len(audio)             # Total samples
print(f"Duration: {duration:.2f}s")
print(f"Samples: {num_samples}")
print(f"Sample Rate: {sample_rate} Hz")
```

### Example: Loading Gun Shot Audio

```python
# Load gun shot audio
audio, sr = librosa.load("extracted_audio/gun_shot/7061-6-0-0.wav", sr=22050)

# Output:
# Duration: 4.00 seconds
# Samples: 88,200 (22,050 samples/second × 4 seconds)
# Sample Rate: 22,050 Hz
# Audio shape: (88200,)
# Audio range: [-0.8, 0.9]
```

---

## Audio Augmentation Techniques

Augmentation creates variations of original audio to increase dataset diversity.

### 1. Time Stretching (Speed Change)

**Purpose**: Simulate sounds at different speeds without changing pitch.

**How it works**:
- Rate > 1.0: Audio plays faster (shorter duration)
- Rate < 1.0: Audio plays slower (longer duration)

```python
import librosa

def time_stretch(audio, rate=1.0):
    """
    Time stretch audio by a given rate
    rate=1.1 → 10% faster (90.9% duration)
    rate=0.9 → 10% slower (111% duration)
    """
    return librosa.effects.time_stretch(audio, rate=rate)

# Example
audio_fast = time_stretch(audio, rate=1.1)  # 10% faster
audio_slow = time_stretch(audio, rate=0.9)  # 10% slower
```

**Use Case**: Handle variations in gunshot speed or animal call tempo.

**Before**: 4.0 seconds gun shot  
**After (rate=1.1)**: 3.64 seconds (same pitch, faster)  
**After (rate=0.9)**: 4.44 seconds (same pitch, slower)

---

### 2. Pitch Shifting (Tone Change)

**Purpose**: Change the pitch/frequency without changing duration.

**How it works**:
- Positive steps: Higher pitch (shift up)
- Negative steps: Lower pitch (shift down)
- 1 step = 1 semitone (half step in music)

```python
def pitch_shift(audio, sr, n_steps=0):
    """
    Shift pitch by n_steps semitones
    n_steps=2 → 2 semitones higher
    n_steps=-2 → 2 semitones lower
    """
    return librosa.effects.pitch_shift(audio, sr=sr, n_steps=n_steps)

# Example
audio_high = pitch_shift(audio, sr, n_steps=2)   # Higher pitch
audio_low = pitch_shift(audio, sr, n_steps=-2)   # Lower pitch
```

**Use Case**: Handle different microphone characteristics or animal vocal variations.

**Before**: Original frequency distribution  
**After (n_steps=2)**: All frequencies shifted up by 2 semitones  
**After (n_steps=-2)**: All frequencies shifted down by 2 semitones

---

### 3. Noise Addition (Background Noise)

**Purpose**: Add random noise to simulate real-world environmental conditions.

**How it works**:
- Generate Gaussian (normal) random noise
- Scale by noise factor
- Add to original audio

```python
import numpy as np

def add_noise(audio, noise_factor=0.005):
    """
    Add Gaussian noise to audio
    noise_factor: 0.002 (light) to 0.01 (heavy)
    """
    noise = np.random.randn(len(audio))
    augmented = audio + noise_factor * noise
    return augmented

# Example
audio_noisy_light = add_noise(audio, noise_factor=0.002)   # Light noise
audio_noisy_medium = add_noise(audio, noise_factor=0.005)  # Medium noise
```

**Use Case**: Train model to handle wind, rain, insects, distant sounds.

**Noise Factor Guide**:
- `0.001-0.003`: Light background noise (clear day)
- `0.003-0.007`: Medium noise (windy conditions)
- `0.007-0.015`: Heavy noise (rain, storm)

---

### 4. Time Shifting (Temporal Offset)

**Purpose**: Shift audio in time to simulate different recording start points.

**How it works**:
- Roll the audio array left or right
- Wraps around (circular shift)

```python
def time_shift(audio, shift_max=0.2):
    """
    Shift audio in time domain
    shift_max: maximum shift as fraction of length (0.2 = ±20%)
    """
    shift = int(np.random.uniform(-shift_max, shift_max) * len(audio))
    return np.roll(audio, shift)

# Example
audio_shifted = time_shift(audio, shift_max=0.15)  # Shift ±15%
```

**Use Case**: Handle variations in sound detection timing, partial clips.

**Before**: Sound starts at t=0s  
**After (shift=+20%)**: Sound starts at t=0.8s (for 4s clip)  
**After (shift=-20%)**: Sound starts at t=0s, wraps to end

---

### 5. Volume Adjustment (Amplitude Scaling)

**Purpose**: Change audio loudness to handle different distances/recording levels.

**How it works**:
- Multiply all audio samples by a factor
- Factor > 1.0: Louder
- Factor < 1.0: Quieter

```python
def change_volume(audio, factor=1.0):
    """
    Change audio volume
    factor=1.2 → 20% louder
    factor=0.8 → 20% quieter
    """
    return audio * factor

# Example
audio_loud = change_volume(audio, factor=1.2)   # 20% louder
audio_quiet = change_volume(audio, factor=0.8)  # 20% quieter
```

**Use Case**: Handle sounds at different distances (near: loud, far: quiet).

**Distance Simulation**:
- `factor=1.2-1.5`: Close range (< 50m)
- `factor=0.8-1.0`: Medium range (50-200m)
- `factor=0.5-0.7`: Far range (200-500m)

---

### 6. Combined Augmentations

**Purpose**: Apply multiple techniques for complex variations.

```python
def combined_augmentation(audio, sr):
    """
    Apply multiple augmentations together
    """
    # Time stretch + noise
    audio = time_stretch(audio, rate=1.05)
    audio = add_noise(audio, noise_factor=0.003)
    
    return audio

# More combinations
def realistic_variation(audio, sr):
    """
    Simulate realistic field conditions
    """
    # Slight pitch shift (microphone variation)
    audio = pitch_shift(audio, sr, n_steps=1)
    
    # Reduce volume (distant sound)
    audio = change_volume(audio, factor=0.9)
    
    # Add environmental noise
    audio = add_noise(audio, noise_factor=0.004)
    
    return audio
```

**Use Case**: Create realistic variations matching actual field conditions.

---

## Preprocessing Pipeline

### Complete Augmentation Workflow

#### Step 1: Load Original Audio

```python
import librosa
import soundfile as sf
from pathlib import Path

# Load audio
audio_path = Path("extracted_audio/gun_shot/7061-6-0-0.wav")
audio, sr = librosa.load(audio_path, sr=22050)
```

#### Step 2: Define Augmentation Strategy

```python
# Augmentation configurations
augmentations = [
    ('time_stretch_fast', lambda a: time_stretch(a, rate=1.1)),
    ('time_stretch_slow', lambda a: time_stretch(a, rate=0.9)),
    ('pitch_up', lambda a: pitch_shift(a, sr, n_steps=2)),
    ('pitch_down', lambda a: pitch_shift(a, sr, n_steps=-2)),
    ('noise_light', lambda a: add_noise(a, noise_factor=0.002)),
    ('noise_medium', lambda a: add_noise(a, noise_factor=0.005)),
    ('time_shift', lambda a: time_shift(a, shift_max=0.15)),
    ('volume_up', lambda a: change_volume(a, factor=1.2)),
    ('volume_down', lambda a: change_volume(a, factor=0.8)),
    ('combined_1', lambda a: add_noise(time_stretch(a, rate=1.05), noise_factor=0.003)),
    ('combined_2', lambda a: change_volume(pitch_shift(a, sr, n_steps=1), factor=0.9))
]
```

#### Step 3: Apply Augmentations

```python
import numpy as np

# Save original
output_dir = Path("augmented_audio/gun_shot")
output_dir.mkdir(parents=True, exist_ok=True)

base_name = audio_path.stem  # e.g., "7061-6-0-0"

# Save original
sf.write(output_dir / f"{base_name}_original.wav", audio, sr)

# Apply 5 random augmentations
num_augmentations = 5
selected = np.random.choice(len(augmentations), size=num_augmentations, replace=False)

for idx in selected:
    aug_name, aug_func = augmentations[idx]
    
    # Apply augmentation
    augmented_audio = aug_func(audio)
    
    # Save augmented version
    output_path = output_dir / f"{base_name}_{aug_name}.wav"
    sf.write(output_path, augmented_audio, sr)
    
    print(f"✓ Saved: {output_path.name}")
```

#### Step 4: Verify Output

```python
# Check results
augmented_files = list(output_dir.glob("*.wav"))
print(f"\nGenerated {len(augmented_files)} files from 1 original:")
for f in sorted(augmented_files):
    print(f"  - {f.name}")

# Output:
# Generated 6 files from 1 original:
#   - 7061-6-0-0_original.wav
#   - 7061-6-0-0_time_stretch_fast.wav
#   - 7061-6-0-0_pitch_up.wav
#   - 7061-6-0-0_noise_light.wav
#   - 7061-6-0-0_time_shift.wav
#   - 7061-6-0-0_volume_down.wav
```

---

### Smart Augmentation Strategy

Different classes need different augmentation levels:

```python
def get_augmentation_count(current_files):
    """
    Determine augmentation intensity based on dataset size
    """
    if current_files < 50:
        return 10  # 🔴 CRITICAL - create 10 variations per file
    elif current_files < 200:
        return 7   # 🟡 HIGH - create 7 variations per file
    elif current_files < 500:
        return 5   # 🟠 MEDIUM - create 5 variations per file
    else:
        return 3   # 🟢 LOW - create 3 variations per file

# Example
guineafowl_count = 13
gun_shot_count = 374
dog_bark_count = 1000

print(f"guineafowl: {guineafowl_count} files → {get_augmentation_count(guineafowl_count)} augs → {guineafowl_count * 11} total")
print(f"gun_shot: {gun_shot_count} files → {get_augmentation_count(gun_shot_count)} augs → {gun_shot_count * 6} total")
print(f"dog_bark: {dog_bark_count} files → {get_augmentation_count(dog_bark_count)} augs → {dog_bark_count * 4} total")

# Output:
# guineafowl: 13 files → 10 augs → 143 total (11x increase)
# gun_shot: 374 files → 5 augs → 2,244 total (6x increase)
# dog_bark: 1000 files → 3 augs → 4,000 total (4x increase)
```

---

## Feature Extraction (Next Phase)

After augmentation, we extract features for model training:

### 1. Mel-Spectrograms

**What**: Visual representation of audio frequencies over time

```python
import librosa.display
import matplotlib.pyplot as plt

# Extract mel-spectrogram
mel_spec = librosa.feature.melspectrogram(
    y=audio,
    sr=sr,
    n_mels=128,      # Number of mel bands
    fmax=8000        # Maximum frequency
)

# Convert to decibels
mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)

# Visualize
plt.figure(figsize=(10, 4))
librosa.display.specshow(mel_spec_db, sr=sr, x_axis='time', y_axis='mel')
plt.colorbar(format='%+2.0f dB')
plt.title('Mel-Spectrogram')
plt.show()
```

**Output Shape**: (128, time_steps) - Image-like representation  
**Use**: Input to CNN models

---

### 2. MFCCs (Mel-Frequency Cepstral Coefficients)

**What**: Compact representation of audio spectral envelope

```python
# Extract MFCCs
mfccs = librosa.feature.mfcc(
    y=audio,
    sr=sr,
    n_mfcc=40        # Number of coefficients
)

# Output shape: (40, time_steps)
print(f"MFCC shape: {mfccs.shape}")
```

**Use**: Traditional ML models, smaller input size

---

### 3. Additional Features

```python
# Zero Crossing Rate (noisiness)
zcr = librosa.feature.zero_crossing_rate(audio)

# Spectral Centroid (brightness)
spectral_centroids = librosa.feature.spectral_centroid(y=audio, sr=sr)

# Chroma Features (pitch class)
chroma = librosa.feature.chroma_stft(y=audio, sr=sr)

# Combine features
features = np.vstack([
    np.mean(mfccs, axis=1),
    np.mean(zcr),
    np.mean(spectral_centroids),
    np.mean(chroma, axis=1)
])
```

---

## Best Practices

### 1. Audio Quality

✅ **Do**:
- Use sample rate ≥ 22,050 Hz for good quality
- Keep bit depth at 16-bit minimum
- Convert to mono if stereo not needed
- Normalize audio to [-1.0, 1.0] range

❌ **Don't**:
- Over-compress audio (< 128 kbps MP3)
- Mix drastically different sample rates
- Clip audio (values > 1.0 or < -1.0)

### 2. Augmentation Levels

✅ **Do**:
- Use subtle augmentations (avoid extreme values)
- Apply more augmentations to smaller datasets
- Test augmented samples to ensure quality
- Keep original files as backup

❌ **Don't**:
- Over-augment (distorted/unrealistic audio)
- Use same augmentation parameters for all classes
- Forget to save originals

**Recommended Parameters**:
```python
# Subtle (recommended)
time_stretch: rate=0.9-1.1 (±10%)
pitch_shift: n_steps=±2 semitones
noise: factor=0.002-0.007
volume: factor=0.7-1.3

# Extreme (avoid)
time_stretch: rate=0.5-2.0 (±100%)
pitch_shift: n_steps=±5 semitones
noise: factor=0.02+
volume: factor=0.3-3.0
```

### 3. File Organization

```
project/
├── extracted_audio/          # Original files (backup)
│   ├── gun_shot/
│   │   ├── 7061-6-0-0.wav
│   │   └── ...
│   ├── guineafowl/
│   │   ├── guinea_fowl_01.mp3
│   │   └── ...
│   └── ...
│
├── augmented_audio/          # Augmented files (training)
│   ├── gun_shot/
│   │   ├── 7061-6-0-0_original.wav
│   │   ├── 7061-6-0-0_pitch_up.wav
│   │   ├── 7061-6-0-0_noise_light.wav
│   │   └── ...
│   └── ...
│
└── features/                 # Extracted features
    ├── mel_spectrograms/
    │   ├── gun_shot/
    │   └── ...
    └── mfccs/
        ├── gun_shot/
        └── ...
```

### 4. Memory Management

For large datasets:

```python
# Process in batches
def process_audio_batch(file_list, batch_size=50):
    """Process audio files in batches to manage memory"""
    for i in range(0, len(file_list), batch_size):
        batch = file_list[i:i+batch_size]
        
        for audio_file in batch:
            # Load, augment, save
            audio, sr = librosa.load(audio_file, sr=22050)
            augmented = augment_audio(audio, sr)
            save_audio(augmented, output_path)
        
        # Clear memory after each batch
        del audio, augmented
        import gc
        gc.collect()
```

### 5. Quality Control

Always verify augmented audio:

```python
def verify_augmented_audio(audio, original_audio):
    """Check if augmentation produced valid audio"""
    
    # Check for NaN or Inf
    if np.isnan(audio).any() or np.isinf(audio).any():
        return False, "Contains NaN or Inf values"
    
    # Check amplitude range
    if audio.max() > 10.0 or audio.min() < -10.0:
        return False, "Amplitude out of reasonable range"
    
    # Check duration (shouldn't change dramatically except time stretch)
    if len(audio) < len(original_audio) * 0.5 or len(audio) > len(original_audio) * 2.0:
        return False, "Duration changed too much"
    
    return True, "Valid"

# Use during augmentation
augmented = time_stretch(audio, rate=1.1)
is_valid, message = verify_augmented_audio(augmented, audio)
if is_valid:
    sf.write(output_path, augmented, sr)
else:
    print(f"⚠️ Invalid augmentation: {message}")
```

---

## Summary

### Preprocessing Workflow

1. **Load Audio** → Support .wav and .mp3
2. **Augment Data** → 5-10 variations per file
3. **Save as WAV** → Consistent format
4. **Extract Features** → Mel-spectrograms, MFCCs
5. **Train Model** → Use augmented data

### Key Metrics

| Dataset | Original | Augmented | Increase |
|---------|----------|-----------|----------|
| guineafowl | 13 | 143 | 11x |
| gun_shot | 374 | 2,244 | 6x |
| dog_bark | 1,000 | 4,000 | 4x |
| engine_idling | 1,000 | 4,000 | 4x |

### Tools Used

- **librosa**: Audio loading, augmentation, feature extraction
- **soundfile**: Saving audio files
- **numpy**: Array operations
- **matplotlib**: Visualization

---

## Next Steps

1. ✅ **Augmentation** (Complete)
2. ⏳ **Feature Extraction** (Next notebook)
3. ⏳ **Model Training** (CNN on spectrograms)
4. ⏳ **Deployment** (Raspberry Pi)

---

**Questions? Need clarification on any preprocessing step? Just ask!** 🎵🔊
