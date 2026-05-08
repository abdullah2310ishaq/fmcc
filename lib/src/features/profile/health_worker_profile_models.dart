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
    this.email,
    this.profileImageUrl,
    this.isVerified = false,
    this.joinedDate,
    this.healthWorkerId,
    this.educationLevelLabel = '',
    this.provinceLabel = '',
    this.districtLabel = '',
    this.tehsilLabel = '',
    this.approxPatientsPerDay,
    this.salary,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String gender;
  final int? age;
  final String cnic;
  final String phoneNumber;
  final int educationLevelId;
  final String lhwTrainingCertificate;
  final int provinceId;
  final int districtId;
  final int tehsilId;
  final String address;

  final String? email;
  final String? profileImageUrl;
  final bool isVerified;
  final String? joinedDate;
  final String? healthWorkerId;
  final String educationLevelLabel;
  final String provinceLabel;
  final String districtLabel;
  final String tehsilLabel;
  final int? approxPatientsPerDay;
  final double? salary;

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
      age: _asIntNullable(map['age'] ?? map['Age']),
      cnic: _asString(map['cnic'] ?? map['Cnic']) ?? '',
      phoneNumber: _asString(map['phoneNumber'] ?? map['PhoneNumber']) ?? '',
      educationLevelId: _asInt(map['educationLevelId'] ?? map['EducationLevelId']) ?? 0,
      lhwTrainingCertificate:
          _asString(map['lhwTrainingCertificate'] ?? map['LhwTrainingCertificate']) ?? '',
      provinceId: _asInt(map['provinceId'] ?? map['ProvinceId']) ?? 0,
      districtId: _asInt(map['districtId'] ?? map['DistrictId']) ?? 0,
      tehsilId: _asInt(map['tehsilId'] ?? map['TehsilId']) ?? 0,
      address: _asString(map['address'] ?? map['Address']) ?? '',
      email: _asString(map['email'] ?? map['Email']),
      profileImageUrl: _asString(map['profileImageUrl'] ?? map['ProfileImageUrl']),
      isVerified: _asBool(map['isVerified'] ?? map['IsVerified']),
      joinedDate: _asString(map['joinedDate'] ?? map['JoinedDate']),
      healthWorkerId: _asString(map['healthWorkerId'] ?? map['HealthWorkerId']),
      educationLevelLabel:
          _asString(map['educationLevel'] ?? map['EducationLevel']) ?? '',
      provinceLabel: _asString(map['provinceName'] ?? map['ProvinceName']) ?? '',
      districtLabel: _asString(map['districtName'] ?? map['DistrictName']) ?? '',
      tehsilLabel: _asString(map['tehsilName'] ?? map['TehsilName']) ?? '',
      approxPatientsPerDay: _asIntNullable(map['approxPatientsPerDay'] ?? map['ApproxPatientsPerDay']),
      salary: _asDoubleNullable(map['salary'] ?? map['Salary']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static String? _asString(dynamic v) => v is String ? v : v?.toString();

  static bool _asBool(dynamic v) {
    if (v == true || v == 1) return true;
    if (v == false || v == 0 || v == null) return false;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    return _asInt(v);
  }

  static double? _asDoubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }
}

