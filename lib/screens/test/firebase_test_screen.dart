import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Test screen to debug Firebase issues
/// This is for debugging only - remove in production
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      // Test 1: Firebase Auth
      setState(() => _status = 'Testing Firebase Auth...');
      final auth = FirebaseAuth.instance;
      print('Firebase Auth instance: $auth');
      
      // Test 2: Firestore
      setState(() => _status = 'Testing Firestore...');
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('test').get();
      
      setState(() => _status = '✅ Firebase connection successful!');
    } catch (e) {
      setState(() => _status = '❌ Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCreateUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test user...';
    });

    try {
      // Generate random email
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'test_$timestamp@test.com';
      const password = 'Test123456';
      
      setState(() => _status = 'Creating auth account for: $email');
      
      // Create auth account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw 'User creation failed - null user';
      }
      
      setState(() => _status = 'Auth account created. Creating Firestore document...');
      
      // Create Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'role': 'test_user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      setState(() => _status = 'Firestore document created. Cleaning up...');
      
      // Clean up - delete the test user
      await credential.user!.delete();
      
      setState(() => _status = '✅ Test successful! User created and deleted.');
      
    } catch (e) {
      setState(() => _status = '❌ Error: ${e.toString()}');
      print('Full error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSimpleAuth() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing simple auth creation...';
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'simple_$timestamp@test.com';
      
      // Most basic auth creation
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'SimpleTest123',
      );
      
      // setState(() => _status = 'Created user: ${cred.user?.uid}');
      
      // // Delete immediately
      // await cred.user?.delete();
      
      setState(() => _status = '✅ Simple auth test passed!');
      
    } catch (e) {
      setState(() => _status = '❌ Simple auth failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test (Dev Only)'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Firebase Debugging Tool',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This screen tests Firebase connectivity.\nRemove in production!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: _status.contains('✅') 
                          ? Colors.green 
                          : _status.contains('❌') 
                              ? Colors.red 
                              : null,
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              icon: const Icon(Icons.cloud_queue),
              label: const Text('Test Firebase Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSimpleAuth,
              icon: const Icon(Icons.person_add),
              label: const Text('Test Simple Auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCreateUser,
              icon: const Icon(Icons.bug_report),
              label: const Text('Full Test (Auth + Firestore)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const Spacer(),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
