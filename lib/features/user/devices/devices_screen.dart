import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/strings_ar.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/models/device.dart';
import '../../../data/services/device_service.dart';
import '../../../widgets/gold_card.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  IconData _icon(DeviceType t) => switch (t) {
        DeviceType.light => Icons.lightbulb_outline,
        DeviceType.ac => Icons.ac_unit,
        DeviceType.tv => Icons.tv,
        DeviceType.other => Icons.devices_other,
      };

  double _min(Device d) => d.type == DeviceType.ac ? 16 : 0;

  double _max(Device d) => d.type == DeviceType.ac ? 30 : 100;

  String _levelLabel(Device d) => switch (d.type) {
        DeviceType.light => 'السطوع ${d.level}٪',
        DeviceType.ac => 'الحرارة ${d.level}°',
        DeviceType.tv => 'الصوت ${d.level}٪',
        DeviceType.other => 'المستوى ${d.level}٪',
      };

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.devices)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: service.devices.length,
        itemBuilder: (_, i) {
          final d = service.devices[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoldCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GoldIcon(_icon(d.type)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(d.room, style: const TextStyle(color: JavixColors.textTertiary, fontSize: 12)),
                  ])),
                  Switch(
                    value: d.isOn,
                    thumbColor: MaterialStateProperty.resolveWith(
                      (states) => states.contains(MaterialState.selected)
                          ? JavixColors.gold
                          : null,
                    ),
                    onChanged: (_) => service.toggle(d),
                  ),
                ]),
                if (d.isOn)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: JavixColors.gold,
                      thumbColor: JavixColors.gold,
                      inactiveTrackColor: JavixColors.border,
                    ),
                    child: Slider(
                      value: d.level.clamp(_min(d).round(), _max(d).round()).toDouble(),
                      min: _min(d),
                      max: _max(d),
                      divisions: d.type == DeviceType.ac ? 14 : 20,
                      label: _levelLabel(d),
                      onChanged: (v) =>
                          service.setLevel(d, v.round(), publish: false),
                      onChangeEnd: (v) => service.setLevel(d, v.round()),
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
