/// Clinical / demographic reference row (`Id` + `Name` from API).
class NamedReferenceItem {
  const NamedReferenceItem({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory NamedReferenceItem.fromJson(Map<String, dynamic> json) {
    return NamedReferenceItem(
      id: _readInt(
        json['id'] ??
            json['Id'] ??
            json['relationDegreeId'] ??
            json['RelationDegreeId'] ??
            json['conditionId'] ??
            json['ConditionId'] ??
            json['procedureId'] ??
            json['ProcedureId'] ??
            json['medicineCategoryId'] ??
            json['MedicineCategoryId'] ??
            json['categoryId'] ??
            json['CategoryId'],
      ),
      name: _firstNonEmptyField(json, const [
        'name',
        'Name',
        'label',
        'Label',
        'title',
        'Title',
        'relationDegreeName',
        'RelationDegreeName',
        'degreeName',
        'DegreeName',
        'conditionName',
        'ConditionName',
        'procedureName',
        'ProcedureName',
        'categoryName',
        'CategoryName',
        'medicineCategoryName',
        'MedicineCategoryName',
      ]),
    );
  }
}

class EducationLevel {
  const EducationLevel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory EducationLevel.fromJson(Map<String, dynamic> json) {
    return EducationLevel(
      id: _readInt(
        json['id'] ??
            json['Id'] ??
            json['educationLevelId'] ??
            json['EducationLevelId'],
      ),
      name: _firstNonEmptyField(json, const [
        'name',
        'Name',
        'levelName',
        'LevelName',
        'title',
        'Title',
        'label',
        'Label',
      ]),
    );
  }
}

class Province {
  const Province({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: _readInt(
        json['id'] ?? json['Id'] ?? json['provinceId'] ?? json['ProvinceId'],
      ),
      name: _firstNonEmptyField(json, const [
        'name',
        'Name',
        'provinceName',
        'ProvinceName',
        'title',
        'Title',
        'label',
        'Label',
      ]),
    );
  }
}

class District {
  const District({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: _readInt(
        json['id'] ?? json['Id'] ?? json['districtId'] ?? json['DistrictId'],
      ),
      name: _firstNonEmptyField(json, const [
        'name',
        'Name',
        'districtName',
        'DistrictName',
        'title',
        'Title',
        'label',
        'Label',
      ]),
    );
  }
}

class Tehsil {
  const Tehsil({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory Tehsil.fromJson(Map<String, dynamic> json) {
    return Tehsil(
      id: _readInt(
        json['id'] ?? json['Id'] ?? json['tehsilId'] ?? json['TehsilId'],
      ),
      name: _firstNonEmptyField(json, const [
        'name',
        'Name',
        'tehsilName',
        'TehsilName',
        'title',
        'Title',
        'label',
        'Label',
      ]),
    );
  }
}

/// Backend uses typed keys (`levelName`, `provinceName`, …), not always `name`.
String _firstNonEmptyField(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

int _readInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}
