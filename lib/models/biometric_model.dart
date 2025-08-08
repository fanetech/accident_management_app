import 'package:cloud_firestore/cloud_firestore.dart';

class BiometricModel {
  final String biometricId;
  final String personId;
  final BiometricData? leftThumb;
  final BiometricData? rightPinky;
  final DeviceInfo deviceInfo;
  final DateTime capturedAt;

  BiometricModel({
    required this.biometricId,
    required this.personId,
    this.leftThumb,
    this.rightPinky,
    required this.deviceInfo,
    required this.capturedAt,
  });

  factory BiometricModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BiometricModel(
      biometricId: doc.id,
      personId: data['personId'] ?? '',
      leftThumb: data['leftThumb'] != null
          ? BiometricData.fromMap(data['leftThumb'])
          : null,
      rightPinky: data['rightPinky'] != null
          ? BiometricData.fromMap(data['rightPinky'])
          : null,
      deviceInfo: DeviceInfo.fromMap(data['deviceInfo'] ?? {}),
      capturedAt: (data['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'leftThumb': leftThumb?.toMap(),
      'rightPinky': rightPinky?.toMap(),
      'deviceInfo': deviceInfo.toMap(),
      'capturedAt': Timestamp.fromDate(capturedAt),
    };
  }
}

class BiometricData {
  final String template;
  final int quality;
  final DateTime capturedAt;

  BiometricData({
    required this.template,
    required this.quality,
    required this.capturedAt,
  });

  factory BiometricData.fromMap(Map<String, dynamic> map) {
    return BiometricData(
      template: map['template'] ?? '',
      quality: map['quality'] ?? 0,
      capturedAt: (map['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'template': template,
      'quality': quality,
      'capturedAt': Timestamp.fromDate(capturedAt),
    };
  }
}

class DeviceInfo {
  final String manufacturer;
  final String model;
  final String sensorType;

  DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.sensorType,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      manufacturer: map['manufacturer'] ?? 'Unknown',
      model: map['model'] ?? 'Unknown',
      sensorType: map['sensorType'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'sensorType': sensorType,
    };
  }
}
