import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/language_service.dart';
import '../../core/theme/javix_theme.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final _textController = TextEditingController();
  String _source = 'auto';
  String _target = 'en';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب النص الذي تريد ترجمته أولاً.')),
      );
      return;
    }

    final uri = Uri.https(
      'translate.google.com',
      '/',
      {
        'sl': _source,
        'tl': _target,
        'text': text,
      },
    );

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح خدمة الترجمة.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الترجمة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ترجمة النصوص',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          const Text(
            'اختر اللغة المصدر واللغة الهدف، ثم افتح الترجمة. يدعم Google Translate عددًا كبيرًا من اللغات.',
            style: TextStyle(color: JavixColors.textSecondary, height: 1.5),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _textController,
            minLines: 5,
            maxLines: 10,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'النص',
              hintText: 'اكتب النص هنا...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _languageDropdown(
                  label: 'من',
                  value: _source,
                  includeAuto: true,
                  onChanged: (value) {
                    if (value != null) setState(() => _source = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _languageDropdown(
                  label: 'إلى',
                  value: _target,
                  includeAuto: false,
                  onChanged: (value) {
                    if (value != null) setState(() => _target = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _translate,
              icon: const Icon(Icons.translate),
              label: const Text('ترجمة'),
              style: FilledButton.styleFrom(
                backgroundColor: JavixColors.gold,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageDropdown({
    required String label,
    required String value,
    required bool includeAuto,
    required ValueChanged<String?> onChanged,
  }) {
    final items = <DropdownMenuItem<String>>[
      if (includeAuto)
        const DropdownMenuItem(
          value: 'auto',
          child: Text('اكتشاف تلقائي'),
        ),
      ...LanguageService.languages.map(
        (language) => DropdownMenuItem(
          value: language.code,
          child: Text(language.nativeName),
        ),
      ),
    ];

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
