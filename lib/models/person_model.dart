import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String contactId;
  final String phoneNumber;
  final int priority;
  final String relationship;
  final String name;

  EmergencyContact({
    required this.contactId,
    required this.phoneNumber,
    required this.priority,
    required this.relationship,
    required this.name,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      contactId: map['contactId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      priority: map['priority'] ?? 0,
      relationship: map['relationship'] ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'priority': priority,
      'relationship': relationship,
      'name': name,
    };
  }
}

class PersonModel {
  final String personId;
  final String firstName;
  final String lastName;
  final String registeredBy;
  final DateTime registeredAt;
  final DateTime? lastModified;
  final String status;
  final List<EmergencyContact> emergencyContacts;
  final String? photoUrl;

  PersonModel({
    required this.personId,
    required this.firstName,
    required this.lastName,
    required this.registeredBy,
    required this.registeredAt,
    this.lastModified,
    this.status = 'active',
    required this.emergencyContacts,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName';

  factory PersonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PersonModel(
      personId: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      registeredBy: data['registeredBy'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      lastModified: data['lastModified'] != null
          ? (data['lastModified'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'active',
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'registeredBy': registeredBy,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'lastModified':
          lastModified != null ? Timestamp.fromDate(lastModified!) : null,
      'status': status,
      'emergencyContacts':
          emergencyContacts.map((e) => e.toMap()).toList(),
      'photoUrl': photoUrl,
    };
  }

  PersonModel copyWith({
    String? personId,
    String? firstName,
    String? lastName,
    String? registeredBy,
    DateTime? registeredAt,
    DateTime? lastModified,
    String? status,
    List<EmergencyContact>? emergencyContacts,
    String? photoUrl,
  }) {
    return PersonModel(
      personId: personId ?? this.personId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      registeredBy: registeredBy ?? this.registeredBy,
      registeredAt: registeredAt ?? this.registeredAt,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
