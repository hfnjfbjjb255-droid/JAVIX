import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings_ar.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/models/search_result.dart';
import '../../../data/services/speech_service.dart';
import '../../../data/services/vision_service.dart';
import '../../../features/developer/logs/log_viewer_screen.dart';
import '../../../widgets/gold_card.dart';

/// Camera search screen: point at text (e.g. dollar price) or an object.
/// Each result can be read on screen (AR-style overlay) or aloud (TTS).
class CameraSearchScreen extends StatefulWidget {
  const CameraSearchScreen({super.key});

  @override
  State<CameraSearchScreen> createState() => _CameraSearchScreenState();
}

class _CameraSearchScreenState extends State<CameraSearchScreen> {
  // VisionService now comes from the provider (registered in app.dart)
  // instead of being constructed inline here.
  late final VisionService _vision;

  bool _busy = false;
  bool _readAloud = false;
  List<SearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _vision = context.read<VisionService>();
    if (!_vision.isReady) {
      _vision.init().catchError((e) => LogViewerScreen.log('camera init: $e'));
    }
  }

  @override
  void dispose() {
    // Do NOT close the recognizers here - the service is owned by the
    // provider and lives beyond this screen. Only release the camera,
    // and the await happens inside disposeCamera().
    _vision.disposeCamera();
    super.dispose();
  }

  Future<void> _analyze(Future<List<SearchResult>> Function() task) async {
    if (_busy) return;
    setState(() { _busy = true; _results = []; });
    try {
      final results = await task();
      if (!mounted) return;
      setState(() => _results = results);
      if (_readAloud && results.isNotEmpty && mounted) {
        await context.read<SpeechService>().speak(
              '${results.first.label}. ${results.first.detail}',
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التحليل: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.cameraSearch),
        actions: [
          Row(children: [
            const Icon(Icons.volume_up_outlined, size: 18, color: JavixColors.textSecondary),
            Switch(
              value: _readAloud,
              activeColor: JavixColors.gold,
              onChanged: (v) => setState(() => _readAloud = v),
            ),
          ]),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _vision,
            builder: (_, __) {
              if (!_vision.isReady) {
                return const Center(child: CircularProgressIndicator(color: JavixColors.gold));
              }
              return Stack(fit: StackFit.expand, children: [
                CameraPreview(_vision.controller!),
                // AR overlay: results drawn on top of the live camera feed.
                if (_results.isNotEmpty)
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: GoldCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _results
                            .map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    const Icon(Icons.auto_awesome, color: JavixColors.gold, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('${r.label}: ${r.detail}', style: const TextStyle(fontSize: 14))),
                                  ]),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                if (_busy)
                  const Center(child: CircularProgressIndicator(color: JavixColors.gold)),
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14)),
                onPressed: _busy ? null : () => _analyze(_vision.analyzeTextFrame),
                icon: const Icon(Icons.abc, color: Colors.black),
                label: const Text('قراءة نص', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: JavixColors.surfaceLight, padding: const EdgeInsets.all(14)),
                onPressed: _busy ? null : () => _analyze(_vision.analyzeObjectFrame),
                icon: const GoldIcon(Icons.category_outlined, size: 20),
                label: const Text('تعرف على كائن'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
