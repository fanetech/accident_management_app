import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:accident_management4/models/biometric_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PersonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _personsCollection => _firestore.collection('persons');
  CollectionReference get _biometricsCollection => _firestore.collection('biometrics');
  CollectionReference get _auditLogsCollection => _firestore.collection('auditLogs');

  // Create a new person with biometric data
  Future<String> createPersonWithBiometrics({
    required String firstName,
    required String lastName,
    required List<EmergencyContact> emergencyContacts,
    required Map<String, dynamic> leftThumbData,
    required Map<String, dynamic> rightPinkyData,
    String? photoUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Start a batch write for atomic operation
      final batch = _firestore.batch();

      // Create person document
      final personRef = _personsCollection.doc();
      final personModel = PersonModel(
        personId: personRef.id,
        firstName: firstName,
        lastName: lastName,
        registeredBy: currentUser.uid,
        registeredAt: DateTime.now(),
        emergencyContacts: emergencyContacts,
        status: 'active',
        photoUrl: photoUrl,
      );

      batch.set(personRef, personModel.toFirestore());

      // Create biometric document
      final biometricRef = _biometricsCollection.doc();
      final deviceInfo = await _getDeviceInfo();
      
      final biometricModel = BiometricModel(
        biometricId: biometricRef.id,
        personId: personRef.id,
        leftThumb: BiometricData(
          template: leftThumbData['template'] ?? '',
          quality: leftThumbData['quality'] ?? 0,
          capturedAt: DateTime.now(),
        ),
        rightPinky: BiometricData(
          template: rightPinkyData['template'] ?? '',
          quality: rightPinkyData['quality'] ?? 0,
          capturedAt: DateTime.now(),
        ),
        deviceInfo: deviceInfo,
        capturedAt: DateTime.now(),
      );

      batch.set(biometricRef, biometricModel.toFirestore());

      // Create audit log
      final auditRef = _auditLogsCollection.doc();
      batch.set(auditRef, {
        'userId': currentUser.uid,
        'action': 'person_registered',
        'targetId': personRef.id,
        'targetType': 'person',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'description': 'Nouvelle personne enregistrée: $firstName $lastName',
          'personName': '$firstName $lastName',
          'biometricId': biometricRef.id,
        },
      });

      // Commit the batch
      await batch.commit();

      return personRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement: ${e.toString()}');
    }
  }

  // Get all persons registered by current user
  Stream<List<PersonModel>> getMyRegisteredPersons() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _personsCollection
        .where('registeredBy', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get person by ID
  Future<PersonModel?> getPersonById(String personId) async {
    try {
      final doc = await _personsCollection.doc(personId).get();
      if (doc.exists) {
        return PersonModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération: ${e.toString()}');
    }
  }

  // Update person information
  Future<void> updatePerson({
    required String personId,
    String? firstName,
    String? lastName,
    List<EmergencyContact>? emergencyContacts,
    String? photoUrl,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final updates = <String, dynamic>{
        'lastModified': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (emergencyContacts != null) {
        updates['emergencyContacts'] = emergencyContacts.map((e) => e.toMap()).toList();
      }
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _personsCollection.doc(personId).update(updates);

      // Add audit log
      await _auditLogsCollection.add({
        'userId': currentUser.uid,
        'action': 'data_modified',
        'targetId': personId,
        'targetType': 'person',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'description': 'Informations de la personne modifiées',
          'changedFields': updates.keys.toList(),
        },
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  // Search persons by name
  Future<List<PersonModel>> searchPersonsByName(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final queryLower = query.toLowerCase();
      
      // Search in firstName
      final firstNameQuery = await _personsCollection
          .where('registeredBy', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      // Filter results locally for better search
      final results = firstNameQuery.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .where((person) =>
              person.firstName.toLowerCase().contains(queryLower) ||
              person.lastName.toLowerCase().contains(queryLower) ||
              person.fullName.toLowerCase().contains(queryLower))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: ${e.toString()}');
    }
  }

  // Get statistics for dashboard
  Future<Map<String, dynamic>> getRegistrationStatistics() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'total': 0, 'today': 0, 'thisWeek': 0, 'thisMonth': 0};
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      final allPersons = await _personsCollection
          .where('registeredBy', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'active')
          .get();

      int total = 0;
      int today = 0;
      int thisWeek = 0;
      int thisMonth = 0;

      for (var doc in allPersons.docs) {
        final person = PersonModel.fromFirestore(doc);
        total++;

        if (person.registeredAt.isAfter(todayStart)) {
          today++;
        }
        if (person.registeredAt.isAfter(weekStart)) {
          thisWeek++;
        }
        if (person.registeredAt.isAfter(monthStart)) {
          thisMonth++;
        }
      }

      return {
        'total': total,
        'today': today,
        'thisWeek': thisWeek,
        'thisMonth': thisMonth,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: ${e.toString()}');
    }
  }

  // Delete person (soft delete - change status)
  Future<void> deletePerson(String personId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      await _personsCollection.doc(personId).update({
        'status': 'inactive',
        'lastModified': FieldValue.serverTimestamp(),
      });

      // Add audit log
      await _auditLogsCollection.add({
        'userId': currentUser.uid,
        'action': 'data_modified',
        'targetId': personId,
        'targetType': 'person',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'description': 'Personne supprimée (désactivée)',
        },
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression: ${e.toString()}');
    }
  }

  // Get device information
  Future<DeviceInfo> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String manufacturer = 'Unknown';
    String model = 'Unknown';
    String sensorType = 'Fingerprint';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        manufacturer = androidInfo.manufacturer;
        model = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        manufacturer = 'Apple';
        model = iosInfo.model;
      }
    } catch (e) {
      // Use default values if device info fails
    }

    return DeviceInfo(
      manufacturer: manufacturer,
      model: model,
      sensorType: sensorType,
    );
  }

  // Get biometric data for a person
  Future<BiometricModel?> getPersonBiometrics(String personId) async {
    try {
      final query = await _biometricsCollection
          .where('personId', isEqualTo: personId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return BiometricModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données biométriques: ${e.toString()}');
    }
  }
}
