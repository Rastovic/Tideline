import 'package:flutter/material.dart';
import 'package:vitals_notify/vitals_notify.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/app_lock.dart';
import '../data/archive_transfer.dart';
import '../data/evening_reminder.dart';
import '../data/patterns_controller.dart';
import '../data/quick_log_widget.dart';
import '../app/tideline_themes.dart';
import 'backup_screen.dart';
import 'panel.dart';
import 'profile_screens.dart';
import 'theme_picker.dart';
import '../l10n/app_language.dart';

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

  Future<void> _write(ReminderSettings next, AppLanguage language) async {
    setState(() => _settings = next);
    await next.save();
    await widget.reminder.apply(next, language: language);
    widget.onChanged?.call(next);
  }

  Future<void> _toggle(bool on) async {
    final language = context.s.language;
    if (!on) {
      setState(() => _blockedByOs = false);
      await _write(_settings.copyWith(enabled: false), language);
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
    await _write(_settings.copyWith(enabled: true), language);
  }

  /// Redraws every screen at once, and re-words the reminder already
  /// scheduled so it does not arrive in the old language.
  Future<void> _setLanguage(AppLanguage language) async {
    final notifier = LanguageScope.notifierOf(context);
    if (notifier == null) return;
    notifier.value = language;
    await AppLanguage.save(language);
    await widget.reminder.apply(_settings, language: language);
  }

  Future<void> _pickTime() async {
    final language = context.s.language;
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
      language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.s.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            VitalsSpacing.screenH,
            VitalsSpacing.lg,
            VitalsSpacing.screenH,
            VitalsSpacing.huge,
          ),
          children: [
            // Ordered from the person outwards: whose record this is, how the
            // day works for them, then the phone around it (widget, lock),
            // then how the app looks, then the backup. Removing a profile is
            // last and apart.
            if (widget.controller case final controller?)
              Panel(
                label: context.s.profileHeading,
                child: ProfileSettingsSection(controller: controller),
              ),
            Panel(
              label: context.s.reminderHeading,
              child: _column(_reminder(theme)),
            ),
            if (widget.controller case final controller?)
              Panel(
                label: context.s.dayHeading,
                child: _column(_day(theme, controller)),
              ),
            if ((widget.controller, _widgetIds) case (
              final controller?,
              final ids?,
            ))
              Panel(
                label: context.s.widgetHeading,
                child: _column(_widget(theme, controller, ids)),
              ),
            if (widget.lock case final lock?)
              Panel(
                label: context.s.lockHeading,
                child: _column(_lock(theme, lock)),
              ),
            if (ThemeScope.of(context) case final choice?)
              Panel(
                label: context.s.themeHeading,
                child: ThemePicker(choice: choice),
              ),
            Panel(
              label: context.s.languageHeading,
              child: _column(_appearance(theme)),
            ),
            if (widget.controller case final controller?) ...[
              Panel(
                label: context.s.archiveHeading,
                child: _column(_archive(theme, controller)),
              ),
              // Last, and apart. See DeleteProfileSection.
              const SizedBox(height: VitalsSpacing.huge),
              DeleteProfileSection(controller: controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );

  List<Widget> _reminder(VitalsThemeData theme) => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _settings.enabled,
      onChanged: _toggle,
      title: Text(context.s.oneEveningReminder, style: theme.typography.body),
    ),
    // Right under the switch it explains, not at the bottom of the page.
    if (_blockedByOs)
      Container(
        margin: const EdgeInsets.only(bottom: VitalsSpacing.md),
        padding: const EdgeInsets.all(VitalsSpacing.md),
        decoration: BoxDecoration(
          color: theme.colors.danger.withValues(alpha: 0.10),
          borderRadius: VitalsRadius.nestedAll,
        ),
        child: Text(
          context.s.notificationsBlocked,
          style: theme.typography.caption,
        ),
      ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: _settings.enabled,
      onTap: _settings.enabled ? _pickTime : null,
      title: Text(context.s.time, style: theme.typography.body),
      trailing: Text(
        _clock(_settings),
        style: theme.typography.title.copyWith(
          color: _settings.enabled ? theme.colors.ink : theme.colors.inkFaint,
        ),
      ),
    ),
    const SizedBox(height: VitalsSpacing.sm),
    Text(
      // Written down because it is a promise, not a description: the
      // reminder does not know whether the day was logged, and it is
      // never going to.
      context.s.reminderPromise,
      style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
    ),
  ];

  List<Widget> _day(VitalsThemeData theme, PatternsController controller) => [
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.s.newDayStartsAt, style: theme.typography.body),
      subtitle: Text(
        context.s.dayBoundaryExplained,
        style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
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
  ];

  List<Widget> _widget(
    VitalsThemeData theme,
    PatternsController controller,
    List<String> ids,
  ) => [
    Text(
      context.s.widgetExplained(quickLogSlots),
      style: theme.typography.caption.copyWith(color: theme.colors.inkMuted),
    ),
    for (final metric in controller.homeOrder)
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: ids.contains(metric.id),
        onChanged: ids.contains(metric.id) || ids.length < quickLogSlots
            ? (_) => _toggleWidgetMarker(metric.id)
            : null,
        title: Text(metric.name, style: theme.typography.body),
        secondary: ids.contains(metric.id)
            ? Text(
                '${ids.indexOf(metric.id) + 1}.',
                style: theme.typography.caption,
              )
            : null,
      ),
  ];

  List<Widget> _lock(VitalsThemeData theme, AppLock lock) => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: lock.enabled && lock.available,
      onChanged: lock.available
          ? (on) async {
              await lock.setEnabled(on, reason: context.s.unlockReason);
              if (mounted) setState(() {});
            }
          : null,
      title: Text(context.s.lockTitle, style: theme.typography.body),
      subtitle: Text(
        lock.available ? context.s.lockExplained : context.s.lockUnavailable,
        style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
      ),
    ),
  ];

  /// How the app looks and speaks. The chips carry each language's own name,
  /// so the choice is still findable by someone who cannot read the heading.
  /// The chips carry each language's own name, so the choice is still
  /// findable by someone who cannot read the heading.
  List<Widget> _appearance(VitalsThemeData theme) => [
    Wrap(
      spacing: VitalsSpacing.sm,
      children: [
        for (final language in AppLanguage.values)
          ChoiceChip(
            label: Text(language.nativeName),
            selected: context.s.language == language,
            onSelected: (_) => _setLanguage(language),
          ),
      ],
    ),
  ];

  List<Widget> _archive(
    VitalsThemeData theme,
    PatternsController controller,
  ) => [
    // A number to look at, never a limit. Nothing here deletes a photo,
    // suggests deleting one, or warns at a threshold: the phone's own
    // storage warning is the only one that is true.
    FutureBuilder<int>(
      future: _photoBytes ??= controller.photoBytes(),
      builder: (context, snapshot) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.s.photosTakeUp, style: theme.typography.body),
        trailing: Text(
          snapshot.hasData ? megabytes(snapshot.data!) : '…',
          style: theme.typography.body.copyWith(color: theme.colors.inkMuted),
        ),
      ),
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.s.backupAndRestore, style: theme.typography.body),
      subtitle: Text(
        context.s.oneFileWithEverything,
        style: theme.typography.caption.copyWith(color: theme.colors.inkFaint),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BackupScreen(controller: controller, transfer: widget.transfer),
        ),
      ),
    ),
  ];

  static String _clock(ReminderSettings settings) =>
      '${settings.hour.toString().padLeft(2, '0')}:'
      '${settings.minuteOfHour.toString().padLeft(2, '0')}';
}
