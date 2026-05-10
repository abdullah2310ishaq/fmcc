class HealthWorkerProfileUpsert {
  const HealthWorkerProfileUpsert({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
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
  /// Calendar date only (local); serialized as `yyyy-MM-dd` for API `DateOnly`.
  final DateTime dateOfBirth;
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
        'dateOfBirth': formatIsoDateOnly(dateOfBirth),
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
    this.dateOfBirth,
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
    this.legacyAgeYears,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String gender;
  /// From API `DateOfBirth` / `dateOfBirth`.
  final DateTime? dateOfBirth;
  /// When API still returns `age` only (no DOB).
  final int? legacyAgeYears;
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

  /// Completed calendar years from [dateOfBirth] to [reference] (default now).
  int? get ageYears =>
      ageCompletedYearsFromDateOfBirth(dateOfBirth, legacyAgeYears, DateTime.now());

  static HealthWorkerProfile? tryFromApi(dynamic data) {
    final map = _asMap(data);
    if (map == null) return null;

    final userId = _asString(map['userId'] ?? map['UserId']);
    if (userId == null || userId.trim().isEmpty) return null;

    final dob = tryParseApiDateOnly(
      map['dateOfBirth'] ??
          map['DateOfBirth'] ??
          map['date_of_birth'] ??
          map['dob'] ??
          map['Dob'],
    );
    final legacyAge = dob == null ? _asIntNullable(map['age'] ?? map['Age']) : null;

    return HealthWorkerProfile(
      userId: userId,
      firstName: _asString(map['firstName'] ?? map['FirstName']) ?? '',
      lastName: _asString(map['lastName'] ?? map['LastName']) ?? '',
      gender: _asString(map['gender'] ?? map['Gender']) ?? '',
      dateOfBirth: dob,
      legacyAgeYears: legacyAge,
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

/// ISO `yyyy-MM-dd` for ASP.NET `DateOnly` JSON.
String formatIsoDateOnly(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? tryParseApiDateOnly(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return DateTime(v.year, v.month, v.day);
  if (v is String) {
    final t = v.trim();
    if (t.isEmpty) return null;
    final normalized = t.contains('T') ? t.split('T').first : t;
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
    final parts = normalized.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final mo = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && mo != null && d != null && mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        try {
          return DateTime(y, mo, d);
        } catch (_) {
          return null;
        }
      }
    }
  }
  return null;
}

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

DateTime _birthdayInCalendarYear(DateTime birth, int year) {
  var day = birth.day;
  if (birth.month == 2 && birth.day == 29 && !_isLeapYear(year)) {
    day = 28;
  }
  return DateTime(year, birth.month, day);
}

/// Full years lived from [birthDate] to [reference] (local calendar dates).
int ageCompletedYears(DateTime birthDate, DateTime reference) {
  final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final today = DateTime(reference.year, reference.month, reference.day);
  if (today.isBefore(birth)) return -1;
  var age = today.year - birth.year;
  final birthdayThisYear = _birthdayInCalendarYear(birth, today.year);
  if (today.isBefore(birthdayThisYear)) {
    age--;
  }
  return age;
}

/// Prefer age from [dateOfBirth]; fall back to [legacyAgeYears].
int? ageCompletedYearsFromDateOfBirth(
  DateTime? dateOfBirth,
  int? legacyAgeYears,
  DateTime reference,
) {
  if (dateOfBirth != null) {
    final n = ageCompletedYears(dateOfBirth, reference);
    if (n < 0 || n > 130) return null;
    return n;
  }
  if (legacyAgeYears != null && legacyAgeYears > 0 && legacyAgeYears <= 130) {
    return legacyAgeYears;
  }
  return null;
}

String? validateProfileDateOfBirth(DateTime? dob, {DateTime? reference}) {
  if (dob == null) return 'Select date of birth';
  final ref = reference ?? DateTime.now();
  final age = ageCompletedYears(dob, ref);
  if (age < 0) return 'Date of birth cannot be in the future';
  if (age > 120) return 'Enter a valid date of birth';
  return null;
}

