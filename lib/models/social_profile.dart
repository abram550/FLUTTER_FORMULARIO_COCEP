class SocialProfile {
  final String? id;
  final String name;
  final String lastName;
  final int age;
  final String gender;
  final String phone;
  final String address;
  final String city;
  final String prayerRequest;
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
    required this.prayerRequest,
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
      'prayerRequest': prayerRequest,
      'socialNetwork': socialNetwork,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SocialProfile.fromMap(Map<String, dynamic> map, String id) {
    return SocialProfile(
      id: id,
      name: map['name'] ?? '',
      lastName: map['lastName'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      prayerRequest: map['prayerRequest'] ?? '',
      socialNetwork: map['socialNetwork'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}