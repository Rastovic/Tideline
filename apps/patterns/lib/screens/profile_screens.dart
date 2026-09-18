import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:vitals_ui/vitals_ui.dart';

import '../data/app_database.dart';
import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';

/// Switches profile. Shared by the home header and anywhere else that needs it.
Future<void> switchProfileTo(
  PatternsController controller,
  String profileId,
) async {
  await controller.switchProfile(profileId);
  await ActiveProfile.save(profileId);
}

/// The profile picker: every profile, the active one ticked, and a way to
/// make another.
Future<void> showProfilePicker(
  BuildContext context,
  PatternsController controller,
) async {
  final s = context.s;
  final choice = await showModalBottomSheet<String>(
    context: context,
    // Scrolls, because profiles accumulate and a phone is short: a fixed
    // column of them overflowed the sheet with only two profiles and the
    // demo entry.
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final profile in controller.profileList)
            ListTile(
              leading: Icon(
                profile.id == controller.activeProfileId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(profile.name),
              onTap: () => Navigator.of(context).pop(profile.id),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_add_alt),
            title: Text(s.newProfile),
            onTap: () => Navigator.of(context).pop('new'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(s.demoProfile),
            subtitle: Text(s.demoProfileHint),
            onTap: () => Navigator.of(context).pop('demo'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  if (choice == 'demo') {
    await makeDemoProfile(context, controller);
    return;
  }
  if (choice == 'new') {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NewProfileScreen(controller: controller),
      ),
    );
    return;
  }
  await switchProfileTo(controller, choice);
}

/// Builds the demo profile behind a small progress dialog, then opens on it.
Future<void> makeDemoProfile(
  BuildContext context,
  PatternsController controller,
) async {
  final s = context.s;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: VitalsSpacing.lg),
          Expanded(child: Text(s.makingDemo)),
        ],
      ),
    ),
  );
  try {
    final profile = await controller.createDemoProfile(
      name: s.demoProfileName,
      reportNames: (
        moodAndTiredness: s.demoMoodAndTiredness,
        creatineAndBloating: s.demoCreatineAndBloating,
        byCycleDay: s.demoByCycleDay,
        weeklyRhythm: s.demoWeeklyRhythm,
      ),
    );
    await ActiveProfile.save(profile.id);
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Making a profile: a name, and what it starts with.
///
/// **Markers only, ever.** Copying from another profile brings its list of
/// things to track and none of what was recorded, because a child's profile
/// that opened with a parent's history would be a privacy bug on day one.
class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({required this.controller, super.key});

  final PatternsController controller;

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  final _name = TextEditingController();
  ProfileStart _start = ProfileStart.starter;
  late String _copyFrom = widget.controller.activeProfileId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final profile = await widget.controller.createProfile(
      name: _name.text,
      start: _start,
      copyFrom: _copyFrom,
    );
    await ActiveProfile.save(profile.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final others = widget.controller.profileList;

    Widget option(ProfileStart value, String title, String hint) =>
        RadioListTile<ProfileStart>(
          contentPadding: EdgeInsets.zero,
          value: value,
          title: Text(title, style: theme.typography.body),
          subtitle: Text(
            hint,
            style: theme.typography.caption
                .copyWith(color: theme.colors.inkMuted),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.newProfile),
        actions: [
          TextButton(
            onPressed: _name.text.trim().isEmpty || _saving ? null : _create,
            child: Text(s.create),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(VitalsSpacing.screenH),
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: theme.typography.title,
              decoration: InputDecoration(labelText: s.name),
            ),
            const SizedBox(height: VitalsSpacing.xl),
            Text(
              s.startWith.toUpperCase(),
              style: theme.typography.label.copyWith(
                color: theme.colors.inkFaint,
                letterSpacing: 1.2,
              ),
            ),
            RadioGroup<ProfileStart>(
              groupValue: _start,
              onChanged: (v) => setState(() => _start = v!),
              child: Column(
                children: [
                  option(
                    ProfileStart.starter,
                    s.startStarter,
                    s.startStarterHint,
                  ),
                  option(ProfileStart.empty, s.startEmpty, s.startEmptyHint),
                  option(ProfileStart.copy, s.startCopy, s.startCopyHint),
                ],
              ),
            ),
            if (_start == ProfileStart.copy)
              Padding(
                padding: const EdgeInsets.only(left: VitalsSpacing.xxl),
                child: DropdownButton<String>(
                  value: _copyFrom,
                  isExpanded: true,
                  items: [
                    for (final profile in others)
                      DropdownMenuItem(
                        value: profile.id,
                        child: Text(profile.name),
                      ),
                  ],
                  onChanged: (id) => setState(() => _copyFrom = id!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The active profile's own settings: its name, its cycle, and removing it.
class ProfileSettingsSection extends StatefulWidget {
  const ProfileSettingsSection({required this.controller, super.key});

  final PatternsController controller;

  @override
  State<ProfileSettingsSection> createState() => _ProfileSettingsSectionState();
}

class _ProfileSettingsSectionState extends State<ProfileSettingsSection> {
  PatternsController get controller => widget.controller;

  Future<void> _rename() async {
    final s = context.s;
    final field = TextEditingController(text: controller.activeProfile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.rename),
        content: TextField(controller: field, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(field.text),
            child: Text(s.save),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null) return;
    await controller.renameProfile(controller.activeProfileId, name);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final profile = controller.activeProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(profile.name, style: theme.typography.body),
          trailing: TextButton(onPressed: _rename, child: Text(s.rename)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: profile.cycleEnabled,
          onChanged: (on) async {
            await controller.setCycleEnabled(on);
            if (mounted) setState(() {});
          },
          title: Text(s.trackCycle, style: theme.typography.body),
          subtitle: Text(
            s.trackCycleHint,
            style: theme.typography.caption
                .copyWith(color: theme.colors.inkFaint),
          ),
        ),
      ],
    );
  }
}

/// Removing the active profile, kept apart at the bottom of Settings.
///
/// **Far from everything else on purpose.** It sat under the cycle switch,
/// one slip away from a tap meant for it, and it removes a person's whole
/// record. It also asks for the profile's name to be typed, because a
/// confirmation that is one more tap in the same place is a confirmation the
/// thumb gives on its own.
class DeleteProfileSection extends StatelessWidget {
  const DeleteProfileSection({required this.controller, super.key});

  final PatternsController controller;

  Future<void> _delete(BuildContext context) async {
    final s = context.s;
    final profile = controller.activeProfile;
    final typed = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.deleteProfileQuestion(profile.name)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.deleteProfileExplained),
              const SizedBox(height: VitalsSpacing.lg),
              Text(s.typeNameToConfirm(profile.name)),
              TextField(
                controller: typed,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: typed.text.trim() == profile.name
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Text(s.delete),
            ),
          ],
        ),
      ),
    );
    typed.dispose();
    if (ok != true) return;
    await controller.deleteProfile(profile.id);
    await ActiveProfile.save(controller.activeProfileId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final onlyOne = controller.profileList.length <= 1;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onlyOne ? null : () => _delete(context),
        icon: Icon(
          Icons.delete_outline,
          color: onlyOne ? theme.colors.inkFaint : theme.colors.danger,
        ),
        label: Text(
          onlyOne
              ? s.lastProfile
              : s.deleteNamedProfile(controller.activeProfile.name),
          style: TextStyle(
            color: onlyOne ? theme.colors.inkFaint : theme.colors.danger,
          ),
        ),
      ),
    );
  }
}
