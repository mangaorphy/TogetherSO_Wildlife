# Notebook Guide: acoustic_togetherso.ipynb

## 📖 How to Use This Notebook

This notebook is now **organized in a clear, step-by-step flow**. Here's what each section does:

---

## 🗂️ Notebook Structure (9 Steps)

### **Step 1: Import Libraries**
- Loads all required Python libraries (librosa, numpy, pandas, etc.)
- **Action:** Just run this cell first

### **Step 2: Setup Paths**
- Defines where your audio files are located
- Sets configuration (sample rate, target dataset size)
- **Action:** Run to configure paths

### **Step 3: Explore Dataset**
- Scans ALL audio classes in your `extracted_audio/` folder
- Shows which classes are CRITICAL (< 50 files), HIGH (< 500 files), or OK (> 500 files)
- Creates visual charts showing dataset distribution
- **Action:** Run to see your current data status

### **Step 4: Visualize Sample Audio**
- Loads sample audio from gun_shot and guineafowl
- Shows waveform and spectrogram visualizations
- **Action:** Run to understand what your audio looks like

### **Step 5: Define Augmentation Functions**
- Defines 5 augmentation techniques:
  1. Time stretching (speed up/slow down)
  2. Pitch shifting (change tone)
  3. Noise addition (add background noise)
  4. Time shifting (temporal offset)
  5. Volume adjustment (louder/quieter)
- **Action:** Run to load augmentation functions

### **Step 5a: Visualize Augmentation Effects**
- Shows how each augmentation modifies audio
- Displays side-by-side comparison of original vs augmented
- **Action:** Run to see augmentation examples

### **Step 6: Batch Augmentation Pipeline**
- Creates function to apply multiple augmentations to each file
- Randomly selects which augmentations to apply
- Saves augmented files automatically
- **Action:** Run to prepare the augmentation pipeline

### **Step 7: Run Smart Augmentation** ⭐ MAIN ACTION
- **This is where the magic happens!**
- Automatically determines how many augmentations each class needs:
  - < 50 files → 10 augmentations per file (CRITICAL)
  - < 200 files → 7 augmentations per file (HIGH)
  - < 500 files → 5 augmentations per file (MEDIUM)
- Processes gun_shot and guineafowl
- Shows progress bars
- **Action:** Run to augment your data (this takes a few minutes)

### **Step 8: Visualize Results**
- Creates before/after comparison charts
- Shows increase in dataset size
- Pie charts showing composition
- **Action:** Run to see augmentation success

### **Step 9: Sample Augmented Files (Optional)**
- Randomly selects augmented files to review
- Shows waveforms of augmented audio
- Optional: Play audio in notebook
- **Action:** Run to verify quality (optional)

---

## 🎯 Quick Start: Run All Cells

**To augment your data in one go:**
1. Open the notebook
2. Click "Run All" in VS Code
3. Wait 5-10 minutes (depending on dataset size)
4. Check the `augmented_audio/` folder for results

**Or run step-by-step:**
1. Run cells 1-6 (setup and preparation)
2. Run cell 7 (main augmentation) - **MOST IMPORTANT**
3. Run cell 8-9 (verify results)

---

## 📊 Expected Results

After running the notebook:

**Guineafowl:**
- Original: 13 files
- Augmented: ~143 files (11x increase)
- Status: ✅ Sufficient for training

**Gun Shot:**
- Original: 374 files
- Augmented: ~2,244 files (6x increase)
- Status: ✅ Sufficient for training

---

## 🔧 Customization Options

### Want to augment different classes?
In **Step 7**, change this line:
```python
CLASSES_TO_AUGMENT = ["gun_shot", "guineafowl"]
```
To:
```python
CLASSES_TO_AUGMENT = ["gun_shot", "guineafowl", "human_voices"]
```

### Want more/fewer augmentations?
In **Step 7**, adjust these values:
```python
if current_count < 50:
    augs_per_file = 10  # Change this number
```

### Want different target size?
In **Step 2**, change:
```python
TARGET_SIZE = 1000  # Change to 500, 1500, etc.
```

---

## 🐛 Troubleshooting

### Error: "No audio files found"
- **Problem:** `extracted_audio/` folder is empty or missing
- **Solution:** Run the extraction script first: `python extract_audio_files.py`

### Error: "Module not found"
- **Problem:** Missing libraries
- **Solution:** Install: `pip install librosa soundfile pandas matplotlib tqdm`

### Augmentation is too slow
- **Problem:** Processing many files
- **Solution:** Normal! guineafowl (13 files) takes ~1 min, gun_shot (374 files) takes ~5-10 mins

### Files not showing in augmented_audio/
- **Problem:** Step 7 not run or error occurred
- **Solution:** Check terminal output for error messages, re-run Step 7

---

## 💾 Output Files

After successful run:
```
augmented_audio/
├── gun_shot/
│   ├── 7061-6-0-0_original.wav
│   ├── 7061-6-0-0_time_stretch_fast.wav
│   ├── 7061-6-0-0_pitch_up.wav
│   ├── 7061-6-0-0_noise_light.wav
│   └── ... (2,244 total files)
│
└── guineafowl/
    ├── guinea_fowl_01_original.wav
    ├── guinea_fowl_01_pitch_down.wav
    └── ... (143 total files)
```

---

## ✅ Checklist

Before moving to next notebook:

- [ ] All cells run without errors
- [ ] `augmented_audio/` folder created
- [ ] gun_shot has 2,000+ files
- [ ] guineafowl has 100+ files
- [ ] Visualizations show clear before/after comparison
- [ ] Sample audio files sound reasonable (not distorted)

---

## 🚀 What's Next?

Once augmentation is complete:

1. **Create feature extraction notebook** to:
   - Convert audio → Mel-spectrograms
   - Save as numpy arrays for training

2. **Build CNN model** to:
   - Train classifier on augmented data
   - Achieve 90%+ accuracy

3. **Deploy to Raspberry Pi** for:
   - Real-time detection
   - SMS alerts to rangers

---

**Questions? Need help? Just ask!** 🤝
