import 'package:flutter/material.dart';

class ThreatDetection {
  final String id;
  final String threatType;
  final double confidence;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String status; // 'critical', 'pending', 'resolved'
  final String priority; // 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'

  ThreatDetection({
    required this.id,
    required this.threatType,
    required this.confidence,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.status = 'pending',
    required this.priority,
  });

  factory ThreatDetection.fromJson(Map<String, dynamic> json) {
    return ThreatDetection(
      id: json['id'] ?? '',
      threatType: json['predicted_class'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'LOW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'predicted_class': threatType,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'priority': priority,
    };
  }

  String get displayName {
    return threatType.replaceAll('_', ' ').toUpperCase();
  }

  Color get priorityColor {
    switch (priority) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFF59E0B);
      case 'MEDIUM':
        return const Color(0xFF3B82F6);
      case 'LOW':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
