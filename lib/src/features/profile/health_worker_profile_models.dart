class HealthWorkerProfileUpsert {
  const HealthWorkerProfileUpsert({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.cnic,
    required this.phoneNumber,
    required this.educationLevelId,
    required this.lhwTrainingCertificate,
    required this.provinceId,
    required this.districtId,
    required this.tehsilId,
    required this.address,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String gender; // "M" / "F"
  final int age;
  final String cnic;
  final String phoneNumber;
  final int educationLevelId;
  final String lhwTrainingCertificate;
  final int provinceId;
  final int districtId;
  final int tehsilId;
  final String address;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'age': age,
        'cnic': cnic,
        'phoneNumber': phoneNumber,
        'educationLevelId': educationLevelId,
        'lhwTrainingCertificate': lhwTrainingCertificate,
        'provinceId': provinceId,
        'districtId': districtId,
        'tehsilId': tehsilId,
        'address': address,
      };
}

class HealthWorkerProfile {
  const HealthWorkerProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.cnic,
    required this.phoneNumber,
    required this.educationLevelId,
    required this.lhwTrainingCertificate,
    required this.provinceId,
    required this.districtId,
    required this.tehsilId,
    required this.address,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String gender;
  final int age;
  final String cnic;
  final String phoneNumber;
  final int educationLevelId;
  final String lhwTrainingCertificate;
  final int provinceId;
  final int districtId;
  final int tehsilId;
  final String address;

  static HealthWorkerProfile? tryFromApi(dynamic data) {
    final map = _asMap(data);
    if (map == null) return null;

    final userId = _asString(map['userId'] ?? map['UserId']);
    if (userId == null || userId.trim().isEmpty) return null;

    return HealthWorkerProfile(
      userId: userId,
      firstName: _asString(map['firstName'] ?? map['FirstName']) ?? '',
      lastName: _asString(map['lastName'] ?? map['LastName']) ?? '',
      gender: _asString(map['gender'] ?? map['Gender']) ?? '',
      age: _asInt(map['age'] ?? map['Age']) ?? 0,
      cnic: _asString(map['cnic'] ?? map['Cnic']) ?? '',
      phoneNumber: _asString(map['phoneNumber'] ?? map['PhoneNumber']) ?? '',
      educationLevelId: _asInt(map['educationLevelId'] ?? map['EducationLevelId']) ?? 0,
      lhwTrainingCertificate:
          _asString(map['lhwTrainingCertificate'] ?? map['LhwTrainingCertificate']) ?? '',
      provinceId: _asInt(map['provinceId'] ?? map['ProvinceId']) ?? 0,
      districtId: _asInt(map['districtId'] ?? map['DistrictId']) ?? 0,
      tehsilId: _asInt(map['tehsilId'] ?? map['TehsilId']) ?? 0,
      address: _asString(map['address'] ?? map['Address']) ?? '',
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String? _asString(dynamic v) => v is String ? v : v?.toString();

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

