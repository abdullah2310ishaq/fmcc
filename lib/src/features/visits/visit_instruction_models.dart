import 'package:doctor_app/src/core/network/api_config.dart';

/// `GET /api/Patient/instructions` — [VisitInstructionsModel] on the API.
class VisitInstruction {
  const VisitInstruction({
    required this.id,
    required this.instruction,
    required this.instructionImage,
  });

  final int id;
  final String instruction;
  final String instructionImage;

  String get title {
    final lines = instruction
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 1) return lines.first;
    return 'Before you begin';
  }

  String get description {
    final lines = instruction
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > 1) return lines.sublist(1).join('\n');
    return instruction.trim();
  }

  String? get imageUrl {
    final raw = instructionImage.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = ApiConfig.defaultBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$base$path';
  }

  static VisitInstruction? tryFromJson(dynamic json) {
    if (json is! Map) return null;
    final m = Map<String, dynamic>.from(json);
    final id = _readInt(m, 'id', 'Id');
    if (id == null) return null;
    return VisitInstruction(
      id: id,
      instruction: _readString(m, 'instruction', 'Instruction') ?? '',
      instructionImage:
          _readString(m, 'instructionImage', 'InstructionImage') ?? '',
    );
  }
}

int? _readInt(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String? _readString(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  if (v is String) return v;
  if (v == null) return null;
  return v.toString();
}

List<VisitInstruction> parseVisitInstructionsList(dynamic root) {
  final raw = _unwrapList(root);
  final out = <VisitInstruction>[];
  for (final item in raw) {
    final row = VisitInstruction.tryFromJson(item);
    if (row != null) out.add(row);
  }
  out.sort((a, b) => a.id.compareTo(b.id));
  return out;
}

List<dynamic> _unwrapList(dynamic root) {
  if (root is List) return root;
  if (root is Map) {
    final m = Map<String, dynamic>.from(root);
    final inner = m['data'] ?? m['Data'];
    if (inner is List) return inner;
  }
  return const [];
}
