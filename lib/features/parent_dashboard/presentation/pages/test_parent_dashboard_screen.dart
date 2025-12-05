import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../bloc/parent_dashboard_bloc.dart';
import '../bloc/parent_dashboard_event.dart';
import '../../data/services/parent_dashboard_firebase_service.dart';
import 'parent_dashboard_screen.dart';

class TestParentDashboardScreen extends StatefulWidget {
  const TestParentDashboardScreen({super.key});

  @override
  State<TestParentDashboardScreen> createState() => _TestParentDashboardScreenState();
}

class _TestParentDashboardScreenState extends State<TestParentDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Parent Dashboard'),
        backgroundColor: Colors.purple[100],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (_currentUserId != null) {
                context.read<ParentDashboardBloc>().add(LoadDashboardData(
                  childId: _currentUserId!,
                  parentId: _currentUserId!,
                ));
              }
            },
          ),
        ],
      ),
      body: _currentUserId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No user logged in',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Please log in to view the dashboard'),
                ],
              ),
            )
          : BlocProvider(
              create: (context) => ParentDashboardBloc(
                firebaseService: ParentDashboardFirebaseService(),
              )
                ..add(LoadDashboardData(
                  childId: _currentUserId!,
                  parentId: _currentUserId!,
                )),
              child: ParentDashboardScreen(
                childId: _currentUserId!,
                childName: 'Test Child',
                parentId: _currentUserId!,
              ),
            ),
    );
  }
}
