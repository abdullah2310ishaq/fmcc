import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/visits/visit_instruction_models.dart';

/// In-memory cache for visit assessment instructions (fetched once per session).
class VisitInstructionsCache extends ChangeNotifier {
  List<VisitInstruction> _instructions = const [];
  bool _loading = false;
  bool _loaded = false;
  bool _imagesPrefetched = false;
  String? _error;

  List<VisitInstruction> get instructions => _instructions;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get hasInstructions => _instructions.isNotEmpty;

  Future<void> ensureLoaded(SessionController session) async {
    if (_loaded || _loading) return;
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final api = PatientApi(session.apiClient);
      _instructions = await api.getVisitInstructions(bearerToken: token);
      _loaded = true;
      unawaited(prefetchImages());
    } on Object catch (e) {
      _error = session.apiClient.mapError(e).message;
      _instructions = const [];
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Downloads instruction images to disk so the carousel opens instantly.
  Future<void> prefetchImages() async {
    if (_imagesPrefetched || _instructions.isEmpty) return;

    await Future.wait(
      _instructions.map((inst) async {
        final url = inst.imageUrl;
        if (url == null || url.trim().isEmpty) return;
        try {
          await _warmImageCache(url);
        } on Object {
          // Ignore individual image failures.
        }
      }),
    );

    _imagesPrefetched = true;
  }

  Future<void> _warmImageCache(String url) async {
    final provider = CachedNetworkImageProvider(url);
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<void>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo _, bool __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object _, StackTrace? __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );
    stream.addListener(listener);
    await completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        stream.removeListener(listener);
      },
    );
  }

  void clear() {
    _instructions = const [];
    _loading = false;
    _loaded = false;
    _imagesPrefetched = false;
    _error = null;
    notifyListeners();
  }
}
