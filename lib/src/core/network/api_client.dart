import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_config.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/network/session_auth_hooks.dart';

class ApiClient {
  ApiClient({String? baseUrl, SessionAuthHooks? authHooks})
      : _authHooks = authHooks,
        _dio = Dio(
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

    if (authHooks != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (err, handler) async {
            final status = err.response?.statusCode;
            if (status != 401) {
              handler.next(err);
              return;
            }
            await _handleUnauthorized401(err, handler);
          },
        ),
      );
    }
  }

  static const kSkipAuthRetryExtra = 'skipAuthRetry';
  static const kAuthRetryDoneExtra = 'authRetryDone';
  static const kSessionEndedSilentlyExtra = 'sessionEndedSilently';

  final Dio _dio;
  final SessionAuthHooks? _authHooks;

  Future<void> _handleUnauthorized401(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final hooks = _authHooks!;
    final req = err.requestOptions;

    if (req.extra[kSkipAuthRetryExtra] == true) {
      handler.next(err);
      return;
    }

    final path = req.uri.path.toLowerCase();
    if (_isAuthBypassPath(path)) {
      handler.next(err);
      return;
    }

    final refresh = hooks.refreshToken?.trim();
    if (refresh == null || refresh.isEmpty) {
      await hooks.logoutDueToExpiredSession();
      _flagSessionEndedSilently(req);
      handler.reject(_sessionEndedDio(err));
      return;
    }

    if (req.extra[kAuthRetryDoneExtra] == true) {
      await hooks.logoutDueToExpiredSession();
      _flagSessionEndedSilently(req);
      handler.reject(_sessionEndedDio(err));
      return;
    }

    final refreshed = await hooks.tryRefreshTokensLocked();
    if (!refreshed) {
      await hooks.logoutDueToExpiredSession();
      _flagSessionEndedSilently(req);
      handler.reject(_sessionEndedDio(err));
      return;
    }

    final token = hooks.accessToken?.trim();
    if (token == null || token.isEmpty) {
      await hooks.logoutDueToExpiredSession();
      _flagSessionEndedSilently(req);
      handler.reject(_sessionEndedDio(err));
      return;
    }

    req.extra[kAuthRetryDoneExtra] = true;
    req.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.fetch(req);
      handler.resolve(response);
    } catch (e, st) {
      if (e is DioException) {
        AppLogger.instance.e(
          '[HTTP] Retry after refresh failed',
          error: e,
          stackTrace: st,
        );
        handler.next(e);
      } else {
        handler.next(
          DioException(requestOptions: req, error: e, stackTrace: st),
        );
      }
    }
  }

  static void _flagSessionEndedSilently(RequestOptions ro) {
    ro.extra[kSessionEndedSilentlyExtra] = true;
  }

  static DioException _sessionEndedDio(DioException source) {
    return DioException(
      requestOptions: source.requestOptions,
      response: source.response,
      type: DioExceptionType.cancel,
      error: source.error,
    );
  }

  static bool _isAuthBypassPath(String path) {
    return path.contains('/auth/google-login') ||
        path.contains('/auth/google-login-web') ||
        path.contains('/auth/refresh-token');
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? bearerToken,
    bool skipAuthRetry = false,
  }) {
    return _dio.post<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        headers:
            bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
        extra: skipAuthRetry ? {kSkipAuthRetryExtra: true} : null,
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    String? bearerToken,
    bool skipAuthRetry = false,
  }) {
    return _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(
        headers:
            bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
        extra: skipAuthRetry ? {kSkipAuthRetryExtra: true} : null,
      ),
    );
  }

  Future<Response<dynamic>> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    String? bearerToken,
    bool skipAuthRetry = false,
  }) {
    return _dio.put<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        headers:
            bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
        extra: skipAuthRetry ? {kSkipAuthRetryExtra: true} : null,
      ),
    );
  }

  ApiFailure mapError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.cancel &&
          error.requestOptions.extra[kSessionEndedSilentlyExtra] == true) {
        return const SessionEndedFailure();
      }

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
          _sanitizeClientAuthMessage(msgFromServer),
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

  static String _sanitizeClientAuthMessage(String? raw) {
    final m = (raw ?? '').trim().toLowerCase();
    if (m.contains('401') ||
        m.contains('403') ||
        m.contains('unauthorized') ||
        m.contains('forbidden')) {
      return 'Please sign in again.';
    }
    return raw?.trim().isNotEmpty == true ? raw!.trim() : 'Please sign in again.';
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
