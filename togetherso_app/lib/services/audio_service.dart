import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          print('Microphone permission denied');
          return false;
        }
      }

      // Get temporary directory for audio file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';

      // Start recording with WAV format (best for API compatibility)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // Match API requirement
          bitRate: 128000,
          numChannels: 1, // Mono
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      print('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the audio file
  Future<File?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('No recording in progress');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null && await File(path).exists()) {
        print('Recording stopped: $path');
        final file = File(path);
        final fileSize = await file.length();
        print('Audio file size: $fileSize bytes');
        return file;
      } else {
        print('Recording file not found');
        return null;
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
            print('Recording cancelled and deleted');
          }
        }
      }
    } catch (e) {
      print('Error cancelling recording: $e');
    }
  }

  /// Get current audio amplitude (for visualization)
  Future<double> getAmplitude() async {
    try {
      if (_isRecording) {
        final amplitude = await _recorder.getAmplitude();
        // Convert to dB scale (approximate)
        final db = 20 * (amplitude.current / amplitude.max);
        return db.clamp(0, 100);
      }
      return 0;
    } catch (e) {
      print('Error getting amplitude: $e');
      return 0;
    }
  }

  /// Check if microphone is available
  Future<bool> isAvailable() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      print('Error checking microphone availability: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _recorder.dispose();
  }
}
