import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../providers/location_provider.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../models/threat_detection.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _listeningTimer;
  bool _isListening = false;
  String _currentStatus = 'Tap to start listening';
  double _audioLevel = 0;
  Timer? _audioLevelTimer;

  // Services
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();

  // Recording state
  bool _isProcessing = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _listeningTimer?.cancel();
    _audioLevelTimer?.cancel();
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _startListening();
      } else {
        _stopListening();
      }
    });
  }

  void _startListening() async {
    // Check API connection first
    setState(() {
      _currentStatus = 'Checking API connection...';
    });

    final isConnected = await _apiService.testConnection();
    if (!isConnected) {
      if (mounted) {
        _showErrorDialog(
          'API Not Available',
          'Cannot connect to the prediction API. Please ensure the server is running.',
        );
        setState(() {
          _currentStatus = 'API connection failed';
          _isListening = false;
        });
      }
      return;
    }

    _pulseController.repeat();
    setState(() {
      _currentStatus = 'Listening for sounds...';
    });

    // Get real audio level from microphone
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      if (mounted && _audioService.isRecording) {
        final amplitude = await _audioService.getAmplitude();
        setState(() {
          _audioLevel = amplitude;
        });
      }
    });

    // Start continuous recording and prediction cycle
    _listeningTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _isListening && !_isProcessing) {
        _recordAndPredict();
      }
    });

    // Start first recording immediately
    _recordAndPredict();
  }

  void _stopListening() async {
    _pulseController.stop();
    _listeningTimer?.cancel();
    _audioLevelTimer?.cancel();
    _recordingTimer?.cancel();

    // Stop any ongoing recording
    if (_audioService.isRecording) {
      await _audioService.cancelRecording();
    }

    setState(() {
      _currentStatus = 'Tap to start listening';
      _audioLevel = 0;
      _recordingDuration = 0;
      _isProcessing = false;
    });
  }

  void _recordAndPredict() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentStatus = 'Recording audio...';
      _recordingDuration = 0;
    });

    // Start recording
    final started = await _audioService.startRecording();
    if (!started) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStatus = 'Microphone permission required';
        });
        _showErrorDialog(
          'Permission Required',
          'Please grant microphone permission to use this feature.',
        );
      }
      return;
    }

    // Track recording duration
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration++;
        });
      }
    });

    // Record for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    _recordingTimer?.cancel();

    if (!mounted || !_isListening) return;

    setState(() {
      _currentStatus = 'Processing audio...';
    });

    // Stop recording and get file
    final audioFile = await _audioService.stopRecording();
    if (audioFile == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStatus = 'Recording failed';
        });
      }
      return;
    }

    try {
      // Send to API for prediction
      setState(() {
        _currentStatus = 'Analyzing threat...';
      });

      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final lat = locationProvider.latitude;
      final lon = locationProvider.longitude;
      
      print('📍 Sending GPS: $lat, $lon');
      
      final apiResponse = await _apiService.predictAudio(
        audioFile: audioFile,
        latitude: lat,
        longitude: lon,
      );
      
      // API doesn't return GPS, so create detection with our GPS
      final detection = ThreatDetection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        threatType: apiResponse.threatType,
        confidence: apiResponse.confidence,
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lon,
        status: apiResponse.confidence > 0.7 ? 'critical' : 'pending',
        priority: apiResponse.priority,
      );
      
      print('📍 Detection created with GPS: ${detection.latitude}, ${detection.longitude}');

      // Save to Firestore
      final provider = Provider.of<DetectionProvider>(context, listen: false);
      await provider.saveDetection(detection);

      // Show alert if confidence is high enough (>50%)
      if (detection.confidence > 0.5) {
        if (mounted) {
          _showDetectionDialog(detection.threatType, detection);
        }
      }

      if (mounted) {
        setState(() {
          _currentStatus = 'Listening for sounds...';
          _isProcessing = false;
        });
      }

      // Clean up audio file
      await audioFile.delete();
    } catch (e) {
      print('Error during prediction: $e');
      if (mounted) {
        setState(() {
          _currentStatus = 'Prediction error - retrying...';
          _isProcessing = false;
        });

        // Show error for critical failures
        if (e.toString().contains('API') ||
            e.toString().contains('connection')) {
          _showErrorDialog(
            'Prediction Failed',
            'Could not connect to the API. Check your connection and try again.',
          );
        }
      }

      // Clean up audio file
      try {
        await audioFile.delete();
      } catch (_) {}
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDetectionDialog(String threatType, detection) {
    if (!mounted) return;

    // Play alert sound (simulated)
    _currentStatus = 'THREAT DETECTED!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: detection.priorityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning,
                color: detection.priorityColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${detection.displayName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(detection.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: detection.priorityColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm:ss').format(detection.timestamp),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${detection.latitude.toStringAsFixed(4)}, ${detection.longitude.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentStatus = 'Listening for sounds...';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to map or alerts
                      setState(() {
                        _currentStatus = 'Listening for sounds...';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: detection.priorityColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('View Alerts'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          'Live Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2D5F3F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options menu
            },
          ),
        ],
      ),
      body: Consumer<DetectionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Status Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D5F3F),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currentStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isListening) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isProcessing
                                  ? Icons.rotate_right
                                  : Icons.sensors,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isProcessing
                                  ? 'Recording: ${_recordingDuration}s'
                                  : 'Audio Level: ${_audioLevel.toStringAsFixed(0)} dB',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Microphone Button
                Center(
                  child: GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0xFF2D5F3F)
                                : Colors.grey[300],
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2D5F3F)
                                          .withOpacity(
                                            0.3 +
                                                (_pulseController.value * 0.3),
                                          ),
                                      blurRadius:
                                          30 + (_pulseController.value * 20),
                                      spreadRadius:
                                          10 + (_pulseController.value * 10),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 70,
                            color: _isListening
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Start/Stop Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: _toggleListening,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening
                          ? Colors.red
                          : const Color(0xFF2D5F3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isListening ? Icons.stop : Icons.play_arrow),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? 'Stop Listening' : 'Start Listening',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Audio Waveform (Visual indicator)
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            20,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 4,
                              height:
                                  10 + ((index + _audioLevel) % 40).toDouble(),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5F3F),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // Recent Detections
                if (provider.detections.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Detections',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: provider.criticalThreats > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF2D5F3F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${provider.detections.length} Total',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.detections.take(5).length,
                            itemBuilder: (context, index) {
                              final detection = provider.detections[index];
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: detection.priorityColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: detection.priorityColor.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detection.priorityColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        detection.priority.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      detection.displayName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(detection.confidence * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: detection.priorityColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'HH:mm:ss',
                                      ).format(detection.timestamp),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
