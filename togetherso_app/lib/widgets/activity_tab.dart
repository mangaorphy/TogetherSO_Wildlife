import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/detection_provider.dart';

class ActivityTab extends StatelessWidget {
  final DetectionProvider provider;

  const ActivityTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.detections.isEmpty) {
      return _buildEmptyState();
    }

    // Group detections by date
    final groupedDetections = _groupByDate(provider.detections);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedDetections.length,
      itemBuilder: (context, index) {
        final entry = groupedDetections.entries.elementAt(index);
        return _buildDateGroup(entry.key, entry.value);
      },
    );
  }

  Map<String, List> _groupByDate(List detections) {
    final Map<String, List> grouped = {};
    for (final detection in detections) {
      final dateKey = DateFormat('MMM d, yyyy').format(detection.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(detection);
    }
    return grouped;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity will appear here as detections come in',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String date, List detections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...detections
            .map((detection) => _buildActivityItem(detection))
            ,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActivityItem(detection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: detection.priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detection.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(detection.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: detection.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        detection.priority,
                        style: TextStyle(
                          color: detection.priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(detection.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
