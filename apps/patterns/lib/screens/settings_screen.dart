import 'package:flutter/material.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/app_lock.dart';
import '../data/archive_transfer.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/quick_log_widget.dart';
import 'backup_screen.dart';

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
    this.controller,
    this.transfer = const PlatformArchiveTransfer(),
    this.onChanged,
    this.lock,
    this.quickLog,
    this.onWidgetMarkersChanged,
    super.key,
  });

  /// Null hides the widget section.
  final QuickLogWidget? quickLog;

  final VoidCallback? onWidgetMarkersChanged;

  /// Null hides the lock section, as on a surface with no lock wired.
  final AppLock? lock;

  final EveningReminder reminder;
  final ReminderSettings settings;

  /// Null on a surface with no database behind it. The archive entry point is
  /// hidden rather than opening a screen whose buttons cannot work.
  final PatternsController? controller;

  final ArchiveTransfer transfer;

  /// Lets the app hold the current settings without this screen owning them.
  final ValueChanged<ReminderSettings>? onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ReminderSettings _settings = widget.settings;

  /// Asked once per visit, so a rebuild from the reminder switch does not
  /// query the database again.
  Future<int>? _photoBytes;

  /// The widget's markers, in order. Null until loaded.
  List<String>? _widgetIds;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    if (widget.quickLog != null && controller != null) {
      WidgetMarkers.load(controller.homeOrder).then((markers) {
        if (mounted) {
          setState(() => _widgetIds = [for (final m in markers) m.id]);
        }
      });
    }
  }

  Future<void> _toggleWidgetMarker(String id) async {
    final ids = [...?_widgetIds];
    if (ids.contains(id)) {
      ids.remove(id);
    } else if (ids.length < quickLogSlots) {
      ids.add(id);
    } else {
      return;
    }
    setState(() => _widgetIds = ids);
    await WidgetMarkers.save(ids);
    widget.onWidgetMarkersChanged?.call();
  }

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
            if (widget.lock case final lock?) ...[
              const SizedBox(height: VitalsSpacing.huge),
              Text(
                'ZAKLJUCAVANJE',
                style: theme.typography.label.copyWith(
                  color: theme.colors.inkFaint,
                  letterSpacing: 1.2,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: lock.enabled && lock.available,
                onChanged: lock.available
                    ? (on) async {
                        await lock.setEnabled(on);
                        if (mounted) setState(() {});
                      }
                    : null,
                title: Text('Otisak ili PIN telefona',
                    style: theme.typography.body),
                subtitle: Text(
                  lock.available
                      ? 'Pri otvaranju i nakon minute van aplikacije. '
                          'Za iskljucivanje treba otkljucati.'
                      : 'Telefon nema zakljucan ekran, pa aplikacija ne moze '
                          'biti zakljucana.',
                  style: theme.typography.caption
                      .copyWith(color: theme.colors.inkFaint),
                ),
              ),
            ],
            if ((widget.controller, _widgetIds)
                case (final controller?, final ids?)) ...[
              const SizedBox(height: VitalsSpacing.huge),
              Text(
                'WIDGET NA POCETNOM EKRANU',
                style: theme.typography.label.copyWith(
                  color: theme.colors.inkFaint,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: VitalsSpacing.sm),
              Text(
                'Do $quickLogSlots markera. Widget prikazuje samo imena, '
                'nikad vrijednosti ni da li je nesto upisano.',
                style: theme.typography.caption
                    .copyWith(color: theme.colors.inkMuted),
              ),
              for (final metric in controller.homeOrder)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: ids.contains(metric.id),
                  onChanged: ids.contains(metric.id) ||
                          ids.length < quickLogSlots
                      ? (_) => _toggleWidgetMarker(metric.id)
                      : null,
                  title: Text(metric.name, style: theme.typography.body),
                  secondary: ids.contains(metric.id)
                      ? Text('${ids.indexOf(metric.id) + 1}.',
                          style: theme.typography.caption)
                      : null,
                ),
            ],
            if (widget.controller case final controller?) ...[
              const SizedBox(height: VitalsSpacing.huge),
              Text(
                'DAN',
                style: theme.typography.label.copyWith(
                  color: theme.colors.inkFaint,
                  letterSpacing: 1.2,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Novi dan pocinje u', style: theme.typography.body),
                subtitle: Text(
                  'Unos u 01:30 pripada danu koji se upravo zavrsio. '
                  'Promjena vazi za nove unose; stari ostaju gdje su.',
                  style: theme.typography.caption
                      .copyWith(color: theme.colors.inkFaint),
                ),
                trailing: DropdownButton<int>(
                  value: controller.dayBoundaryHour,
                  items: [
                    for (var hour = 0; hour <= 6; hour++)
                      DropdownMenuItem(
                        value: hour,
                        child: Text('${hour.toString().padLeft(2, '0')}:00'),
                      ),
                  ],
                  onChanged: (hour) async {
                    if (hour == null) return;
                    await DayBoundary.save(hour);
                    await controller.setDayBoundaryHour(hour);
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(height: VitalsSpacing.huge),
              Text(
                'ARHIVA',
                style: theme.typography.label.copyWith(
                  color: theme.colors.inkFaint,
                  letterSpacing: 1.2,
                ),
              ),
              // A number to look at, never a limit. Nothing here deletes a
              // photo, suggests deleting one, or warns at a threshold: the
              // phone's own storage warning is the only one that is true.
              FutureBuilder<int>(
                future: _photoBytes ??= controller.photoBytes(),
                builder: (context, snapshot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fotografije zauzimaju',
                      style: theme.typography.body),
                  trailing: Text(
                    snapshot.hasData ? megabytes(snapshot.data!) : '…',
                    style: theme.typography.body
                        .copyWith(color: theme.colors.inkMuted),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Backup i vracanje',
                    style: theme.typography.body),
                subtitle: Text(
                  'Jedan fajl sa svime, fotografije unutra',
                  style: theme.typography.caption
                      .copyWith(color: theme.colors.inkFaint),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BackupScreen(
                      controller: controller,
                      transfer: widget.transfer,
                    ),
                  ),
                ),
              ),
            ],
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
