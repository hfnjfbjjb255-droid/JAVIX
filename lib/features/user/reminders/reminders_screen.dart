import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/localization/strings_ar.dart';
import '../../../core/theme/javix_theme.dart';
import '../../../data/models/reminder.dart';
import '../../../data/services/reminder_service.dart';
import '../../../widgets/gold_card.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  Future<void> _addReminder(BuildContext context) async {
    final title = TextEditingController();
    DateTime due = DateTime.now().add(const Duration(hours: 1));
    int lead = AppConstants.defaultReminderLead.inMinutes;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(S.addReminder, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'عنوان التذكير')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(context: ctx, initialDate: due, firstDate: DateTime.now(), lastDate: DateTime(2035));
                    if (d != null) {
                      final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(due));
                      if (t != null) setSheet(() => due = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  },
                  icon: const GoldIcon(Icons.schedule, size: 18),
                  label: Text(DateFormat('yyyy/MM/dd HH:mm').format(due)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text(S.reminderLeadLabel, style: TextStyle(color: JavixColors.textSecondary)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: lead,
                dropdownColor: JavixColors.surfaceLight,
                items: const [5, 10, 15, 30, 60]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m دقيقة')))
                    .toList(),
                onChanged: (v) => setSheet(() => lead = v ?? 30),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: JavixColors.gold, padding: const EdgeInsets.all(14)),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حفظ', style: TextStyle(color: Colors.black)),
              ),
            ),
          ]),
        ),
      ),
    );

    if (saved == true && title.text.trim().isNotEmpty && context.mounted) {
      try {
        await context.read<ReminderService>().add(Reminder(
              title: title.text.trim(),
              dueAt: due,
              leadTime: Duration(minutes: lead),
            ));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حفظ التذكير: $e')),
          );
        }
      }
    }
    title.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ReminderService>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.reminders)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: JavixColors.gold,
        onPressed: () => _addReminder(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: service.reminders.isEmpty
          ? const Center(child: Text('لا تذكيرات بعد', style: TextStyle(color: JavixColors.textTertiary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: service.reminders.length,
              itemBuilder: (_, i) {
                final r = service.reminders[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GoldCard(
                    child: Row(children: [
                      const GoldIcon(Icons.notifications_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('الموعد: ${DateFormat('yyyy/MM/dd HH:mm').format(r.dueAt)}',
                              style: const TextStyle(color: JavixColors.textSecondary, fontSize: 12)),
                          Text('تنبيه قبل ${r.leadTime.inMinutes} دقيقة',
                              style: const TextStyle(color: JavixColors.gold, fontSize: 12)),
                        ]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: JavixColors.textTertiary),
                        onPressed: () => service.remove(r.id!),
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
