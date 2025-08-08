import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accident_management4/models/client_profile_model.dart';

class ClientProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _clientProfilesCollection => 
      _firestore.collection('client_profiles');

  // Get current user's profile
  Future<ClientProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _clientProfilesCollection.doc(user.uid).get();
      if (!doc.exists) {
        // Create initial profile if it doesn't exist
        return await _createInitialProfile(user);
      }

      return ClientProfile.fromFirestore(doc);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create initial profile for new user
  Future<ClientProfile?> _createInitialProfile(User user) async {
    try {
      final profile = ClientProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        phoneNumber: user.phoneNumber,
        emergencyContacts: [],
        profileCompleted: false,
        createdAt: DateTime.now(),
      );

      await _clientProfilesCollection.doc(user.uid).set(profile.toFirestore());
      return profile;
    } catch (e) {
      print('Error creating initial profile: $e');
      return null;
    }
  }

  // Check if profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isProfileComplete ?? false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  // Get missing profile fields
  Future<List<String>> getMissingProfileFields() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.missingFields ?? [];
    } catch (e) {
      print('Error getting missing fields: $e');
      return [];
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? bloodType,
    Map<String, dynamic>? medicalInfo,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (dateOfBirth != null) updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (bloodType != null) updates['bloodType'] = bloodType;
      if (medicalInfo != null) updates['medicalInfo'] = medicalInfo;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _clientProfilesCollection.doc(user.uid).update(updates);
      
      // Check if profile is now complete
      await _checkAndUpdateProfileCompletion();
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Add or update emergency contacts
  Future<bool> updateEmergencyContacts(List<ClientEmergencyContact> contacts) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Ensure we have at most 3 contacts with proper priority
      final sortedContacts = contacts.take(3).toList();
      for (int i = 0; i < sortedContacts.length; i++) {
        sortedContacts[i] = ClientEmergencyContact(
          name: sortedContacts[i].name,
          phoneNumber: sortedContacts[i].phoneNumber,
          relationship: sortedContacts[i].relationship,
          priority: i + 1,
        );
      }

      await _clientProfilesCollection.doc(user.uid).update({
        'emergencyContacts': sortedContacts.map((e) => e.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _checkAndUpdateProfileCompletion();
      return true;
    } catch (e) {
      print('Error updating emergency contacts: $e');
      return false;
    }
  }

  // Update fingerprint data
  Future<bool> updateFingerprintData(String fingerprintData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _clientProfilesCollection.doc(user.uid).update({
        'fingerprintData': fingerprintData,
        'hasFingerprint': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _checkAndUpdateProfileCompletion();
      return true;
    } catch (e) {
      print('Error updating fingerprint: $e');
      return false;
    }
  }

  // Check and update profile completion status
  Future<void> _checkAndUpdateProfileCompletion() async {
    try {
      final profile = await getCurrentUserProfile();
      if (profile != null) {
        await _clientProfilesCollection.doc(profile.uid).update({
          'profileCompleted': profile.isProfileComplete,
        });
      }
    } catch (e) {
      print('Error updating profile completion status: $e');
    }
  }

  // Stream of profile changes
  Stream<ClientProfile?> profileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _clientProfilesCollection
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? ClientProfile.fromFirestore(doc) : null);
  }

  // Delete profile (for account deletion)
  Future<bool> deleteProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _clientProfilesCollection.doc(user.uid).delete();
      return true;
    } catch (e) {
      print('Error deleting profile: $e');
      return false;
    }
  }

  // Check if user has any registration (to prevent multiple registrations)
  Future<bool> hasExistingRegistration() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _clientProfilesCollection.doc(user.uid).get();
      if (!doc.exists) return false;

      final profile = ClientProfile.fromFirestore(doc);
      // Check if user has at least emergency contacts and fingerprint
      return profile.emergencyContacts.isNotEmpty || profile.hasFingerprint;
    } catch (e) {
      print('Error checking existing registration: $e');
      return false;
    }
  }
}
