import 'package:cloud_firestore/cloud_firestore.dart';

class ClientEmergencyContact {
  final String name;
  final String phoneNumber;
  final String relationship;
  final int priority; // 1 = primary, 2 = secondary, 3 = tertiary

  ClientEmergencyContact({
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priority,
  });

  factory ClientEmergencyContact.fromMap(Map<String, dynamic> map) {
    return ClientEmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      relationship: map['relationship'] ?? '',
      priority: map['priority'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'priority': priority,
    };
  }
}

class ClientProfile {
  final String uid; // User ID from Firebase Auth
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String? address;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final List<ClientEmergencyContact> emergencyContacts;
  final bool hasFingerprint;
  final String? fingerprintData; // Base64 encoded fingerprint template
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? medicalInfo; // Allergies, conditions, etc.

  ClientProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
    this.address,
    this.dateOfBirth,
    this.bloodType,
    required this.emergencyContacts,
    this.hasFingerprint = false,
    this.fingerprintData,
    required this.profileCompleted,
    required this.createdAt,
    this.lastUpdated,
    this.medicalInfo,
  });

  // Check if profile is complete
  bool get isProfileComplete {
    return emergencyContacts.isNotEmpty && 
           hasFingerprint && 
           phoneNumber != null && 
           phoneNumber!.isNotEmpty;
  }

  // Check what's missing in profile
  List<String> get missingFields {
    List<String> missing = [];
    if (emergencyContacts.isEmpty) missing.add('Contacts d\'urgence');
    if (!hasFingerprint) missing.add('Empreinte digitale');
    if (phoneNumber == null || phoneNumber!.isEmpty) missing.add('Numéro de téléphone');
    if (address == null || address!.isEmpty) missing.add('Adresse');
    if (dateOfBirth == null) missing.add('Date de naissance');
    if (bloodType == null || bloodType!.isEmpty) missing.add('Groupe sanguin');
    return missing;
  }

  factory ClientProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'] != null 
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      bloodType: data['bloodType'],
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => ClientEmergencyContact.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasFingerprint: data['hasFingerprint'] ?? false,
      fingerprintData: data['fingerprintData'],
      profileCompleted: data['profileCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      medicalInfo: data['medicalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'address': address,
      'dateOfBirth': dateOfBirth != null 
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'bloodType': bloodType,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      'hasFingerprint': hasFingerprint,
      'fingerprintData': fingerprintData,
      'profileCompleted': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null 
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
      'medicalInfo': medicalInfo,
    };
  }

  ClientProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? address,
    DateTime? dateOfBirth,
    String? bloodType,
    List<ClientEmergencyContact>? emergencyContacts,
    bool? hasFingerprint,
    String? fingerprintData,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? medicalInfo,
  }) {
    return ClientProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      hasFingerprint: hasFingerprint ?? this.hasFingerprint,
      fingerprintData: fingerprintData ?? this.fingerprintData,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      medicalInfo: medicalInfo ?? this.medicalInfo,
    );
  }
}
