import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:accident_management4/models/biometric_model.dart';
import 'package:accident_management4/models/client_profile_model.dart';
import 'dart:convert';
import 'dart:math';

class BiometricScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _biometricsCollection => _firestore.collection('biometrics');
  CollectionReference get _personsCollection => _firestore.collection('persons');
  CollectionReference get _clientProfilesCollection => _firestore.collection('client_profiles');
  CollectionReference get _scanLogsCollection => _firestore.collection('scan_logs');
  CollectionReference get _auditLogsCollection => _firestore.collection('auditLogs');

  // Identify person by fingerprint scan
  Future<Map<String, dynamic>?> identifyPersonByFingerprint({
    required String scannedTemplate,
    required String scannerLocation,
    String? scannedBy,
  }) async {
    try {
      // Log the scan attempt
      await _logScanAttempt(
        scannedBy: scannedBy,
        location: scannerLocation,
        status: 'initiated',
      );

      // Method 1: Check in person biometrics (for registered persons)
      final personResult = await _searchInPersonBiometrics(scannedTemplate);
      if (personResult != null) {
        await _logScanSuccess(
          personId: personResult['personId'],
          scannedBy: scannedBy,
          location: scannerLocation,
          identificationMethod: 'person_biometrics',
        );
        return personResult;
      }

      // Method 2: Check in client profiles (for app users)
      final clientResult = await _searchInClientProfiles(scannedTemplate);
      if (clientResult != null) {
        await _logScanSuccess(
          personId: clientResult['uid'],
          scannedBy: scannedBy,
          location: scannerLocation,
          identificationMethod: 'client_profile',
        );
        return clientResult;
      }

      // No match found
      await _logScanFailure(
        scannedBy: scannedBy,
        location: scannerLocation,
        reason: 'no_match_found',
      );

      return null;
    } catch (e) {
      await _logScanFailure(
        scannedBy: scannedBy,
        location: scannerLocation,
        reason: 'error: ${e.toString()}',
      );
      throw Exception('Erreur lors de l\'identification: ${e.toString()}');
    }
  }

  // Search in person biometrics collection
  Future<Map<String, dynamic>?> _searchInPersonBiometrics(String scannedTemplate) async {
    try {
      // Get all biometric records
      final QuerySnapshot biometricsSnapshot = await _biometricsCollection
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in biometricsSnapshot.docs) {
        final biometric = BiometricModel.fromFirestore(doc);
        
        // Compare with left thumb
        if (_compareTemplates(scannedTemplate, biometric.leftThumb!.template)) {
          return await _getPersonDetails(biometric.personId, 'biometric_match');
        }
        
        // Compare with right pinky
        if (_compareTemplates(scannedTemplate, biometric.rightPinky!.template)) {
          return await _getPersonDetails(biometric.personId, 'biometric_match');
        }
      }

      return null;
    } catch (e) {
      print('Error searching in person biometrics: $e');
      return null;
    }
  }

  // Search in client profiles collection
  Future<Map<String, dynamic>?> _searchInClientProfiles(String scannedTemplate) async {
    try {
      // Get all client profiles with fingerprints
      final QuerySnapshot profilesSnapshot = await _clientProfilesCollection
          .where('hasFingerprint', isEqualTo: true)
          .get();

      for (var doc in profilesSnapshot.docs) {
        final profile = ClientProfile.fromFirestore(doc);
        
        if (profile.fingerprintData != null &&
            _compareTemplates(scannedTemplate, profile.fingerprintData!)) {
          return _formatClientProfileResult(profile);
        }
      }

      return null;
    } catch (e) {
      print('Error searching in client profiles: $e');
      return null;
    }
  }

  // Compare two biometric templates (mock implementation)
  // In a real app, this would use a proper biometric matching algorithm
  bool _compareTemplates(String template1, String template2) {
    // For simulation: templates match if they're the same
    // In production, use proper biometric matching library
    if (template1 == template2) return true;
    
    // Simulate some matching logic with similarity threshold
    try {
      final bytes1 = base64.decode(template1);
      final bytes2 = base64.decode(template2);
      
      if (bytes1.length != bytes2.length) return false;
      
      // Calculate similarity (mock implementation)
      int matches = 0;
      for (int i = 0; i < min(bytes1.length, 100); i++) {
        if (bytes1[i] == bytes2[i]) matches++;
      }
      
      // If more than 80% match in first 100 bytes (mock threshold)
      return matches > 80;
    } catch (e) {
      return false;
    }
  }

  // Get person details from persons collection
  Future<Map<String, dynamic>?> _getPersonDetails(String personId, String identificationMethod) async {
    try {
      final personDoc = await _personsCollection.doc(personId).get();
      
      if (!personDoc.exists) return null;
      
      final person = PersonModel.fromFirestore(personDoc);
      
      return {
        'personId': person.personId,
        'firstName': person.firstName,
        'lastName': person.lastName,
        'fullName': person.fullName,
        'emergencyContacts': person.emergencyContacts
            .map((contact) => {
                  'name': contact.name,
                  'phoneNumber': contact.phoneNumber,
                  'relationship': contact.relationship,
                  'priority': contact.priority,
                })
            .toList(),
        'photoUrl': person.photoUrl,
        'registeredAt': person.registeredAt.toIso8601String(),
        'identificationMethod': identificationMethod,
        'type': 'registered_person',
      };
    } catch (e) {
      print('Error getting person details: $e');
      return null;
    }
  }

  // Format client profile result
  Map<String, dynamic> _formatClientProfileResult(ClientProfile profile) {
    return {
      'personId': profile.uid,
      'firstName': profile.displayName.split(' ').first,
      'lastName': profile.displayName.split(' ').length > 1
          ? profile.displayName.split(' ').sublist(1).join(' ')
          : '',
      'fullName': profile.displayName,
      'email': profile.email,
      'phoneNumber': profile.phoneNumber,
      'bloodType': profile.bloodType,
      'address': profile.address,
      'emergencyContacts': profile.emergencyContacts
          .map((contact) => {
                'name': contact.name,
                'phoneNumber': contact.phoneNumber,
                'relationship': contact.relationship,
                'priority': contact.priority,
              })
          .toList(),
      'medicalInfo': profile.medicalInfo,
      'photoUrl': profile.photoUrl,
      'identificationMethod': 'client_profile',
      'type': 'app_user',
    };
  }

  // Log scan attempt
  Future<void> _logScanAttempt({
    String? scannedBy,
    required String location,
    required String status,
  }) async {
    try {
      await _scanLogsCollection.add({
        'scannedBy': scannedBy ?? 'anonymous',
        'location': location,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging scan attempt: $e');
    }
  }

  // Log successful scan
  Future<void> _logScanSuccess({
    required String personId,
    String? scannedBy,
    required String location,
    required String identificationMethod,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Add scan log
      final scanRef = _scanLogsCollection.doc();
      batch.set(scanRef, {
        'personId': personId,
        'scannedBy': scannedBy ?? 'anonymous',
        'location': location,
        'status': 'success',
        'identificationMethod': identificationMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Add audit log
      final auditRef = _auditLogsCollection.doc();
      batch.set(auditRef, {
        'userId': scannedBy ?? 'anonymous',
        'action': 'person_identified',
        'targetId': personId,
        'targetType': 'person',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'description': 'Personne identifiée par empreinte digitale',
          'location': location,
          'method': identificationMethod,
        },
      });
      
      await batch.commit();
    } catch (e) {
      print('Error logging scan success: $e');
    }
  }

  // Log failed scan
  Future<void> _logScanFailure({
    String? scannedBy,
    required String location,
    required String reason,
  }) async {
    try {
      await _scanLogsCollection.add({
        'scannedBy': scannedBy ?? 'anonymous',
        'location': location,
        'status': 'failed',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging scan failure: $e');
    }
  }

  // Get recent scan logs
  Stream<List<Map<String, dynamic>>> getRecentScanLogs({int limit = 50}) {
    return _scanLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get scan statistics
  Future<Map<String, dynamic>> getScanStatistics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Get all scan logs
      final allScans = await _scanLogsCollection.get();
      
      int totalScans = 0;
      int successfulScans = 0;
      int failedScans = 0;
      int todayScans = 0;
      int weekScans = 0;
      int monthScans = 0;

      for (var doc in allScans.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        
        if (timestamp != null) {
          totalScans++;
          
          if (data['status'] == 'success') {
            successfulScans++;
          } else if (data['status'] == 'failed') {
            failedScans++;
          }
          
          if (timestamp.isAfter(todayStart)) {
            todayScans++;
          }
          if (timestamp.isAfter(weekStart)) {
            weekScans++;
          }
          if (timestamp.isAfter(monthStart)) {
            monthScans++;
          }
        }
      }

      return {
        'total': totalScans,
        'successful': successfulScans,
        'failed': failedScans,
        'today': todayScans,
        'thisWeek': weekScans,
        'thisMonth': monthScans,
        'successRate': totalScans > 0 
            ? (successfulScans / totalScans * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error getting scan statistics: $e');
      return {
        'total': 0,
        'successful': 0,
        'failed': 0,
        'today': 0,
        'thisWeek': 0,
        'thisMonth': 0,
        'successRate': '0.0',
      };
    }
  }

  // Simulate fingerprint scan (for testing)
  String generateMockFingerprintTemplate() {
    final random = Random();
    final bytes = List<int>.generate(512, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }
}
