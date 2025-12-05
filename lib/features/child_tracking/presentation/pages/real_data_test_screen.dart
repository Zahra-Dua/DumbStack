import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/real_data_collection_service.dart';
class RealDataTestScreen extends StatefulWidget {
  const RealDataTestScreen({super.key});
  @override
  State<RealDataTestScreen> createState() => _RealDataTestScreenState();
}
class _RealDataTestScreenState extends State<RealDataTestScreen> {
  final RealDataCollectionService _dataService = RealDataCollectionService();
  bool _isCollecting = false;
  String _status = 'Ready to start data collection';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Data Collection'),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCollecting 
                          ? 'Collecting real data from device...'
                          : 'Data collection stopped',
                      style: TextStyle(
                        color: _isCollecting ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCollecting ? null : _startRealDataCollection,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Real Collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCollecting ? _stopRealDataCollection : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Test Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulateRealData,
                icon: const Icon(Icons.science),
                label: const Text('Simulate Real Data (For Testing)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Real Data Collection Info:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Collects real URLs visited by child'),
                    const Text('• Collects real app usage data'),
                    const Text('• Uploads to Firebase automatically'),
                    const Text('• Parent can see all data in real-time'),
                    const SizedBox(height: 8),
                    Text(
                      'Child ID: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not logged in'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRealDataCollection() async {
    try {
      setState(() {
        _isCollecting = true;
        _status = 'Starting real data collection...';
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _status = 'Error: User not logged in';
          _isCollecting = false;
        });
        return;
      }

      // For now, using current user as both child and parent
      // In real app, you'd get parent ID from your relationship system
      await _dataService.initializeRealDataCollection(
        childId: currentUser.uid,
        parentId: currentUser.uid, // This should be actual parent ID
      );

      setState(() {
        _status = 'Real data collection started successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real data collection started!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isCollecting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRealDataCollection() async {
    try {
      await _dataService.stopRealDataCollection();
      
      setState(() {
        _isCollecting = false;
        _status = 'Real data collection stopped';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real data collection stopped!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error stopping: $e';
      });
    }
  }

  Future<void> _simulateRealData() async {
    try {
      setState(() {
        _status = 'Simulating real data...';
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _status = 'Error: User not logged in';
        });
        return;
      }

      await _dataService.simulateRealDataCollection(
        childId: currentUser.uid,
        parentId: currentUser.uid, // This should be actual parent ID
      );

      setState(() {
        _status = 'Simulated real data uploaded successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated real data uploaded to Firebase!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'Error simulating data: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}




