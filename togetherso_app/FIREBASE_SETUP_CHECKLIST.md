# 🔥 Firebase Setup Checklist - EcoSight

## ✅ Completed Steps

- [x] Install Firebase packages (firebase_core, cloud_firestore, firebase_auth)
- [x] Configure firebase_options.dart for all platforms
- [x] Initialize Firebase in main.dart
- [x] Create FirestoreService for data operations
- [x] Update DetectionProvider with real-time sync
- [x] Add offline support
- [x] Implement automatic cloud backup

## ⏳ Required Setup in Firebase Console

### Step 1: Enable Firestore Database
1. Go to https://console.firebase.google.com
2. Select project: **ecosight-79869**
3. Click "**Firestore Database**" in left menu
4. Click "**Create database**"
5. Select region (recommended: **us-central1** or closest to Kenya)
6. Choose "**Start in test mode**" for now
7. Click "**Enable**"

### Step 2: Update Security Rules (Important!)

**For Testing (Current):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**For Production (Later):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /detections/{detectionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

### Step 3: Create Indexes (Optional but Recommended)

Go to "Indexes" tab and create:

**Index 1:**
- Collection ID: `detections`
- Fields to index:
  - `status` (Ascending)
  - `timestamp` (Descending)
- Query scope: Collection

**Index 2:**
- Collection ID: `detections`
- Fields to index:
  - `priority` (Ascending)
  - `timestamp` (Descending)
- Query scope: Collection

## 🚀 Testing Steps

### 1. Run the App
```bash
cd /Users/cococe/Desktop/TogetherSO_Wildlife/togetherso_app
flutter run
```

### 2. Create Test Detection
- Open app
- Go to "Monitor" tab
- Tap microphone button to start listening
- Wait for automatic detection OR
- Go to "Monitoring" screen and tap simulate button

### 3. Verify in Firebase Console
- Open Firebase Console
- Go to Firestore Database
- Click on "detections" collection
- You should see your test detections appear in real-time!

### 4. Test Real-Time Sync
- Open app on Device 1
- Create a detection
- Open Firestore Console
- See detection appear instantly
- Make changes in console
- See changes reflected in app instantly

### 5. Test Offline Mode
- Turn off WiFi on device
- Create some detections
- Detections saved locally
- Turn WiFi back on
- Detections sync to Firestore automatically

## 📊 What You'll See in Firestore

### Collection: `detections`

Example document:
```json
{
  "id": "1699521234567",
  "predicted_class": "gun_shot",
  "confidence": 0.94,
  "timestamp": "2025-11-09T16:25:06.000Z",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "status": "pending",
  "priority": "CRITICAL"
}
```

## 🎯 Expected Behavior

### When Creating Detection:
1. Detection appears in app instantly
2. Detection saved to Firestore
3. All connected devices see the detection
4. Works offline (syncs when online)

### When Updating Status:
1. Status updated in app
2. Status synced to Firestore
3. All devices see updated status

### When Viewing Alerts:
1. Real-time updates from Firestore
2. Sorted by timestamp (newest first)
3. Color-coded by priority

## 🔍 How to Verify It's Working

### Check 1: Console Logs
Look for these messages in terminal:
```
Detection saved to Firestore: 1699521234567
✓ Firestore sync active
```

### Check 2: Firebase Console
- Go to Firestore Database
- See documents being created in real-time
- Total document count should match app

### Check 3: Network Tab (Chrome DevTools)
- Open app in Chrome
- Press F12 → Network tab
- Filter: "firestore"
- See API calls being made

## ⚠️ Troubleshooting

### Problem: "Permission Denied" Error
**Solution:** 
1. Go to Firestore → Rules
2. Update to test mode rules (see Step 2 above)
3. Publish rules

### Problem: "Firebase not initialized"
**Solution:**
1. Check that `Firebase.initializeApp()` is in main.dart
2. Verify firebase_options.dart exists
3. Restart app

### Problem: Detections Not Syncing
**Solution:**
1. Check internet connection
2. Verify Firestore is enabled in Firebase Console
3. Check security rules
4. Look for errors in console

### Problem: "Index Required" Error
**Solution:**
1. Click the link in error message
2. Creates index automatically
3. Wait 1-2 minutes for index to build
4. Try query again

## 📱 Platform-Specific Setup

### Android
No additional setup required - already configured!

### iOS
No additional setup required - already configured!

### Web
No additional setup required - already configured!

## 🎊 Success Criteria

You'll know Firebase is working when:
- ✅ App starts without errors
- ✅ Detections appear in Firestore Console
- ✅ Real-time sync works (changes appear instantly)
- ✅ Offline mode works (syncs when back online)
- ✅ Multiple devices show same data

## 📞 Support

If you encounter issues:
1. Check FIREBASE_INTEGRATION.md for detailed documentation
2. Check Firebase Console for error logs
3. Look at terminal output for error messages
4. Verify all steps in this checklist completed

---

**Status:** Ready for Testing ✅  
**Next Step:** Enable Firestore in Firebase Console and test!
