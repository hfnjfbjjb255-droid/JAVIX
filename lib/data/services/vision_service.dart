import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../features/developer/logs/log_viewer_screen.dart';
import '../models/search_result.dart';

/// Camera search for text and objects.
///
/// ML Kit's bundled text recognizer supports Latin, Chinese, Devanagari,
/// Japanese and Korean scripts; it does not provide Arabic script OCR.
class VisionService extends ChangeNotifier {
  CameraController? _controller;
  CameraController? get controller => _controller;

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  ObjectDetector? _objectDetector;
  List<CameraDescription> _cameras = [];
  bool _initializing = false;

  bool get isReady => _controller?.value.isInitialized ?? false;

  Future<void> init() async {
    if (_initializing || isReady) return;
    _initializing = true;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        LogViewerScreen.log('vision: no cameras available on this device');
        return;
      }

      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      try {
        await controller.initialize();
        _controller = controller;
      } catch (_) {
        await controller.dispose();
        rethrow;
      }

      _objectDetector ??= ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );
      notifyListeners();
    } catch (e) {
      LogViewerScreen.log('vision init failed: $e');
      await disposeCamera();
    } finally {
      _initializing = false;
    }
  }

  Future<List<SearchResult>> analyzeTextFrame() async {
    if (!isReady) return [];
    final image = await _controller!.takePicture();
    try {
      final recognized = await _textRecognizer.processImage(
        InputImage.fromFile(File(image.path)),
      );
      LogViewerScreen.log(
        'vision: OCR -> ${recognized.text.trim().length} chars',
      );
      if (recognized.text.trim().isEmpty) {
        return [
          const SearchResult(
            label: 'لا يوجد نص',
            detail: 'وجّه الكاميرا نحو نص لاتيني أو أرقام بوضوح',
          ),
        ];
      }
      return [
        SearchResult(label: 'النص المقروء', detail: recognized.text.trim()),
      ];
    } finally {
      try {
        await File(image.path).delete();
      } catch (_) {}
    }
  }

  Future<List<SearchResult>> analyzeObjectFrame() async {
    if (!isReady) return [];
    _objectDetector ??= ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );

    final image = await _controller!.takePicture();
    try {
      final objects = await _objectDetector!.processImage(
        InputImage.fromFile(File(image.path)),
      );
      LogViewerScreen.log('vision: objects -> ${objects.length}');
      if (objects.isEmpty) {
        return [
          const SearchResult(
            label: 'لم يتم التعرف',
            detail: 'لم أجد كائناً واضحاً في الصورة',
          ),
        ];
      }
      return objects
          .map((o) => SearchResult(
                label: o.labels.isNotEmpty ? o.labels.first.text : 'كائن',
                detail:
                    'ثقة ${((o.labels.isNotEmpty ? o.labels.first.confidence : 0) * 100).toStringAsFixed(0)}٪',
                confidence:
                    o.labels.isNotEmpty ? o.labels.first.confidence : null,
              ))
          .toList();
    } finally {
      try {
        await File(image.path).delete();
      } catch (_) {}
    }
  }

  Future<void> disposeCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) unawaited(controller.dispose());
    unawaited(_textRecognizer.close());
    final detector = _objectDetector;
    _objectDetector = null;
    if (detector != null) unawaited(detector.close());
    super.dispose();
  }
}
