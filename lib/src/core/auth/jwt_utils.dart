import 'dart:convert';

class JwtUtils {
  const JwtUtils._();

  static Map<String, dynamic> tryDecodePayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return const {};

    try {
      final normalized = base64Url.normalize(parts[1]);
      final bytes = base64Url.decode(normalized);
      final decoded = utf8.decode(bytes);
      final obj = jsonDecode(decoded);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
      return const {};
    } catch (_) {
      return const {};
    }
  }
}

