import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/threat_detection.dart';

class ApiService {
  // API base URL - production Railway endpoint
  static String get baseUrl => 'https://ecosight-api-production.up.railway.app';

  /// Check if API is healthy
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API health check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking API health: $e');
      rethrow;
    }
  }

  /// Get available threat classes
  Future<Map<String, dynamic>> getClasses() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/classes'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get classes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting classes: $e');
      rethrow;
    }
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/model-info'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get model info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting model info: $e');
      rethrow;
    }
  }

  /// Predict threat from audio file
  Future<ThreatDetection> predictAudio({
    required File audioFile,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      // Add GPS coordinates if provided
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }

      // Send request
      print('Sending audio file to API: ${audioFile.path}');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          'Prediction received: ${data['predicted_class']} (${data['confidence']})',
        );

        // Convert to ThreatDetection model
        return ThreatDetection.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception('Prediction failed: ${error['detail']}');
      }
    } catch (e) {
      print('Error predicting audio: $e');
      rethrow;
    }
  }

  /// Predict threats from multiple audio files
  Future<List<Map<String, dynamic>>> batchPredict({
    required List<File> audioFiles,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/batch-predict'),
      );

      // Add all audio files
      for (var file in audioFiles) {
        request.files.add(
          await http.MultipartFile.fromPath('files', file.path),
        );
      }

      print('Sending ${audioFiles.length} files for batch prediction');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        final error = json.decode(response.body);
        throw Exception('Batch prediction failed: ${error['detail']}');
      }
    } catch (e) {
      print('Error in batch prediction: $e');
      rethrow;
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final health = await healthCheck();
      return health['model_loaded'] == true;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }


}
