# TogetherSO Wildlife Protection System - Project Strategy

## 📋 Executive Summary

You're building an AI-powered anti-poaching system that detects threatening sounds (gunshots, vehicles, dogs, human voices, guinea fowl alarm calls) in game parks and alerts rangers via SMS in real-time.

---

## 🎯 Current Status Assessment

### Your Audio Dataset:

| Class | Current Files | Status | Priority |
|-------|--------------|--------|----------|
| **guineafowl** | 13 | 🔴 CRITICAL | Needs 70-80x increase |
| **gun_shot** | 374 | 🟡 HIGH | Needs 2-3x increase |
| **dog_bark** | 1,000 | 🟢 OK | Sufficient |
| **engine_idling** | 1,000 | 🟢 OK | Sufficient |
| **human_voices** | TBD | ❓ Check | Depends on count |

---

## ✅ My Top Recommendations

### 1. **Immediate: Aggressive Augmentation for Imbalanced Classes**

**Guineafowl (CRITICAL - only 13 files!)**
- Apply 10+ augmentations per file → Target: 150-200 files minimum
- Techniques: pitch shift (±3 semitones), time stretch (0.8-1.2x), noise, time shift, volume
- Consider synthetic generation if needed

**Gun Shot (HIGH - 374 files)**
- Apply 5-7 augmentations per file → Target: 1,000+ files
- Critical for model reliability (this is your most important class!)

**Human Voices (if < 500 files)**
- Augment to at least 800-1,000 files
- This class helps distinguish between rangers and poachers

### 2. **Model Architecture: Start Simple, Scale Smart**

**Recommended Approach: Mel-Spectrogram + CNN**

```python
Why this approach?
✅ Fast inference on edge devices (Raspberry Pi)
✅ Works well with limited data (transfer learning)
✅ Proven track record in audio classification
✅ Easy to optimize with TensorFlow Lite
```

**Architecture:**
1. Convert audio → Mel-Spectrogram (128x128 pixels)
2. Use lightweight CNN (MobileNetV2 or EfficientNet-Lite)
3. Fine-tune on your specific classes
4. Deploy as TensorFlow Lite model

**Expected Performance:**
- Accuracy: 88-93%
- Inference time: 300-500ms on Raspberry Pi 4
- Model size: < 10MB (optimized)

### 3. **Handle Class Imbalance During Training**

Even after augmentation, use these techniques:

```python
# Option 1: Class weights (Recommended)
from sklearn.utils.class_weight import compute_class_weight

class_weights = compute_class_weight(
    'balanced',
    classes=np.unique(y_train),
    y=y_train
)

# Option 2: Focal Loss (for severe imbalance)
# Penalizes wrong predictions on rare classes more heavily

# Option 3: Oversampling rare classes
# Randomly duplicate guineafowl samples during training
```

### 4. **Smart Alert System Design**

**Alert Priority Logic:**

```
GUN SHOT detected (confidence > 85%):
  → IMMEDIATE SMS to all rangers
  → Log GPS location, timestamp
  → Trigger camera trap if available
  → Priority: CRITICAL

DOG BARK + ENGINE IDLING (within 30 seconds):
  → Alert rangers (possible poachers approaching)
  → Priority: HIGH

GUINEA FOWL alarm call (confidence > 80%):
  → Alert rangers (animals sensing danger)
  → Priority: MEDIUM
  
HUMAN VOICES (nighttime only):
  → Alert rangers (suspicious activity)
  → Priority: MEDIUM

HUMAN VOICES (daytime):
  → Log only (likely tourists/rangers)
  → Priority: LOW
```

**Reduce False Positives:**
- Set high confidence threshold for gun_shot (90%+)
- Combine multiple detections (e.g., dog + engine = higher confidence)
- Time-of-day filtering
- Geofencing (higher alerts in restricted areas)

### 5. **Deployment Strategy**

**Hardware Setup (Per Detection Unit):**
- Raspberry Pi 4 (4GB) - $55
- USB Omnidirectional Microphone - $25
- 4G Module (SIM7600 or similar) - $40
- Solar Panel + Battery - $50
- Waterproof case - $30
- **Total: ~$200 per unit**

**Software Stack:**
```
Raspberry Pi OS Lite (headless)
├── Python 3.9+
├── TensorFlow Lite Runtime
├── librosa (audio processing)
├── Twilio/Africa's Talking (SMS)
├── systemd (auto-start on boot)
└── SQLite (local logging)
```

**Detection Pipeline:**
```
1. Continuous audio recording (4-second sliding windows)
2. Extract Mel-spectrogram in real-time
3. Model inference (< 500ms)
4. If confidence > threshold:
   ├── Get GPS coordinates
   ├── Generate alert message
   ├── Send SMS via 4G
   └── Log to database
5. Repeat
```

---

## 📊 Success Metrics

**Technical:**
- [ ] Model accuracy > 90%
- [ ] Gun shot detection precision > 95% (minimize false alarms)
- [ ] Gun shot detection recall > 90% (catch all real threats)
- [ ] Inference time < 500ms
- [ ] Battery life > 7 days continuous operation

**Operational:**
- [ ] Alert delivery time < 30 seconds
- [ ] SMS delivery success rate > 98%
- [ ] False positive rate < 5%
- [ ] System uptime > 95%

---

## 🛣️ 8-Week Fast Track Plan

### **Weeks 1-2: Data Preparation** ← YOU ARE HERE
- [x] Extract audio files
- [ ] Complete augmentation (focus on guineafowl & gun_shot)
- [ ] Create balanced dataset
- [ ] Train/val/test split (70/15/15)

### **Weeks 3-4: Model Development**
- [ ] Extract Mel-spectrograms from all audio
- [ ] Build baseline CNN
- [ ] Train with class weights
- [ ] Achieve > 85% validation accuracy

### **Weeks 5-6: Optimization**
- [ ] Hyperparameter tuning
- [ ] Model compression (TensorFlow Lite)
- [ ] Test on Raspberry Pi
- [ ] Optimize inference speed

### **Weeks 7-8: Deployment**
- [ ] Build real-time detection script
- [ ] Integrate SMS alerts
- [ ] Field testing
- [ ] Create deployment documentation

---

## 🚨 Critical Considerations

### 1. **Real-World Audio Challenges**

**Distance Variations:**
- Sounds at 10m vs 100m vs 500m will be very different
- Solution: Include volume augmentation, train on multi-distance samples

**Background Noise:**
- Wind, rain, other animals, insects
- Solution: Add noise augmentation, train with environmental sounds

**Overlapping Sounds:**
- Multiple sounds happening simultaneously
- Solution: Multi-label classification (detect multiple classes at once)

### 2. **False Positives Management**

Gun shot false positives are EXPENSIVE (rangers respond unnecessarily):
- Use high confidence threshold (90-95%)
- Require multiple consecutive detections
- Time-of-day weighting
- Consider "confidence voting" from multiple nearby sensors

### 3. **Power Management**

Raspberry Pi power consumption:
- Active inference: ~5-7W
- With solar panel: Need ~15W panel + 20,000mAh battery
- Optimization: Sleep between detections, wake on loud sounds

### 4. **Network Reliability**

4G coverage in game parks may be spotty:
- Queue alerts locally when offline
- Batch send when connection restored
- Priority queue (gun_shot alerts first)
- Consider LoRaWAN as backup

---

## 💻 Next Immediate Steps

### Step 1: Complete Augmentation (Today)
```bash
# Run your notebook cells to augment guineafowl and gun_shot
# Target: guineafowl → 150+ files, gun_shot → 1,000+ files
```

### Step 2: Create Feature Extraction Notebook (Tomorrow)
```python
# notebooks/03_feature_extraction.ipynb
# Extract Mel-spectrograms for all augmented audio
# Save as numpy arrays for fast training
```

### Step 3: Build Baseline Model (Next 2-3 days)
```python
# notebooks/04_model_training.ipynb
# Simple CNN on Mel-spectrograms
# Target: 85%+ accuracy
```

### Step 4: Test on Raspberry Pi (Next week)
```python
# deployment/test_inference.py
# Measure inference speed and resource usage
```

---

## 📚 Helpful Resources

**Audio Deep Learning:**
- Environmental Sound Classification with CNNs
- Transfer Learning for Audio (AudioSet weights)
- Librosa tutorial: https://librosa.org/doc/main/tutorial.html

**Edge Deployment:**
- TensorFlow Lite for Raspberry Pi
- Real-time audio processing with Python
- Optimizing models for edge devices

**IoT & SMS:**
- Twilio API documentation
- Africa's Talking API (better for African regions)
- Raspberry Pi GPIO and sensors

---

## 🤝 Need Help With?

Let me know if you need assistance with:

1. ✅ **Data augmentation** (we're doing this now!)
2. ⏳ **Feature extraction code** (Mel-spectrograms, MFCCs)
3. ⏳ **Model architecture** (CNN design, transfer learning)
4. ⏳ **Training pipeline** (data loaders, training loops)
5. ⏳ **Real-time inference** (audio streaming, sliding windows)
6. ⏳ **SMS integration** (Twilio/Africa's Talking setup)
7. ⏳ **Deployment scripts** (systemd service, auto-start)

---

## 🎯 Final Thoughts

Your project is ambitious but absolutely feasible! Here's what makes it achievable:

✅ **Clear use case** with real impact on wildlife conservation  
✅ **Manageable scope** (5 classes, well-defined problem)  
✅ **Available hardware** (Raspberry Pi is perfect for this)  
✅ **Proven technology** (CNNs work great for audio classification)  

**Biggest challenges:**
1. Guineafowl class imbalance (only 13 samples!) - Address with aggressive augmentation
2. Real-world noise and distance variations - Address with diverse training data
3. Power and connectivity in remote areas - Address with solar + local queuing

**You've got this! Let's build something that saves wildlife! 🦏🐘🦒**

---

**Questions or need clarification on any part? Let me know!**
