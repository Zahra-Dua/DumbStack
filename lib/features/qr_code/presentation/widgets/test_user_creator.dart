import 'package:flutter/material.dart';
import '../../../user_management/data/models/user_model.dart';

class TestUserCreator extends StatelessWidget {
  final Function(UserModel) onUserCreated;

  const TestUserCreator({
    super.key,
    required this.onUserCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test User Creator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Create test users to test QR code functionality:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createTestUser('parent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Parent'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createTestUser('child'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Child'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createTestUser('guardian'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Guardian'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _createTestUser('admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Create Admin'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createTestUser(String userType) {
    final user = UserModel(
      uid: 'test_${userType}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test ${userType.capitalize()}',
      email: 'test_$userType@example.com',
      userType: userType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    onUserCreated(user);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
