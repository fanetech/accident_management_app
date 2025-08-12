import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference for call logs
  CollectionReference get _callLogsCollection => _firestore.collection('emergency_call_logs');

  // Make emergency call
  Future<bool> makeEmergencyCall({
    required String phoneNumber,
    required String personId,
    required String personName,
    required String contactName,
    required String relationship,
    int? priority,
    String? location,
  }) async {
    try {
      // Format phone number for calling
      final formattedNumber = _formatPhoneNumber(phoneNumber);
      
      // Log the call attempt
      await _logCallAttempt(
        personId: personId,
        personName: personName,
        phoneNumber: phoneNumber,
        contactName: contactName,
        relationship: relationship,
        priority: priority,
        location: location,
      );
      
      // Make the actual call
      final Uri phoneUri = Uri(
        scheme: 'tel',
        path: formattedNumber,
      );
      
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        
        // Log successful call initiation
        await _updateCallStatus(
          personId: personId,
          phoneNumber: phoneNumber,
          status: 'initiated',
        );
        
        return true;
      } else {
        // Log failed call
        await _updateCallStatus(
          personId: personId,
          phoneNumber: phoneNumber,
          status: 'failed',
          failureReason: 'unable_to_launch_call',
        );
        
        return false;
      }
    } catch (e) {
      // Log error
      await _updateCallStatus(
        personId: personId,
        phoneNumber: phoneNumber,
        status: 'failed',
        failureReason: e.toString(),
      );
      
      throw Exception('Erreur lors de l\'appel: ${e.toString()}');
    }
  }

  // Send SMS to emergency contact
  Future<bool> sendEmergencySMS({
    required String phoneNumber,
    required String personId,
    required String personName,
    required String message,
    String? location,
  }) async {
    try {
      final formattedNumber = _formatPhoneNumber(phoneNumber);
      
      // Create SMS body with location if available
      String smsBody = message;
      if (location != null && location.isNotEmpty) {
        smsBody += '\n\nLocalisation: $location';
      }
      
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: formattedNumber,
        queryParameters: {'body': smsBody},
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        
        // Log SMS sent
        await _logSMS(
          personId: personId,
          personName: personName,
          phoneNumber: phoneNumber,
          message: smsBody,
          location: location,
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du SMS: ${e.toString()}');
    }
  }

  // Format phone number for proper dialing
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Ensure proper format for Burkina Faso numbers
    if (!cleaned.startsWith('+') && !cleaned.startsWith('00')) {
      // If it's a local number (starts with 0), remove the 0 and add country code
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      // Add Burkina Faso country code
      cleaned = '+226$cleaned';
    }
    
    return cleaned;
  }

  // Log call attempt
  Future<void> _logCallAttempt({
    required String personId,
    required String personName,
    required String phoneNumber,
    required String contactName,
    required String relationship,
    int? priority,
    String? location,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      
      await _callLogsCollection.add({
        'personId': personId,
        'personName': personName,
        'phoneNumber': phoneNumber,
        'contactName': contactName,
        'relationship': relationship,
        'priority': priority ?? 0,
        'location': location,
        'calledBy': currentUser?.uid ?? 'anonymous',
        'callerName': currentUser?.displayName ?? 'Agent de secours',
        'status': 'attempting',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging call attempt: $e');
    }
  }

  // Update call status
  Future<void> _updateCallStatus({
    required String personId,
    required String phoneNumber,
    required String status,
    String? failureReason,
  }) async {
    try {
      // Find the most recent call log for this person and phone number
      final query = await _callLogsCollection
          .where('personId', isEqualTo: personId)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'status': status,
          'failureReason': failureReason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  // Log SMS
  Future<void> _logSMS({
    required String personId,
    required String personName,
    required String phoneNumber,
    required String message,
    String? location,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      
      await _firestore.collection('emergency_sms_logs').add({
        'personId': personId,
        'personName': personName,
        'phoneNumber': phoneNumber,
        'message': message,
        'location': location,
        'sentBy': currentUser?.uid ?? 'anonymous',
        'senderName': currentUser?.displayName ?? 'Agent de secours',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging SMS: $e');
    }
  }

  // Get call history for a person
  Stream<List<Map<String, dynamic>>> getCallHistory(String personId) {
    return _callLogsCollection
        .where('personId', isEqualTo: personId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get recent emergency calls (for dashboard)
  Stream<List<Map<String, dynamic>>> getRecentEmergencyCalls({int limit = 10}) {
    return _callLogsCollection
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

  // Get call statistics
  Future<Map<String, dynamic>> getCallStatistics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      
      final allCalls = await _callLogsCollection.get();
      
      int totalCalls = 0;
      int todayCalls = 0;
      int weekCalls = 0;
      int successfulCalls = 0;
      
      for (var doc in allCalls.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        
        if (timestamp != null) {
          totalCalls++;
          
          if (data['status'] == 'initiated') {
            successfulCalls++;
          }
          
          if (timestamp.isAfter(todayStart)) {
            todayCalls++;
          }
          
          if (timestamp.isAfter(weekStart)) {
            weekCalls++;
          }
        }
      }
      
      return {
        'total': totalCalls,
        'today': todayCalls,
        'thisWeek': weekCalls,
        'successful': successfulCalls,
        'successRate': totalCalls > 0 
            ? (successfulCalls / totalCalls * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error getting call statistics: $e');
      return {
        'total': 0,
        'today': 0,
        'thisWeek': 0,
        'successful': 0,
        'successRate': '0.0',
      };
    }
  }

  // Send batch SMS to all emergency contacts
  Future<Map<String, bool>> sendBatchEmergencySMS({
    required List<Map<String, dynamic>> contacts,
    required String personId,
    required String personName,
    required String message,
    String? location,
  }) async {
    Map<String, bool> results = {};
    
    for (var contact in contacts) {
      final phoneNumber = contact['phoneNumber'] as String?;
      final contactName = contact['name'] as String?;
      
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          final success = await sendEmergencySMS(
            phoneNumber: phoneNumber,
            personId: personId,
            personName: personName,
            message: message,
            location: location,
          );
          
          results[contactName ?? phoneNumber] = success;
        } catch (e) {
          results[contactName ?? phoneNumber] = false;
        }
      }
    }
    
    return results;
  }
}
