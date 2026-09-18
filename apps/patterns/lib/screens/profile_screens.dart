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
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
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

  Future<void> _delete() async {
    final s = context.s;
    final profile = controller.activeProfile;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteProfileQuestion(profile.name)),
        content: Text(s.deleteProfileExplained),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await controller.deleteProfile(profile.id);
    await ActiveProfile.save(controller.activeProfileId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitalsTheme.of(context);
    final s = context.s;
    final profile = controller.activeProfile;
    final onlyOne = controller.profileList.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.profileHeading,
          style: theme.typography.label.copyWith(
            color: theme.colors.inkFaint,
            letterSpacing: 1.2,
          ),
        ),
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
        TextButton(
          onPressed: onlyOne ? null : _delete,
          child: Text(
            onlyOne ? s.lastProfile : s.deleteProfile,
            style: TextStyle(
              color: onlyOne ? theme.colors.inkFaint : theme.colors.danger,
            ),
          ),
        ),
      ],
    );
  }
}
