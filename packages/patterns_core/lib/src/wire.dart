/// Turning a reading into something storable, and back.
///
/// Rule 6 of `00-foundation/DATA-PORTABILITY.md`: stable strings, never
/// ordinals, and a row that cannot be read costs one row rather than the whole
/// import. Decoding therefore returns null on anything unexpected instead of
/// throwing - an archive written by a later version will contain kinds this
/// build has never heard of, and that is a normal Tuesday, not a crash.
library;

import 'metric_kind.dart';
import 'metric_value.dart';


/// Rebuilds a value of [kind] from what [toWire] produced.
///
/// Returns null when the stored shape does not match the kind, which happens
/// with a corrupt row, a hand-edited export, or a marker retyped by a build
/// that should have refused to.
MetricValue? decodeValue(MetricKind kind, Object? wire) {
  switch (kind) {
    case MetricKind.scale:
    case MetricKind.percent:
    case MetricKind.count:
    case MetricKind.duration:
    case MetricKind.amount:
      if (wire is num) return NumberValue(wire, kind: kind);
      return null;
    case MetricKind.boolean:
      if (wire is bool) return BooleanValue(wire);
      return null;
    case MetricKind.choice:
      if (wire is String && wire.isNotEmpty) return ChoiceValue(wire);
      return null;
    case MetricKind.tags:
      if (wire is List) {
        // An empty list is kept: it is the explicit "none of these" answer, and
        // dropping it would turn a recorded fact back into a missing day.
        return TagsValue(wire.whereType<String>());
      }
      return null;
    case MetricKind.text:
      if (wire is String) return TextValue(wire);
      if (wire is Map && wire['text'] is String) {
        return TextValue(
          wire['text'] as String,
          isPrivate: wire['private'] == true,
        );
      }
      return null;
    case MetricKind.photo:
      if (wire is Map) {
        final photoId = wire['photoId'];
        if (photoId is! String || photoId.isEmpty) return null;
        final caption = wire['caption'];
        return PhotoValue(
          photoId: photoId,
          caption: caption is String ? caption : null,
        );
      }
      return null;
    case MetricKind.timeOfDay:
      if (wire is int && wire >= 0 && wire <= 1439) {
        return TimeOfDayValue(wire);
      }
      return null;
  }
}
