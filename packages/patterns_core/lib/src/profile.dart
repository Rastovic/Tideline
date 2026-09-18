import 'metric.dart';

/// The profile every install starts with, and the one all data written
/// before profiles existed belongs to.
///
/// A fixed id rather than a generated one, so a backup made before profiles
/// existed restores into the same profile on any phone.
const String defaultProfileId = '0198aa02-0000-7000-8000-000000000001';

/// Whose record this is: one person's markers, readings, photos and reports.
///
/// **Nothing crosses between profiles.** A child's markers are not a filter
/// over a parent's, they are separate rows, so deleting one profile cannot
/// touch another's history.
final class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.cycleEnabled = false,
    this.periodStartMetricId,
    this.periodEndMetricId,
    this.sortOrder = 0,
    this.deletedAt,
  });

  final String id;
  final String name;

  /// Off by default. The module is invisible when off - no card, no axis, no
  /// line on the doctor page - and turning it off hides rather than deletes.
  final bool cycleEnabled;

  /// The two markers this profile records a period with. Held by id rather
  /// than found by name, so renaming either one changes nothing.
  final String? periodStartMetricId;
  final String? periodEndMetricId;

  final int sortOrder;
  final DateTime createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get hasCycleMarkers =>
      periodStartMetricId != null && periodEndMetricId != null;

  Profile copyWith({
    String? name,
    bool? cycleEnabled,
    String? periodStartMetricId,
    String? periodEndMetricId,
    int? sortOrder,
    DateTime? deletedAt,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        cycleEnabled: cycleEnabled ?? this.cycleEnabled,
        periodStartMetricId: periodStartMetricId ?? this.periodStartMetricId,
        periodEndMetricId: periodEndMetricId ?? this.periodEndMetricId,
        sortOrder: sortOrder ?? this.sortOrder,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  /// Whether [metric] is one of this profile's two period markers.
  bool ownsCycleMarker(Metric metric) =>
      metric.id == periodStartMetricId || metric.id == periodEndMetricId;
}
