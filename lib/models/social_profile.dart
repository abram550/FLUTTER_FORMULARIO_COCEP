import 'package:cloud_firestore/cloud_firestore.dart';

class SocialProfile {
  final String? id;
  final String name;
  final String lastName;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String city;
  final String? prayerRequest;
  final String socialNetwork;
  final DateTime createdAt;

  SocialProfile({
    this.id,
    required this.name,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.city,
    this.prayerRequest,
    required this.socialNetwork,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'phone': phone,
      'address': address,
      'city': city,
      'prayerRequest': prayerRequest ?? '',
      'socialNetwork': socialNetwork,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ✅ CORRECCIÓN: Manejo robusto de datos desde Firestore
  factory SocialProfile.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;

    try {
      // Intentar parsear desde String ISO8601
      if (map['createdAt'] is String) {
        parsedDate = DateTime.parse(map['createdAt']);
      }
      // Si es un Timestamp de Firestore
      else if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      }
      // Fallback a fecha actual
      else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parseando fecha en SocialProfile: $e');
      parsedDate = DateTime.now();
    }

    return SocialProfile(
      id: id,
      name: map['name']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      age: _parseToInt(map['age']),
      gender: map['gender']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      prayerRequest: map['prayerRequest']?.toString(),
      socialNetwork: map['socialNetwork']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }

  // Método auxiliar para parseo seguro de enteros
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
