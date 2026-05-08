import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_config.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: (baseUrl ?? ApiConfig.defaultBaseUrl).trim(),
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.instance.i(
            '[HTTP] → ${options.method} ${options.baseUrl}${options.path}\n'
            'headers=${options.headers}\n'
            'query=${options.queryParameters}\n'
            'body=${_safeBody(options.data)}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.instance.i(
            '[HTTP] ← ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.baseUrl}${response.requestOptions.path}\n'
            'data=${_safeBody(response.data)}',
          );
          handler.next(response);
        },
        onError: (e, handler) {
          AppLogger.instance.e(
            '[HTTP] ✕ ${e.response?.statusCode} ${e.requestOptions.method} '
            '${e.requestOptions.baseUrl}${e.requestOptions.path}\n'
            'dioType=${e.type}\n'
            'message=${e.message}\n'
            'data=${_safeBody(e.response?.data)}',
            error: e,
            stackTrace: e.stackTrace,
          );
          handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Response<dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? bearerToken,
  }) {
    return _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        headers: bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
  }) {
    return _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(
        headers: bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
      ),
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? bearerToken,
  }) {
    return _dio.put<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        headers:
            bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
      ),
    );
  }

  ApiFailure mapError(Object error) {
    if (error is DioException) {
      final msgFromServer = _extractMessage(error.response?.data);

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const NetworkFailure('Network error. Please check your internet and try again.');
      }

      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return UnauthorizedFailure(
          msgFromServer ?? 'Unauthorized. Please login again.',
        );
      }

      if (status != null && status >= 400 && status < 500) {
        final msg = msgFromServer ??
            'Request failed. Please check your input and try again.';
        return ValidationFailure(msg);
      }

      if (status != null && status >= 500) {
        return const ServerFailure('Server error. Please try again in a moment.');
      }

      return UnknownFailure(error.message ?? 'Unexpected error occurred.');
    }

    return UnknownFailure('Unexpected error occurred.');
  }

  static String _safeBody(Object? body) {
    try {
      if (body == null) return 'null';
      if (body is String) return body.length > 1500 ? '${body.substring(0, 1500)}…' : body;
      final encoded = jsonEncode(body);
      return encoded.length > 1500 ? '${encoded.substring(0, 1500)}…' : encoded;
    } catch (_) {
      return body.toString();
    }
  }

  static String? _extractMessage(Object? data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map) {
      final dynamic msg = data['message'] ?? data['Message'] ?? data['error'] ?? data['Error'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
    return null;
  }
}

