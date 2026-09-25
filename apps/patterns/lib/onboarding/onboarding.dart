import 'package:flutter/material.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_core/vitals_core.dart';

import '../data/app_database.dart';
import '../data/patterns_controller.dart';
import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../screens/day_detail_screen.dart';
import '../screens/metrics_screen.dart';
import '../screens/report_view_screen.dart';
import '../screens/reports_screen.dart';
import 'setup_screen.dart';
import 'suggested_markers.dart';
import 'welcome_screen.dart';

/// The stops of the tour, in order. Each one is a screen and a few lines.
enum TourStep { home, logging, day, reports, lines, cycle, grid, markers, done }

/// The first run: a welcome, a tour on a demo profile, and picking markers.
///
/// **Only on a fresh install.** An install that already holds markers - an
/// update, a restore - is marked done without ever seeing it, so nobody with
/// a year of entries is greeted as new.
///
/// The tour drives the real screens rather than pictures of them: each step
/// resets to home and pushes what it talks about, so Back and Next are the
/// same operation and wandering off mid-tour cannot leave it lost.
final class Onboarding extends ChangeNotifier {
  Onboarding({
    required this.controller,
    required this.language,
    required bool pending,
    String? demoProfileId,
  })
    // ignore: prefer_initializing_formals
    : _pending = pending,
       // ignore: prefer_initializing_formals
       _demoProfileId = demoProfileId;

  final PatternsController controller;
  final ValueNotifier<AppLanguage> language;

  /// The app's navigator, so the tour can move between screens from a
  /// banner that sits outside every one of them.
  final navigatorKey = GlobalKey<NavigatorState>();

  bool _pending;
  String? _demoProfileId;
  TourStep? _step;

  bool get isPending => _pending;

  /// The profile to go back to when a replayed tour ends. Set only while a
  /// tour started from Settings is running.
  String? _returnTo;

  /// A tour taken again from Settings: it ends back on her own profile, with
  /// the demo gone, instead of offering markers she already has.
  bool get isReplay => _returnTo != null;

  /// The onboarding above [context], or null where there is none.
  static Onboarding? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingScope>()?.notifier;

  /// Null when no tour is running.
  TourStep? get step => _step;

  bool get hasDemo =>
      _demoProfileId != null &&
      controller.profileList.any((p) => p.id == _demoProfileId);

  static const _stateKey = 'patterns.onboarding';
  static const _demoKey = 'patterns.onboarding.demo';

  /// Reads where the first run stands, deciding it on the very first launch.
  ///
  /// Written as pending straight away, so an app closed mid-tour comes back
  /// to the welcome rather than to a half-made profile with no way forward.
  static Future<Onboarding> load({
    required PatternsController controller,
    required ValueNotifier<AppLanguage> language,
    required Future<bool> Function() isFreshInstall,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var state = prefs.getString(_stateKey);
    if (state == null) {
      state = await isFreshInstall() ? 'pending' : 'done';
      await prefs.setString(_stateKey, state);
    }
    return Onboarding(
      controller: controller,
      language: language,
      pending: state == 'pending',
      demoProfileId: prefs.getString(_demoKey),
    );
  }

  NavigatorState get _nav => navigatorKey.currentState!;

  AppStrings get _s => AppStrings(language.value);

  /// Puts the welcome over home, once the navigator exists.
  void showWelcomeIfPending() {
    if (!_pending) return;
    _nav.push(
      MaterialPageRoute<void>(builder: (_) => WelcomeScreen(onboarding: this)),
    );
  }

  /// Makes the demo, or reopens the one an interrupted run left, and starts.
  Future<void> startTour() async {
    if (!hasDemo) {
      final s = _s;
      final demo = await controller.createDemoProfile(
        name: s.demoProfileName,
        reportNames: (
          moodAndTiredness: s.demoMoodAndTiredness,
          trainingAndMood: s.demoTrainingAndMood,
          byCycleDay: s.demoByCycleDay,
          weeklyRhythm: s.demoWeeklyRhythm,
        ),
      );
      _demoProfileId = demo.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_demoKey, demo.id);
    } else {
      await controller.switchProfile(_demoProfileId!);
    }
    await ActiveProfile.save(controller.activeProfileId);
    await _go(TourStep.home);
  }

  Future<void> next() async {
    final current = _step;
    if (current == null) return;
    if (current == TourStep.done) {
      return isReplay ? _endReplay() : openSetup();
    }
    await _go(TourStep.values[current.index + 1]);
  }

  Future<void> back() async {
    final current = _step;
    if (current == null || current.index == 0) return;
    await _go(TourStep.values[current.index - 1]);
  }

  /// Jumps to the end of the tour and on to picking markers.
  Future<void> skip() async {
    if (isReplay) return _endReplay();
    await _go(TourStep.done);
    await openSetup();
  }

  /// Takes the tour again on a fresh demo, from wherever she is.
  Future<void> replay() async {
    _returnTo = controller.activeProfileId;
    _demoProfileId = null;
    await startTour();
  }

  Future<void> _endReplay() async {
    final returnTo = _returnTo!;
    _nav.popUntil((route) => route.isFirst);
    _returnTo = null;
    _step = null;
    notifyListeners();
    await controller.switchProfile(returnTo);
    await ActiveProfile.save(controller.activeProfileId);
    if (hasDemo) await controller.deleteProfile(_demoProfileId!);
    _demoProfileId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_demoKey);
  }

  /// Whether the marker picker is open, which hides the tour card under it.
  bool get inSetup => _inSetup;
  bool _inSetup = false;

  Future<void> openSetup() async {
    _inSetup = true;
    notifyListeners();
    await _nav.push(
      MaterialPageRoute<void>(builder: (_) => SetupScreen(onboarding: this)),
    );
    _inSetup = false;
    notifyListeners();
  }

  Future<void> _go(TourStep step) async {
    _step = step;
    notifyListeners();
    final nav = _nav;
    nav.popUntil((route) => route.isFirst);
    void push(Widget screen) =>
        nav.push(MaterialPageRoute<void>(builder: (_) => screen));

    switch (step) {
      case TourStep.home || TourStep.logging || TourStep.done:
        break;
      case TourStep.day:
        push(
          DayDetailScreen(
            controller: controller,
            dayKey: addDays(controller.today, -1),
          ),
        );
      case TourStep.reports:
        push(ReportsScreen(controller: controller));
      case TourStep.markers:
        push(MetricsScreen(controller: controller));
      case TourStep.lines || TourStep.cycle || TourStep.grid:
        final s = _s;
        final name = switch (step) {
          TourStep.lines => s.demoMoodAndTiredness,
          TourStep.cycle => s.demoByCycleDay,
          _ => s.demoWeeklyRhythm,
        };
        final saved = await controller.savedReports();
        push(ReportsScreen(controller: controller));
        for (final definition in saved) {
          if (definition.name == name) {
            push(
              ReportViewScreen(controller: controller, definition: definition),
            );
            break;
          }
        }
    }
  }

  /// Writes her own markers and ends the first run.
  ///
  /// They go into the first profile, the one every install has, renamed into
  /// the chosen language. The demo goes unless [keepDemo].
  Future<void> finish({
    required Set<String> picked,
    required bool cycle,
    required bool keepDemo,
  }) async {
    final lang = language.value;
    final s = _s;
    final now = DateTime.now().toUtc();

    final own = controller.profileList.firstWhere(
      (p) => p.id == defaultProfileId,
      orElse: () =>
          controller.profileList.firstWhere((p) => p.id != _demoProfileId),
    );
    await controller.switchProfile(own.id);
    await controller.renameProfile(own.id, s.defaultProfileName);

    for (final suggestion in suggestedMarkers) {
      if (!picked.contains(suggestion.key)) continue;
      await controller.saveMetric(
        suggestion.build(
          language: lang,
          profileId: own.id,
          id: Ids.newId(),
          newId: Ids.newId,
          createdAt: now,
          sortOrder: controller.nextSortOrder(suggestion.domain),
        ),
      );
    }

    if (cycle) {
      await controller.setCycleEnabled(true);
      final profile = controller.activeProfile;
      for (final (id, words) in [
        (profile.periodStartMetricId, periodStartName),
        (profile.periodEndMetricId, periodEndName),
      ]) {
        final marker = id == null ? null : controller.byId(id);
        final name = periodName(words, lang);
        if (marker != null && marker.name != name) {
          await controller.saveMetric(marker.copyWith(name: name));
        }
      }
    }

    if (!keepDemo && hasDemo) {
      await controller.deleteProfile(_demoProfileId!);
    }
    await ActiveProfile.save(controller.activeProfileId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, 'done');
    await prefs.remove(_demoKey);
    _pending = false;
    _step = null;
    notifyListeners();
    _nav.popUntil((route) => route.isFirst);
  }
}

/// Makes the onboarding reachable from any screen, for Settings' replay.
class OnboardingScope extends InheritedNotifier<Onboarding> {
  const OnboardingScope({
    required Onboarding onboarding,
    required super.child,
    super.key,
  }) : super(notifier: onboarding);
}
