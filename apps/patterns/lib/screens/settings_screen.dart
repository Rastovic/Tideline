import 'package:flutter/material.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/evening_reminder.dart';

/// Settings, which for now is the one reminder.
///
/// **One reminder, end of day, at a time I set, and it can be off.** There is
/// no second reminder to add here, no morning ping and no "how often should we
/// check in" question, because everything else in the app is quick-log.
///
/// The permission is asked for **after** the switch is flipped and never on
/// launch: a tracker that opens by asking to notify you is a tracker whose
/// notifications get turned off at OS level in the first week, which costs the
/// one reminder that was actually wanted.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.reminder,
    required this.settings,
    this.onChanged,
    super.key,
  });

  final EveningReminder reminder;
  final ReminderSettings settings;

  /// Lets the app hold the current settings without this screen owning them.
  final ValueChanged<ReminderSettings>? onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ReminderSettings _settings = widget.settings;

  /// Set when the OS refused. Shown as a plain sentence rather than a repeated
  /// prompt, because asking twice does nothing on Android after a hard denial.
  bool _blockedByOs = false;

  Future<void> _write(ReminderSettings next) async {
    setState(() => _settings = next);
    await next.save();
    await widget.reminder.apply(next);
    widget.onChanged?.call(next);
  }

  Future<void> _toggle(bool on) async {
    if (!on) {
      setState(() => _blockedByOs = false);
      await _write(_settings.copyWith(enabled: false));
      return;
    }

    final notifier = widget.reminder.notifier;
    var state = await notifier.permission();
    if (state != NotificationPermission.granted) {
      state = await notifier.requestPermission();
    }
    if (state != NotificationPermission.granted) {
      // The switch stays off rather than on-but-silent. An app that says a
      // reminder is set when the OS will never deliver it is lying, and the
      // discovery comes weeks later.
      setState(() => _blockedByOs = true);
      return;
    }

    setState(() => _blockedByOs = false);
    await _write(_settings.copyWith(enabled: true));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.hour,
        minute: _settings.minuteOfHour,
      ),
    );
    if (picked == null) return;
    await _write(
      _settings.copyWith(minute: picked.hour * 60 + picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Podesavanja')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            Text(
              'PODSJETNIK',
              style: theme.typography.label.copyWith(
                color: theme.colors.inkFaint,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: VitalsSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _settings.enabled,
              onChanged: _toggle,
              title: Text('Jedan podsjetnik uvece', style: theme.typography.body),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _settings.enabled,
              onTap: _settings.enabled ? _pickTime : null,
              title: Text('Vrijeme', style: theme.typography.body),
              trailing: Text(
                _clock(_settings),
                style: theme.typography.title.copyWith(
                  color: _settings.enabled
                      ? theme.colors.ink
                      : theme.colors.inkFaint,
                ),
              ),
            ),
            const SizedBox(height: VitalsSpacing.md),
            Text(
              // Written down because it is a promise, not a description: the
              // reminder does not know whether the day was logged, and it is
              // never going to.
              'Kaze isto svake veceri i otvara listu markera. '
              'Ne zna da li si nesto upisala i ne spominje propusteni dan.',
              style: theme.typography.caption.copyWith(
                color: theme.colors.inkMuted,
              ),
            ),
            if (_blockedByOs) ...[
              const SizedBox(height: VitalsSpacing.lg),
              Container(
                padding: const EdgeInsets.all(VitalsSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colors.danger.withValues(alpha: 0.10),
                  borderRadius: VitalsRadius.nestedAll,
                ),
                child: Text(
                  'Obavjestenja su iskljucena u postavkama telefona, '
                  'pa podsjetnik ne moze stici. Sve ostalo radi normalno.',
                  style: theme.typography.caption,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _clock(ReminderSettings settings) =>
      '${settings.hour.toString().padLeft(2, '0')}:'
      '${settings.minuteOfHour.toString().padLeft(2, '0')}';
}
