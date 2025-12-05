import 'package:flutter/material.dart';

class DailyScreenTimeChart extends StatelessWidget {
  final List<Map<String, dynamic>> dailyData;

  const DailyScreenTimeChart({
    super.key,
    required this.dailyData,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxMinutes = dailyData.map((d) => d['totalMinutes'] as int).reduce((a, b) => a > b ? a : b);
    final maxHeight = 150.0;

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chart
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyData.map((day) {
                final minutes = day['totalMinutes'] as int;
                final height = maxMinutes > 0 ? (minutes / maxMinutes) * maxHeight : 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bar
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Day label
                    Text(
                      day['dayName'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    // Hours label
                    Text(
                      '${day['totalHours']}h',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
