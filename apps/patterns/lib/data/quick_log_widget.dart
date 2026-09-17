import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:patterns_core/patterns_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How many markers the home screen widget holds.
const quickLogSlots = 4;

/// The home screen widget, as the app sees it.
///
/// A seam over `home_widget` so a test can check what would be published and
/// fake a tap, without a launcher.
abstract interface class QuickLogWidget {
  /// Shows these markers' names on the widget. Names and ids only.
  Future<void> publish(List<Metric> markers);

  /// The marker the app was opened for from a cold start, if any.
  Future<String?> launchedFor();

  /// Markers tapped while the app was already running.
  Stream<String> get taps;
}

/// `tideline://log/<marker id>`, the link each widget slot opens.
String? markerIdFromLink(Uri? uri) {
  if (uri == null || uri.scheme != 'tideline' || uri.host != 'log') return null;
  final segments = uri.pathSegments;
  return segments.length == 1 && segments.single.isNotEmpty
      ? segments.single
      : null;
}

final class PlatformQuickLogWidget implements QuickLogWidget {
  const PlatformQuickLogWidget();

  static const _provider = 'com.rastovic.tideline.TidelineWidgetProvider';

  @override
  Future<void> publish(List<Metric> markers) async {
    try {
      for (var i = 0; i < quickLogSlots; i++) {
        final metric = i < markers.length ? markers[i] : null;
        await HomeWidget.saveWidgetData<String>('marker_${i}_id', metric?.id);
        await HomeWidget.saveWidgetData<String>(
            'marker_${i}_name', metric?.name);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } on Object {
      // No launcher, or no widget placed. The app works the same without it.
    }
  }

  @override
  Future<String?> launchedFor() async {
    try {
      return markerIdFromLink(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } on Object {
      return null;
    }
  }

  @override
  Stream<String> get taps => HomeWidget.widgetClicked
      .map(markerIdFromLink)
      .where((id) => id != null)
      .cast<String>()
      .handleError((Object _) {});
}

/// Which markers the widget holds, in order.
final class WidgetMarkers {
  const WidgetMarkers._();

  static const _key = 'patterns.widget.markers';

  /// The saved choice, dropping markers that have since been archived or
  /// deleted. With nothing saved, the first four on the home list.
  static Future<List<Metric>> load(List<Metric> active) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null) {
      return active.take(quickLogSlots).toList();
    }
    final byId = {for (final m in active) m.id: m};
    return [
      for (final id in saved)
        if (byId[id] case final metric?) metric,
    ].take(quickLogSlots).toList();
  }

  static Future<void> save(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.take(quickLogSlots).toList());
  }
}
