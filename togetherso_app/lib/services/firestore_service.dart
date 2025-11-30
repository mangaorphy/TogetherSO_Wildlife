import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/threat_detection.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get detectionsCollection =>
      _firestore.collection('detections');

  /// Save a threat detection to Firestore
  Future<void> saveDetection(ThreatDetection detection) async {
    try {
      await detectionsCollection.doc(detection.id).set(detection.toJson());
      print('Detection saved to Firestore: ${detection.id}');
    } catch (e) {
      print('Error saving detection to Firestore: $e');
      rethrow;
    }
  }

  /// Save multiple detections
  Future<void> saveDetections(List<ThreatDetection> detections) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var detection in detections) {
        DocumentReference docRef = detectionsCollection.doc(detection.id);
        batch.set(docRef, detection.toJson());
      }

      await batch.commit();
      print('${detections.length} detections saved to Firestore');
    } catch (e) {
      print('Error saving batch detections: $e');
      rethrow;
    }
  }

  /// Update detection status
  Future<void> updateDetectionStatus(String id, String newStatus) async {
    try {
      await detectionsCollection.doc(id).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('Detection $id status updated to $newStatus');
    } catch (e) {
      print('Error updating detection status: $e');
      rethrow;
    }
  }

  /// Get all detections (real-time stream)
  Stream<List<ThreatDetection>> getDetectionsStream() {
    return detectionsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ThreatDetection.fromJson(data);
          }).toList();
        });
  }

  /// Get detections by status
  Stream<List<ThreatDetection>> getDetectionsByStatus(String status) {
    return detectionsCollection
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ThreatDetection.fromJson(data);
          }).toList();
        });
  }

  /// Get detections by priority
  Stream<List<ThreatDetection>> getDetectionsByPriority(String priority) {
    return detectionsCollection
        .where('priority', isEqualTo: priority)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ThreatDetection.fromJson(data);
          }).toList();
        });
  }

  /// Get detections from last 24 hours
  Stream<List<ThreatDetection>> getRecentDetections() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    return detectionsCollection
        .where('timestamp', isGreaterThan: yesterday.toIso8601String())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ThreatDetection.fromJson(data);
          }).toList();
        });
  }

  /// Delete a detection
  Future<void> deleteDetection(String id) async {
    try {
      await detectionsCollection.doc(id).delete();
      print('Detection $id deleted from Firestore');
    } catch (e) {
      print('Error deleting detection: $e');
      rethrow;
    }
  }

  /// Delete all detections
  Future<void> deleteAllDetections() async {
    try {
      final snapshot = await detectionsCollection.get();
      WriteBatch batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All detections deleted from Firestore');
    } catch (e) {
      print('Error deleting all detections: $e');
      rethrow;
    }
  }

  /// Get detection by ID
  Future<ThreatDetection?> getDetectionById(String id) async {
    try {
      final doc = await detectionsCollection.doc(id).get();
      if (doc.exists) {
        return ThreatDetection.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting detection by ID: $e');
      rethrow;
    }
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final snapshot = await detectionsCollection.get();
      final detections = snapshot.docs.map((doc) {
        return ThreatDetection.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      return {
        'total': detections.length,
        'critical': detections.where((d) => d.priority == 'CRITICAL').length,
        'high': detections.where((d) => d.priority == 'HIGH').length,
        'medium': detections.where((d) => d.priority == 'MEDIUM').length,
        'low': detections.where((d) => d.priority == 'LOW').length,
        'pending': detections.where((d) => d.status == 'pending').length,
        'resolved': detections.where((d) => d.status == 'resolved').length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }
}
