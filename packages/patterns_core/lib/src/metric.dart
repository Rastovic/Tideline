import 'aggregation.dart';
import 'display.dart';
import 'metric_kind.dart';

/// Which section of the home list a marker sits in. Nothing else.
///
/// It decides where the marker is listed and never what it means or what it can
/// be compared with. Bloating is on [body] and irritability is on [mind], and a
/// report can stack them anyway, because a domain is a heading rather than a
/// container.
enum MetricDomain {
  mind('mind'),
  body('body'),

  /// Period start and period end, and nothing else.
  ///
  /// The module exists for the axis, not for the calendar: a recorded start
  /// lets every other marker be re-sorted by cycle day. Symptoms are ordinary
  /// markers on [body] and are deliberately **not** owned by this domain.
  cycle('cycle');

  const MetricDomain(this.wireName);

  final String wireName;

  static MetricDomain? fromWire(String value) {
    for (final domain in MetricDomain.values) {
      if (domain.wireName == value) return domain;
    }
    return null;
  }
}

/// One option of a [MetricKind.choice] or [MetricKind.tags] marker.
///
/// Carries a stable [id] so a label can be reworded without rewriting history:
/// renaming "overthink" to "premišljanje" must not orphan four months of it.
final class MetricOption {
  const MetricOption({
    required this.id,
    required this.label,
    this.colorHex,
    this.sortOrder = 0,
    this.archived = false,
  });

  final String id;
  final String label;

  /// Optional own colour, so a tag row can be told apart at a glance.
  final String? colorHex;
  final int sortOrder;

  /// Archived options keep their history and stop being offered.
  final bool archived;

  MetricOption copyWith({
    String? label,
    String? colorHex,
    int? sortOrder,
    bool? archived,
  }) =>
      MetricOption(
        id: id,
        label: label ?? this.label,
        colorHex: colorHex ?? this.colorHex,
        sortOrder: sortOrder ?? this.sortOrder,
        archived: archived ?? this.archived,
      );

  @override
  bool operator ==(Object other) =>
      other is MetricOption &&
      other.id == id &&
      other.label == label &&
      other.colorHex == colorHex &&
      other.sortOrder == sortOrder &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(id, label, colorHex, sortOrder, archived);
}

/// A thing being tracked.
///
/// **Every marker is this object.** The ones seeded on first run and the ones
/// invented in the editor two years later are the same class, stored in the
/// same table, with the same fields. There is no built-in flag and no special
/// case, because "track my own thing" is the reason the app exists.
///
/// **No marker carries a goal, a target, a streak or a direction.** Their
/// absence is deliberate and load-bearing: this app records, it never grades,
/// and a field for a target is how grading gets added later by accident.
///
/// **No marker owns another.** Creatine does not own bloating, and the cycle
/// does not own irritability. Markers are independent streams that share a date
/// axis, and every connection is made by the user in a report, afterwards.
final class Metric {
  const Metric({
    required this.id,
    required this.name,
    required this.domain,
    required this.kind,
    required this.aggregation,
    required this.createdAt,
    this.displayStyle,
    this.colorHex,
    this.unit,
    this.scaleMin = 1,
    this.scaleMax = 10,
    this.lowLabel,
    this.highLabel,
    this.options = const [],
    this.sortOrder = 0,
    this.archivedAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Creates a marker with the defaults its kind implies.
  ///
  /// The editor calls this, so a new marker is always internally consistent
  /// before the user has touched a single field.
  factory Metric.create({
    required String id,
    required String name,
    required MetricDomain domain,
    required MetricKind kind,
    required DateTime createdAt,
    String? colorHex,
    String? unit,
    int scaleMin = 1,
    int scaleMax = 10,
    String? lowLabel,
    String? highLabel,
    List<MetricOption> options = const [],
    int sortOrder = 0,
  }) =>
      Metric(
        id: id,
        name: name,
        domain: domain,
        kind: kind,
        aggregation: DayAggregation.defaultFor(kind),
        displayStyle: DisplayStyle.defaultFor(kind),
        createdAt: createdAt,
        colorHex: colorHex,
        unit: unit,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
        lowLabel: lowLabel,
        highLabel: highLabel,
        options: options,
        sortOrder: sortOrder,
      );

  final String id;

  /// User-editable on every marker, seeded ones included.
  final String name;
  final MetricDomain domain;
  final MetricKind kind;

  /// How a day holding several readings collapses to one value in a report.
  final DayAggregation aggregation;

  /// How it draws. Null for the kinds that are never charted.
  final DisplayStyle? displayStyle;

  /// `#RRGGBB`. Assigned from a fixed palette at creation rather than picked
  /// freely, because two markers in near-identical colours ruin the one screen
  /// colours exist for - a stack of rows read together.
  final String? colorHex;

  /// Free text, for the kinds that take one: `g`, `kg`, `ml`, `min`.
  final String? unit;

  /// Bounds for [MetricKind.scale]. Ignored by every other kind.
  final int scaleMin;
  final int scaleMax;

  /// What the ends of the scale mean, in the user's words.
  final String? lowLabel;
  final String? highLabel;

  /// Options for [MetricKind.choice] and [MetricKind.tags].
  final List<MetricOption> options;

  /// Position in its section of the home list.
  final int sortOrder;

  /// An archived marker keeps every reading and stops being offered or
  /// reminded about. Finishing a course of a supplement is archiving, not
  /// deleting, and the reports still draw those months.
  final DateTime? archivedAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Tombstone. Rows are never hard-deleted, per `DATA-PORTABILITY.md` rule 3.
  final DateTime? deletedAt;

  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;

  /// Whether it appears on the home list and in the reminder.
  bool get isActive => !isArchived && !isDeleted;

  /// The options still offered for picking, in order.
  List<MetricOption> get liveOptions =>
      [...options.where((o) => !o.archived)]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Metric copyWith({
    String? name,
    MetricDomain? domain,
    DayAggregation? aggregation,
    DisplayStyle? displayStyle,
    String? colorHex,
    String? unit,
    int? scaleMin,
    int? scaleMax,
    String? lowLabel,
    String? highLabel,
    List<MetricOption>? options,
    int? sortOrder,
    DateTime? archivedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearArchivedAt = false,
  }) =>
      Metric(
        id: id,
        // Kind is absent on purpose: retyping a marker that already holds
        // readings is not an edit, it is "archive this and create a new one".
        // Reinterpreting a year of 1-10 ratings as percentages is a data-loss
        // bug wearing a feature's clothes.
        kind: kind,
        name: name ?? this.name,
        domain: domain ?? this.domain,
        aggregation: aggregation ?? this.aggregation,
        displayStyle: displayStyle ?? this.displayStyle,
        colorHex: colorHex ?? this.colorHex,
        unit: unit ?? this.unit,
        scaleMin: scaleMin ?? this.scaleMin,
        scaleMax: scaleMax ?? this.scaleMax,
        lowLabel: lowLabel ?? this.lowLabel,
        highLabel: highLabel ?? this.highLabel,
        options: options ?? this.options,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
        archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  @override
  String toString() => 'Metric($name, ${kind.wireName}, ${domain.wireName})';
}
