import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/detection_provider.dart';
import '../widgets/alerts_tab.dart';
import '../widgets/activity_tab.dart';
import '../widgets/map_tab.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final detectionProvider = Provider.of<DetectionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text(
          'Live Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Real-time threat detection and alerts from ranger devices',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                _buildTabs(),
              ],
            ),
          ),
          Expanded(child: _buildSelectedTab(detectionProvider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSimulateDialog(context, detectionProvider);
        },
        backgroundColor: const Color(0xFF2D5F3F),
        icon: const Icon(Icons.add),
        label: const Text('Simulate Alert'),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildTab(
            icon: Icons.notifications,
            label: 'Alerts',
            isSelected: _selectedTabIndex == 0,
            onTap: () => setState(() => _selectedTabIndex = 0),
          ),
        ),
        Expanded(
          child: _buildTab(
            icon: Icons.show_chart,
            label: 'Activity',
            isSelected: _selectedTabIndex == 1,
            onTap: () => setState(() => _selectedTabIndex = 1),
          ),
        ),
        Expanded(
          child: _buildTab(
            icon: Icons.map,
            label: 'Map',
            isSelected: _selectedTabIndex == 2,
            onTap: () => setState(() => _selectedTabIndex = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2D5F3F) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF2D5F3F) : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF2D5F3F) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTab(DetectionProvider provider) {
    switch (_selectedTabIndex) {
      case 0:
        return AlertsTab(provider: provider);
      case 1:
        return ActivityTab(provider: provider);
      case 2:
        return MapTab(provider: provider);
      default:
        return AlertsTab(provider: provider);
    }
  }

  void _showSimulateDialog(BuildContext context, DetectionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Gun Shot (CRITICAL)'),
              onTap: () {
                provider.simulateDetection('gun_shot', 'CRITICAL');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.record_voice_over,
                color: Colors.orange,
              ),
              title: const Text('Human Voices (HIGH)'),
              onTap: () {
                provider.simulateDetection('human_voices', 'HIGH');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.blue),
              title: const Text('Engine Idling (MEDIUM)'),
              onTap: () {
                provider.simulateDetection('engine_idling', 'MEDIUM');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.green),
              title: const Text('Dog Bark (LOW)'),
              onTap: () {
                provider.simulateDetection('dog_bark', 'LOW');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
