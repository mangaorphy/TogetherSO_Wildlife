import 'package:flutter/material.dart';
import '../models/threat_detection.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class DetectionProvider with ChangeNotifier {
  List<ThreatDetection> _detections = [];
  bool _isMonitoring = false;
  bool _isOnline = true;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _detectionsSubscription;

  List<ThreatDetection> get detections => _detections;
  bool get isMonitoring => _isMonitoring;
  bool get isOnline => _isOnline;

  int get totalAlerts => _detections.length;
  int get criticalThreats => _detections
      .where((d) => d.status == 'critical' && d.priority == 'CRITICAL')
      .length;
  int get pendingAlerts =>
      _detections.where((d) => d.status == 'pending').length;
  int get resolvedAlerts =>
      _detections.where((d) => d.status == 'resolved').length;

  DetectionProvider() {
    // Initialize real-time sync with Firestore with delay
    Future.delayed(const Duration(seconds: 2), () {
      _initializeFirestoreSync();
    });
  }

  /// Initialize real-time sync with Firestore
  void _initializeFirestoreSync() {
    try {
      _detectionsSubscription = _firestoreService.getDetectionsStream().listen(
        (detections) {
          _detections = detections;
          _isOnline = true;
          notifyListeners();
        },
        onError: (error) {
          print('Error syncing detections from Firestore: $error');
          _isOnline = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Failed to initialize Firestore sync: $e');
      _isOnline = false;
    }
  }

  void toggleMonitoring() {
    _isMonitoring = !_isMonitoring;
    notifyListeners();
  }

  void setOnlineStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }

  /// Add detection and sync to Firestore
  Future<void> addDetection(ThreatDetection detection) async {
    try {
      // Add to Firestore (will automatically update via stream)
      await _firestoreService.saveDetection(detection);
      _isOnline = true;
    } catch (e) {
      print('Error adding detection: $e');
      _isOnline = false;
      // Add locally if offline
      _detections.insert(0, detection);
      notifyListeners();
    }
  }

  /// Save detection (alias for addDetection)
  Future<void> saveDetection(ThreatDetection detection) async {
    await addDetection(detection);
  }

  /// Update detection status and sync to Firestore
  Future<void> updateDetectionStatus(String id, String newStatus) async {
    try {
      // Update in Firestore (will automatically update via stream)
      await _firestoreService.updateDetectionStatus(id, newStatus);
      _isOnline = true;
    } catch (e) {
      print('Error updating detection status: $e');
      _isOnline = false;
      // Update locally if offline
      final index = _detections.indexWhere((d) => d.id == id);
      if (index != -1) {
        _detections[index] = ThreatDetection(
          id: _detections[index].id,
          threatType: _detections[index].threatType,
          confidence: _detections[index].confidence,
          timestamp: _detections[index].timestamp,
          latitude: _detections[index].latitude,
          longitude: _detections[index].longitude,
          status: newStatus,
          priority: _detections[index].priority,
        );
        notifyListeners();
      }
    }
  }

  /// Simulate detection for testing and save to Firestore
  Future<void> simulateDetection(String threatType, String priority) async {
    final detection = ThreatDetection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      threatType: threatType,
      confidence: 0.85 + (0.15 * (DateTime.now().millisecond % 100) / 100),
      timestamp: DateTime.now(),
      latitude: -1.2921 + (DateTime.now().millisecond % 100) / 10000,
      longitude: 36.8219 + (DateTime.now().millisecond % 100) / 10000,
      status: priority == 'CRITICAL' ? 'critical' : 'pending',
      priority: priority,
    );
    await addDetection(detection);
  }

  /// Clear all detections from Firestore and local
  Future<void> clearAllDetections() async {
    try {
      await _firestoreService.deleteAllDetections();
      _isOnline = true;
    } catch (e) {
      print('Error clearing detections: $e');
      _isOnline = false;
      // Clear locally if offline
      _detections.clear();
      notifyListeners();
    }
  }

  /// Get statistics from Firestore
  Future<Map<String, int>> getStatistics() async {
    try {
      return await _firestoreService.getStatistics();
    } catch (e) {
      print('Error getting statistics: $e');
      // Return local statistics if offline
      return {
        'total': totalAlerts,
        'critical': criticalThreats,
        'pending': pendingAlerts,
        'resolved': resolvedAlerts,
      };
    }
  }

  @override
  void dispose() {
    _detectionsSubscription?.cancel();
    super.dispose();
  }
}
