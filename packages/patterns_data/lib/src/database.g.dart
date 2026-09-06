// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MetricsTable extends Metrics with TableInfo<$MetricsTable, MetricRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregationMeta = const VerificationMeta(
    'aggregation',
  );
  @override
  late final GeneratedColumn<String> aggregation = GeneratedColumn<String>(
    'aggregation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayStyleMeta = const VerificationMeta(
    'displayStyle',
  );
  @override
  late final GeneratedColumn<String> displayStyle = GeneratedColumn<String>(
    'display_style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scaleMinMeta = const VerificationMeta(
    'scaleMin',
  );
  @override
  late final GeneratedColumn<int> scaleMin = GeneratedColumn<int>(
    'scale_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _scaleMaxMeta = const VerificationMeta(
    'scaleMax',
  );
  @override
  late final GeneratedColumn<int> scaleMax = GeneratedColumn<int>(
    'scale_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _lowLabelMeta = const VerificationMeta(
    'lowLabel',
  );
  @override
  late final GeneratedColumn<String> lowLabel = GeneratedColumn<String>(
    'low_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highLabelMeta = const VerificationMeta(
    'highLabel',
  );
  @override
  late final GeneratedColumn<String> highLabel = GeneratedColumn<String>(
    'high_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    domain,
    kind,
    aggregation,
    displayStyle,
    colorHex,
    unit,
    scaleMin,
    scaleMax,
    lowLabel,
    highLabel,
    sortOrder,
    createdAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('aggregation')) {
      context.handle(
        _aggregationMeta,
        aggregation.isAcceptableOrUnknown(
          data['aggregation']!,
          _aggregationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregationMeta);
    }
    if (data.containsKey('display_style')) {
      context.handle(
        _displayStyleMeta,
        displayStyle.isAcceptableOrUnknown(
          data['display_style']!,
          _displayStyleMeta,
        ),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('scale_min')) {
      context.handle(
        _scaleMinMeta,
        scaleMin.isAcceptableOrUnknown(data['scale_min']!, _scaleMinMeta),
      );
    }
    if (data.containsKey('scale_max')) {
      context.handle(
        _scaleMaxMeta,
        scaleMax.isAcceptableOrUnknown(data['scale_max']!, _scaleMaxMeta),
      );
    }
    if (data.containsKey('low_label')) {
      context.handle(
        _lowLabelMeta,
        lowLabel.isAcceptableOrUnknown(data['low_label']!, _lowLabelMeta),
      );
    }
    if (data.containsKey('high_label')) {
      context.handle(
        _highLabelMeta,
        highLabel.isAcceptableOrUnknown(data['high_label']!, _highLabelMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      aggregation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregation'],
      )!,
      displayStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_style'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      scaleMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale_min'],
      )!,
      scaleMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale_max'],
      )!,
      lowLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}low_label'],
      ),
      highLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}high_label'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $MetricsTable createAlias(String alias) {
    return $MetricsTable(attachedDatabase, alias);
  }
}

class MetricRow extends DataClass implements Insertable<MetricRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String name;

  /// `mind` / `body` / `cycle`. Decides which section of the home list it sits
  /// in, and nothing else.
  final String domain;

  /// One of the eleven kinds, as its wire name.
  final String kind;

  /// How a day holding several readings collapses in a report: `sum`,
  /// `typical`, `peak`, `lowest`, `last`, `anyTrue`, `union`, `none`.
  ///
  /// **Applied at read time, never at write time.** Changing it re-reads the
  /// same history instead of rewriting it, which is why no aggregate is stored.
  final String aggregation;

  /// How it draws. Null for the kinds that are never charted.
  final String? displayStyle;

  /// `#RRGGBB`, from the fixed palette.
  final String? colorHex;
  final String? unit;
  final int scaleMin;
  final int scaleMax;
  final String? lowLabel;
  final String? highLabel;
  final int sortOrder;
  final int createdAt;

  /// Archived keeps every reading and stops being offered. Finishing a course
  /// of a supplement is archiving, not deleting.
  final int? archivedAt;
  const MetricRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.name,
    required this.domain,
    required this.kind,
    required this.aggregation,
    this.displayStyle,
    this.colorHex,
    this.unit,
    required this.scaleMin,
    required this.scaleMax,
    this.lowLabel,
    this.highLabel,
    required this.sortOrder,
    required this.createdAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['name'] = Variable<String>(name);
    map['domain'] = Variable<String>(domain);
    map['kind'] = Variable<String>(kind);
    map['aggregation'] = Variable<String>(aggregation);
    if (!nullToAbsent || displayStyle != null) {
      map['display_style'] = Variable<String>(displayStyle);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['scale_min'] = Variable<int>(scaleMin);
    map['scale_max'] = Variable<int>(scaleMax);
    if (!nullToAbsent || lowLabel != null) {
      map['low_label'] = Variable<String>(lowLabel);
    }
    if (!nullToAbsent || highLabel != null) {
      map['high_label'] = Variable<String>(highLabel);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    return map;
  }

  MetricsCompanion toCompanion(bool nullToAbsent) {
    return MetricsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      name: Value(name),
      domain: Value(domain),
      kind: Value(kind),
      aggregation: Value(aggregation),
      displayStyle: displayStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(displayStyle),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      scaleMin: Value(scaleMin),
      scaleMax: Value(scaleMax),
      lowLabel: lowLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(lowLabel),
      highLabel: highLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(highLabel),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory MetricRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      name: serializer.fromJson<String>(json['name']),
      domain: serializer.fromJson<String>(json['domain']),
      kind: serializer.fromJson<String>(json['kind']),
      aggregation: serializer.fromJson<String>(json['aggregation']),
      displayStyle: serializer.fromJson<String?>(json['displayStyle']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      unit: serializer.fromJson<String?>(json['unit']),
      scaleMin: serializer.fromJson<int>(json['scaleMin']),
      scaleMax: serializer.fromJson<int>(json['scaleMax']),
      lowLabel: serializer.fromJson<String?>(json['lowLabel']),
      highLabel: serializer.fromJson<String?>(json['highLabel']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'name': serializer.toJson<String>(name),
      'domain': serializer.toJson<String>(domain),
      'kind': serializer.toJson<String>(kind),
      'aggregation': serializer.toJson<String>(aggregation),
      'displayStyle': serializer.toJson<String?>(displayStyle),
      'colorHex': serializer.toJson<String?>(colorHex),
      'unit': serializer.toJson<String?>(unit),
      'scaleMin': serializer.toJson<int>(scaleMin),
      'scaleMax': serializer.toJson<int>(scaleMax),
      'lowLabel': serializer.toJson<String?>(lowLabel),
      'highLabel': serializer.toJson<String?>(highLabel),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
    };
  }

  MetricRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? name,
    String? domain,
    String? kind,
    String? aggregation,
    Value<String?> displayStyle = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? scaleMin,
    int? scaleMax,
    Value<String?> lowLabel = const Value.absent(),
    Value<String?> highLabel = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    Value<int?> archivedAt = const Value.absent(),
  }) => MetricRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    name: name ?? this.name,
    domain: domain ?? this.domain,
    kind: kind ?? this.kind,
    aggregation: aggregation ?? this.aggregation,
    displayStyle: displayStyle.present ? displayStyle.value : this.displayStyle,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    unit: unit.present ? unit.value : this.unit,
    scaleMin: scaleMin ?? this.scaleMin,
    scaleMax: scaleMax ?? this.scaleMax,
    lowLabel: lowLabel.present ? lowLabel.value : this.lowLabel,
    highLabel: highLabel.present ? highLabel.value : this.highLabel,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  MetricRow copyWithCompanion(MetricsCompanion data) {
    return MetricRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      name: data.name.present ? data.name.value : this.name,
      domain: data.domain.present ? data.domain.value : this.domain,
      kind: data.kind.present ? data.kind.value : this.kind,
      aggregation: data.aggregation.present
          ? data.aggregation.value
          : this.aggregation,
      displayStyle: data.displayStyle.present
          ? data.displayStyle.value
          : this.displayStyle,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      unit: data.unit.present ? data.unit.value : this.unit,
      scaleMin: data.scaleMin.present ? data.scaleMin.value : this.scaleMin,
      scaleMax: data.scaleMax.present ? data.scaleMax.value : this.scaleMax,
      lowLabel: data.lowLabel.present ? data.lowLabel.value : this.lowLabel,
      highLabel: data.highLabel.present ? data.highLabel.value : this.highLabel,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('domain: $domain, ')
          ..write('kind: $kind, ')
          ..write('aggregation: $aggregation, ')
          ..write('displayStyle: $displayStyle, ')
          ..write('colorHex: $colorHex, ')
          ..write('unit: $unit, ')
          ..write('scaleMin: $scaleMin, ')
          ..write('scaleMax: $scaleMax, ')
          ..write('lowLabel: $lowLabel, ')
          ..write('highLabel: $highLabel, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    domain,
    kind,
    aggregation,
    displayStyle,
    colorHex,
    unit,
    scaleMin,
    scaleMax,
    lowLabel,
    highLabel,
    sortOrder,
    createdAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.name == this.name &&
          other.domain == this.domain &&
          other.kind == this.kind &&
          other.aggregation == this.aggregation &&
          other.displayStyle == this.displayStyle &&
          other.colorHex == this.colorHex &&
          other.unit == this.unit &&
          other.scaleMin == this.scaleMin &&
          other.scaleMax == this.scaleMax &&
          other.lowLabel == this.lowLabel &&
          other.highLabel == this.highLabel &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt);
}

class MetricsCompanion extends UpdateCompanion<MetricRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> name;
  final Value<String> domain;
  final Value<String> kind;
  final Value<String> aggregation;
  final Value<String?> displayStyle;
  final Value<String?> colorHex;
  final Value<String?> unit;
  final Value<int> scaleMin;
  final Value<int> scaleMax;
  final Value<String?> lowLabel;
  final Value<String?> highLabel;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int?> archivedAt;
  final Value<int> rowid;
  const MetricsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.name = const Value.absent(),
    this.domain = const Value.absent(),
    this.kind = const Value.absent(),
    this.aggregation = const Value.absent(),
    this.displayStyle = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.unit = const Value.absent(),
    this.scaleMin = const Value.absent(),
    this.scaleMax = const Value.absent(),
    this.lowLabel = const Value.absent(),
    this.highLabel = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetricsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String name,
    required String domain,
    required String kind,
    required String aggregation,
    this.displayStyle = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.unit = const Value.absent(),
    this.scaleMin = const Value.absent(),
    this.scaleMax = const Value.absent(),
    this.lowLabel = const Value.absent(),
    this.highLabel = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       name = Value(name),
       domain = Value(domain),
       kind = Value(kind),
       aggregation = Value(aggregation),
       createdAt = Value(createdAt);
  static Insertable<MetricRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? name,
    Expression<String>? domain,
    Expression<String>? kind,
    Expression<String>? aggregation,
    Expression<String>? displayStyle,
    Expression<String>? colorHex,
    Expression<String>? unit,
    Expression<int>? scaleMin,
    Expression<int>? scaleMax,
    Expression<String>? lowLabel,
    Expression<String>? highLabel,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (name != null) 'name': name,
      if (domain != null) 'domain': domain,
      if (kind != null) 'kind': kind,
      if (aggregation != null) 'aggregation': aggregation,
      if (displayStyle != null) 'display_style': displayStyle,
      if (colorHex != null) 'color_hex': colorHex,
      if (unit != null) 'unit': unit,
      if (scaleMin != null) 'scale_min': scaleMin,
      if (scaleMax != null) 'scale_max': scaleMax,
      if (lowLabel != null) 'low_label': lowLabel,
      if (highLabel != null) 'high_label': highLabel,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetricsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? name,
    Value<String>? domain,
    Value<String>? kind,
    Value<String>? aggregation,
    Value<String?>? displayStyle,
    Value<String?>? colorHex,
    Value<String?>? unit,
    Value<int>? scaleMin,
    Value<int>? scaleMax,
    Value<String?>? lowLabel,
    Value<String?>? highLabel,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int?>? archivedAt,
    Value<int>? rowid,
  }) {
    return MetricsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      kind: kind ?? this.kind,
      aggregation: aggregation ?? this.aggregation,
      displayStyle: displayStyle ?? this.displayStyle,
      colorHex: colorHex ?? this.colorHex,
      unit: unit ?? this.unit,
      scaleMin: scaleMin ?? this.scaleMin,
      scaleMax: scaleMax ?? this.scaleMax,
      lowLabel: lowLabel ?? this.lowLabel,
      highLabel: highLabel ?? this.highLabel,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (aggregation.present) {
      map['aggregation'] = Variable<String>(aggregation.value);
    }
    if (displayStyle.present) {
      map['display_style'] = Variable<String>(displayStyle.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (scaleMin.present) {
      map['scale_min'] = Variable<int>(scaleMin.value);
    }
    if (scaleMax.present) {
      map['scale_max'] = Variable<int>(scaleMax.value);
    }
    if (lowLabel.present) {
      map['low_label'] = Variable<String>(lowLabel.value);
    }
    if (highLabel.present) {
      map['high_label'] = Variable<String>(highLabel.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('domain: $domain, ')
          ..write('kind: $kind, ')
          ..write('aggregation: $aggregation, ')
          ..write('displayStyle: $displayStyle, ')
          ..write('colorHex: $colorHex, ')
          ..write('unit: $unit, ')
          ..write('scaleMin: $scaleMin, ')
          ..write('scaleMax: $scaleMax, ')
          ..write('lowLabel: $lowLabel, ')
          ..write('highLabel: $highLabel, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetricOptionsTable extends MetricOptions
    with TableInfo<$MetricOptionsTable, MetricOptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricIdMeta = const VerificationMeta(
    'metricId',
  );
  @override
  late final GeneratedColumn<String> metricId = GeneratedColumn<String>(
    'metric_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    metricId,
    label,
    colorHex,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metric_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricOptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('metric_id')) {
      context.handle(
        _metricIdMeta,
        metricId.isAcceptableOrUnknown(data['metric_id']!, _metricIdMeta),
      );
    } else if (isInserting) {
      context.missing(_metricIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricOptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricOptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      metricId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $MetricOptionsTable createAlias(String alias) {
    return $MetricOptionsTable(attachedDatabase, alias);
  }
}

class MetricOptionRow extends DataClass implements Insertable<MetricOptionRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String metricId;
  final String label;
  final String? colorHex;
  final int sortOrder;

  /// Archived options keep their history and stop being offered.
  final bool archived;
  const MetricOptionRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.metricId,
    required this.label,
    this.colorHex,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['metric_id'] = Variable<String>(metricId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  MetricOptionsCompanion toCompanion(bool nullToAbsent) {
    return MetricOptionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      metricId: Value(metricId),
      label: Value(label),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory MetricOptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricOptionRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      metricId: serializer.fromJson<String>(json['metricId']),
      label: serializer.fromJson<String>(json['label']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'metricId': serializer.toJson<String>(metricId),
      'label': serializer.toJson<String>(label),
      'colorHex': serializer.toJson<String?>(colorHex),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  MetricOptionRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? metricId,
    String? label,
    Value<String?> colorHex = const Value.absent(),
    int? sortOrder,
    bool? archived,
  }) => MetricOptionRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    metricId: metricId ?? this.metricId,
    label: label ?? this.label,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  MetricOptionRow copyWithCompanion(MetricOptionsCompanion data) {
    return MetricOptionRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      metricId: data.metricId.present ? data.metricId.value : this.metricId,
      label: data.label.present ? data.label.value : this.label,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricOptionRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('metricId: $metricId, ')
          ..write('label: $label, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    metricId,
    label,
    colorHex,
    sortOrder,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricOptionRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.metricId == this.metricId &&
          other.label == this.label &&
          other.colorHex == this.colorHex &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class MetricOptionsCompanion extends UpdateCompanion<MetricOptionRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> metricId;
  final Value<String> label;
  final Value<String?> colorHex;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<int> rowid;
  const MetricOptionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.metricId = const Value.absent(),
    this.label = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetricOptionsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String metricId,
    required String label,
    this.colorHex = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       metricId = Value(metricId),
       label = Value(label);
  static Insertable<MetricOptionRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? metricId,
    Expression<String>? label,
    Expression<String>? colorHex,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (metricId != null) 'metric_id': metricId,
      if (label != null) 'label': label,
      if (colorHex != null) 'color_hex': colorHex,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetricOptionsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? metricId,
    Value<String>? label,
    Value<String?>? colorHex,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return MetricOptionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      metricId: metricId ?? this.metricId,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (metricId.present) {
      map['metric_id'] = Variable<String>(metricId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricOptionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('metricId: $metricId, ')
          ..write('label: $label, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ObservationsTable extends Observations
    with TableInfo<$ObservationsTable, ObservationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricIdMeta = const VerificationMeta(
    'metricId',
  );
  @override
  late final GeneratedColumn<String> metricId = GeneratedColumn<String>(
    'metric_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredLateMeta = const VerificationMeta(
    'enteredLate',
  );
  @override
  late final GeneratedColumn<bool> enteredLate = GeneratedColumn<bool>(
    'entered_late',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("entered_late" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    metricId,
    recordedAt,
    valueJson,
    enteredLate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObservationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('metric_id')) {
      context.handle(
        _metricIdMeta,
        metricId.isAcceptableOrUnknown(data['metric_id']!, _metricIdMeta),
      );
    } else if (isInserting) {
      context.missing(_metricIdMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('entered_late')) {
      context.handle(
        _enteredLateMeta,
        enteredLate.isAcceptableOrUnknown(
          data['entered_late']!,
          _enteredLateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObservationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObservationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      metricId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      enteredLate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}entered_late'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ObservationsTable createAlias(String alias) {
    return $ObservationsTable(attachedDatabase, alias);
  }
}

class ObservationRow extends DataClass implements Insertable<ObservationRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String metricId;

  /// UTC epoch millis. Orders readings inside a day.
  final int recordedAt;

  /// The reading itself, as the JSON its kind serialises to.
  ///
  /// One column rather than five typed ones because the kind already says how
  /// to read it, and five columns means four are null on every row. **No
  /// numeric copy is stored alongside it**: a second source of truth for the
  /// same number is how a value and its projection drift apart. Reports load a
  /// date range and do the maths in Dart, which at one person's volume is a
  /// few thousand rows a year.
  final String valueJson;

  /// Filled in after the fact rather than as it happened. Marked, not hidden.
  final bool enteredLate;
  final int createdAt;
  const ObservationRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.metricId,
    required this.recordedAt,
    required this.valueJson,
    required this.enteredLate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['metric_id'] = Variable<String>(metricId);
    map['recorded_at'] = Variable<int>(recordedAt);
    map['value_json'] = Variable<String>(valueJson);
    map['entered_late'] = Variable<bool>(enteredLate);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ObservationsCompanion toCompanion(bool nullToAbsent) {
    return ObservationsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      metricId: Value(metricId),
      recordedAt: Value(recordedAt),
      valueJson: Value(valueJson),
      enteredLate: Value(enteredLate),
      createdAt: Value(createdAt),
    );
  }

  factory ObservationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObservationRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      metricId: serializer.fromJson<String>(json['metricId']),
      recordedAt: serializer.fromJson<int>(json['recordedAt']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      enteredLate: serializer.fromJson<bool>(json['enteredLate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'metricId': serializer.toJson<String>(metricId),
      'recordedAt': serializer.toJson<int>(recordedAt),
      'valueJson': serializer.toJson<String>(valueJson),
      'enteredLate': serializer.toJson<bool>(enteredLate),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ObservationRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    String? metricId,
    int? recordedAt,
    String? valueJson,
    bool? enteredLate,
    int? createdAt,
  }) => ObservationRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    metricId: metricId ?? this.metricId,
    recordedAt: recordedAt ?? this.recordedAt,
    valueJson: valueJson ?? this.valueJson,
    enteredLate: enteredLate ?? this.enteredLate,
    createdAt: createdAt ?? this.createdAt,
  );
  ObservationRow copyWithCompanion(ObservationsCompanion data) {
    return ObservationRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      metricId: data.metricId.present ? data.metricId.value : this.metricId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      enteredLate: data.enteredLate.present
          ? data.enteredLate.value
          : this.enteredLate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObservationRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('metricId: $metricId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('valueJson: $valueJson, ')
          ..write('enteredLate: $enteredLate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    metricId,
    recordedAt,
    valueJson,
    enteredLate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObservationRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.metricId == this.metricId &&
          other.recordedAt == this.recordedAt &&
          other.valueJson == this.valueJson &&
          other.enteredLate == this.enteredLate &&
          other.createdAt == this.createdAt);
}

class ObservationsCompanion extends UpdateCompanion<ObservationRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String> metricId;
  final Value<int> recordedAt;
  final Value<String> valueJson;
  final Value<bool> enteredLate;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ObservationsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.metricId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.enteredLate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObservationsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required String metricId,
    required int recordedAt,
    required String valueJson,
    this.enteredLate = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       metricId = Value(metricId),
       recordedAt = Value(recordedAt),
       valueJson = Value(valueJson),
       createdAt = Value(createdAt);
  static Insertable<ObservationRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? metricId,
    Expression<int>? recordedAt,
    Expression<String>? valueJson,
    Expression<bool>? enteredLate,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (metricId != null) 'metric_id': metricId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (valueJson != null) 'value_json': valueJson,
      if (enteredLate != null) 'entered_late': enteredLate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObservationsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String>? metricId,
    Value<int>? recordedAt,
    Value<String>? valueJson,
    Value<bool>? enteredLate,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ObservationsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      metricId: metricId ?? this.metricId,
      recordedAt: recordedAt ?? this.recordedAt,
      valueJson: valueJson ?? this.valueJson,
      enteredLate: enteredLate ?? this.enteredLate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (metricId.present) {
      map['metric_id'] = Variable<String>(metricId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (enteredLate.present) {
      map['entered_late'] = Variable<bool>(enteredLate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservationsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('metricId: $metricId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('valueJson: $valueJson, ')
          ..write('enteredLate: $enteredLate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, PhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricIdMeta = const VerificationMeta(
    'metricId',
  );
  @override
  late final GeneratedColumn<String> metricId = GeneratedColumn<String>(
    'metric_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observationIdMeta = const VerificationMeta(
    'observationId',
  );
  @override
  late final GeneratedColumn<String> observationId = GeneratedColumn<String>(
    'observation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbFileNameMeta = const VerificationMeta(
    'thumbFileName',
  );
  @override
  late final GeneratedColumn<String> thumbFileName = GeneratedColumn<String>(
    'thumb_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<int> capturedAt = GeneratedColumn<int>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    metricId,
    observationId,
    fileName,
    thumbFileName,
    caption,
    byteSize,
    capturedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('metric_id')) {
      context.handle(
        _metricIdMeta,
        metricId.isAcceptableOrUnknown(data['metric_id']!, _metricIdMeta),
      );
    }
    if (data.containsKey('observation_id')) {
      context.handle(
        _observationIdMeta,
        observationId.isAcceptableOrUnknown(
          data['observation_id']!,
          _observationIdMeta,
        ),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('thumb_file_name')) {
      context.handle(
        _thumbFileNameMeta,
        thumbFileName.isAcceptableOrUnknown(
          data['thumb_file_name']!,
          _thumbFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thumbFileNameMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      metricId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_id'],
      ),
      observationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation_id'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      thumbFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_file_name'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class PhotoRow extends DataClass implements Insertable<PhotoRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;

  /// Null for a free photo that belongs to the day rather than to a marker.
  final String? metricId;

  /// Null for a free photo.
  final String? observationId;

  /// File name inside the app-private photo directory, not a full path: an
  /// absolute path from an old install is wrong after a restore.
  final String fileName;
  final String thumbFileName;

  /// Searchable alongside the diary. The caption is what makes a photo mean
  /// anything six months later.
  final String? caption;

  /// Bytes on disk, so Settings can show a size budget without walking the
  /// directory. **The app never deletes a photo on its own** - it surfaces the
  /// oldest and the choice stays with the user.
  final int byteSize;
  final int capturedAt;
  const PhotoRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    this.metricId,
    this.observationId,
    required this.fileName,
    required this.thumbFileName,
    this.caption,
    required this.byteSize,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    if (!nullToAbsent || metricId != null) {
      map['metric_id'] = Variable<String>(metricId);
    }
    if (!nullToAbsent || observationId != null) {
      map['observation_id'] = Variable<String>(observationId);
    }
    map['file_name'] = Variable<String>(fileName);
    map['thumb_file_name'] = Variable<String>(thumbFileName);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['byte_size'] = Variable<int>(byteSize);
    map['captured_at'] = Variable<int>(capturedAt);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      metricId: metricId == null && nullToAbsent
          ? const Value.absent()
          : Value(metricId),
      observationId: observationId == null && nullToAbsent
          ? const Value.absent()
          : Value(observationId),
      fileName: Value(fileName),
      thumbFileName: Value(thumbFileName),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      byteSize: Value(byteSize),
      capturedAt: Value(capturedAt),
    );
  }

  factory PhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      metricId: serializer.fromJson<String?>(json['metricId']),
      observationId: serializer.fromJson<String?>(json['observationId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      thumbFileName: serializer.fromJson<String>(json['thumbFileName']),
      caption: serializer.fromJson<String?>(json['caption']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      capturedAt: serializer.fromJson<int>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'metricId': serializer.toJson<String?>(metricId),
      'observationId': serializer.toJson<String?>(observationId),
      'fileName': serializer.toJson<String>(fileName),
      'thumbFileName': serializer.toJson<String>(thumbFileName),
      'caption': serializer.toJson<String?>(caption),
      'byteSize': serializer.toJson<int>(byteSize),
      'capturedAt': serializer.toJson<int>(capturedAt),
    };
  }

  PhotoRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    Value<String?> metricId = const Value.absent(),
    Value<String?> observationId = const Value.absent(),
    String? fileName,
    String? thumbFileName,
    Value<String?> caption = const Value.absent(),
    int? byteSize,
    int? capturedAt,
  }) => PhotoRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    metricId: metricId.present ? metricId.value : this.metricId,
    observationId: observationId.present
        ? observationId.value
        : this.observationId,
    fileName: fileName ?? this.fileName,
    thumbFileName: thumbFileName ?? this.thumbFileName,
    caption: caption.present ? caption.value : this.caption,
    byteSize: byteSize ?? this.byteSize,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  PhotoRow copyWithCompanion(PhotosCompanion data) {
    return PhotoRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      metricId: data.metricId.present ? data.metricId.value : this.metricId,
      observationId: data.observationId.present
          ? data.observationId.value
          : this.observationId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      thumbFileName: data.thumbFileName.present
          ? data.thumbFileName.value
          : this.thumbFileName,
      caption: data.caption.present ? data.caption.value : this.caption,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('metricId: $metricId, ')
          ..write('observationId: $observationId, ')
          ..write('fileName: $fileName, ')
          ..write('thumbFileName: $thumbFileName, ')
          ..write('caption: $caption, ')
          ..write('byteSize: $byteSize, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    metricId,
    observationId,
    fileName,
    thumbFileName,
    caption,
    byteSize,
    capturedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.metricId == this.metricId &&
          other.observationId == this.observationId &&
          other.fileName == this.fileName &&
          other.thumbFileName == this.thumbFileName &&
          other.caption == this.caption &&
          other.byteSize == this.byteSize &&
          other.capturedAt == this.capturedAt);
}

class PhotosCompanion extends UpdateCompanion<PhotoRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String?> metricId;
  final Value<String?> observationId;
  final Value<String> fileName;
  final Value<String> thumbFileName;
  final Value<String?> caption;
  final Value<int> byteSize;
  final Value<int> capturedAt;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.metricId = const Value.absent(),
    this.observationId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.thumbFileName = const Value.absent(),
    this.caption = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    this.metricId = const Value.absent(),
    this.observationId = const Value.absent(),
    required String fileName,
    required String thumbFileName,
    this.caption = const Value.absent(),
    required int byteSize,
    required int capturedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       fileName = Value(fileName),
       thumbFileName = Value(thumbFileName),
       byteSize = Value(byteSize),
       capturedAt = Value(capturedAt);
  static Insertable<PhotoRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? metricId,
    Expression<String>? observationId,
    Expression<String>? fileName,
    Expression<String>? thumbFileName,
    Expression<String>? caption,
    Expression<int>? byteSize,
    Expression<int>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (metricId != null) 'metric_id': metricId,
      if (observationId != null) 'observation_id': observationId,
      if (fileName != null) 'file_name': fileName,
      if (thumbFileName != null) 'thumb_file_name': thumbFileName,
      if (caption != null) 'caption': caption,
      if (byteSize != null) 'byte_size': byteSize,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String?>? metricId,
    Value<String?>? observationId,
    Value<String>? fileName,
    Value<String>? thumbFileName,
    Value<String?>? caption,
    Value<int>? byteSize,
    Value<int>? capturedAt,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      metricId: metricId ?? this.metricId,
      observationId: observationId ?? this.observationId,
      fileName: fileName ?? this.fileName,
      thumbFileName: thumbFileName ?? this.thumbFileName,
      caption: caption ?? this.caption,
      byteSize: byteSize ?? this.byteSize,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (metricId.present) {
      map['metric_id'] = Variable<String>(metricId.value);
    }
    if (observationId.present) {
      map['observation_id'] = Variable<String>(observationId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (thumbFileName.present) {
      map['thumb_file_name'] = Variable<String>(thumbFileName.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('metricId: $metricId, ')
          ..write('observationId: $observationId, ')
          ..write('fileName: $fileName, ')
          ..write('thumbFileName: $thumbFileName, ')
          ..write('caption: $caption, ')
          ..write('byteSize: $byteSize, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedReportsTable extends SavedReports
    with TableInfo<$SavedReportsTable, SavedReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesJsonMeta = const VerificationMeta(
    'seriesJson',
  );
  @override
  late final GeneratedColumn<String> seriesJson = GeneratedColumn<String>(
    'series_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _axisMeta = const VerificationMeta('axis');
  @override
  late final GeneratedColumn<String> axis = GeneratedColumn<String>(
    'axis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    seriesJson,
    period,
    axis,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedReportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('series_json')) {
      context.handle(
        _seriesJsonMeta,
        seriesJson.isAcceptableOrUnknown(data['series_json']!, _seriesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesJsonMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('axis')) {
      context.handle(
        _axisMeta,
        axis.isAcceptableOrUnknown(data['axis']!, _axisMeta),
      );
    } else if (isInserting) {
      context.missing(_axisMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedReportRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      seriesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_json'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      axis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}axis'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedReportsTable createAlias(String alias) {
    return $SavedReportsTable(attachedDatabase, alias);
  }
}

class SavedReportRow extends DataClass implements Insertable<SavedReportRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String name;

  /// The series, as JSON: marker id, display override, and which row a boolean
  /// band rides behind. JSON rather than a second table because a series has no
  /// identity of its own - it exists only inside its report, and is always read
  /// and written whole.
  final String seriesJson;

  /// `last:30` or `2026-08-01..2026-08-31`. A rolling window and a fixed
  /// stretch in one column, both round-tripped by `ReportPeriod`.
  final String period;

  /// `date` or `cycleDay`, as a string. Never an ordinal.
  final String axis;
  final int sortOrder;
  final int createdAt;
  const SavedReportRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.name,
    required this.seriesJson,
    required this.period,
    required this.axis,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['name'] = Variable<String>(name);
    map['series_json'] = Variable<String>(seriesJson);
    map['period'] = Variable<String>(period);
    map['axis'] = Variable<String>(axis);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SavedReportsCompanion toCompanion(bool nullToAbsent) {
    return SavedReportsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      name: Value(name),
      seriesJson: Value(seriesJson),
      period: Value(period),
      axis: Value(axis),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory SavedReportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedReportRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      name: serializer.fromJson<String>(json['name']),
      seriesJson: serializer.fromJson<String>(json['seriesJson']),
      period: serializer.fromJson<String>(json['period']),
      axis: serializer.fromJson<String>(json['axis']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'name': serializer.toJson<String>(name),
      'seriesJson': serializer.toJson<String>(seriesJson),
      'period': serializer.toJson<String>(period),
      'axis': serializer.toJson<String>(axis),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SavedReportRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? name,
    String? seriesJson,
    String? period,
    String? axis,
    int? sortOrder,
    int? createdAt,
  }) => SavedReportRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    name: name ?? this.name,
    seriesJson: seriesJson ?? this.seriesJson,
    period: period ?? this.period,
    axis: axis ?? this.axis,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedReportRow copyWithCompanion(SavedReportsCompanion data) {
    return SavedReportRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      name: data.name.present ? data.name.value : this.name,
      seriesJson: data.seriesJson.present
          ? data.seriesJson.value
          : this.seriesJson,
      period: data.period.present ? data.period.value : this.period,
      axis: data.axis.present ? data.axis.value : this.axis,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedReportRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('seriesJson: $seriesJson, ')
          ..write('period: $period, ')
          ..write('axis: $axis, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    seriesJson,
    period,
    axis,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedReportRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.name == this.name &&
          other.seriesJson == this.seriesJson &&
          other.period == this.period &&
          other.axis == this.axis &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class SavedReportsCompanion extends UpdateCompanion<SavedReportRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> name;
  final Value<String> seriesJson;
  final Value<String> period;
  final Value<String> axis;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SavedReportsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.name = const Value.absent(),
    this.seriesJson = const Value.absent(),
    this.period = const Value.absent(),
    this.axis = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedReportsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String name,
    required String seriesJson,
    required String period,
    required String axis,
    this.sortOrder = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       name = Value(name),
       seriesJson = Value(seriesJson),
       period = Value(period),
       axis = Value(axis),
       createdAt = Value(createdAt);
  static Insertable<SavedReportRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? name,
    Expression<String>? seriesJson,
    Expression<String>? period,
    Expression<String>? axis,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (name != null) 'name': name,
      if (seriesJson != null) 'series_json': seriesJson,
      if (period != null) 'period': period,
      if (axis != null) 'axis': axis,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedReportsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? name,
    Value<String>? seriesJson,
    Value<String>? period,
    Value<String>? axis,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedReportsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      name: name ?? this.name,
      seriesJson: seriesJson ?? this.seriesJson,
      period: period ?? this.period,
      axis: axis ?? this.axis,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (seriesJson.present) {
      map['series_json'] = Variable<String>(seriesJson.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (axis.present) {
      map['axis'] = Variable<String>(axis.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedReportsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('seriesJson: $seriesJson, ')
          ..write('period: $period, ')
          ..write('axis: $axis, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    key,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String key;
  final String value;
  const Setting({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? key,
    String? value,
  }) => Setting(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, installId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceInstallIdMeta = const VerificationMeta(
    'deviceInstallId',
  );
  @override
  late final GeneratedColumn<String> deviceInstallId = GeneratedColumn<String>(
    'device_install_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<int> installedAt = GeneratedColumn<int>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    deviceInstallId,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('device_install_id')) {
      context.handle(
        _deviceInstallIdMeta,
        deviceInstallId.isAcceptableOrUnknown(
          data['device_install_id']!,
          _deviceInstallIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceInstallIdMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      deviceInstallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_install_id'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String deviceInstallId;
  final int installedAt;
  const AppMetaRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.deviceInstallId,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['device_install_id'] = Variable<String>(deviceInstallId);
    map['installed_at'] = Variable<int>(installedAt);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      deviceInstallId: Value(deviceInstallId),
      installedAt: Value(installedAt),
    );
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      deviceInstallId: serializer.fromJson<String>(json['deviceInstallId']),
      installedAt: serializer.fromJson<int>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'deviceInstallId': serializer.toJson<String>(deviceInstallId),
      'installedAt': serializer.toJson<int>(installedAt),
    };
  }

  AppMetaRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? deviceInstallId,
    int? installedAt,
  }) => AppMetaRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    deviceInstallId: deviceInstallId ?? this.deviceInstallId,
    installedAt: installedAt ?? this.installedAt,
  );
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      deviceInstallId: data.deviceInstallId.present
          ? data.deviceInstallId.value
          : this.deviceInstallId,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('deviceInstallId: $deviceInstallId, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    deviceInstallId,
    installedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.deviceInstallId == this.deviceInstallId &&
          other.installedAt == this.installedAt);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> deviceInstallId;
  final Value<int> installedAt;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.deviceInstallId = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String deviceInstallId,
    required int installedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       deviceInstallId = Value(deviceInstallId),
       installedAt = Value(installedAt);
  static Insertable<AppMetaRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? deviceInstallId,
    Expression<int>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (deviceInstallId != null) 'device_install_id': deviceInstallId,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? deviceInstallId,
    Value<int>? installedAt,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      deviceInstallId: deviceInstallId ?? this.deviceInstallId,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (deviceInstallId.present) {
      map['device_install_id'] = Variable<String>(deviceInstallId.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<int>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('deviceInstallId: $deviceInstallId, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PatternsDatabase extends GeneratedDatabase {
  _$PatternsDatabase(QueryExecutor e) : super(e);
  $PatternsDatabaseManager get managers => $PatternsDatabaseManager(this);
  late final $MetricsTable metrics = $MetricsTable(this);
  late final $MetricOptionsTable metricOptions = $MetricOptionsTable(this);
  late final $ObservationsTable observations = $ObservationsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $SavedReportsTable savedReports = $SavedReportsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    metrics,
    metricOptions,
    observations,
    photos,
    savedReports,
    settings,
    appMeta,
  ];
}

typedef $$MetricsTableCreateCompanionBuilder =
    MetricsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String name,
      required String domain,
      required String kind,
      required String aggregation,
      Value<String?> displayStyle,
      Value<String?> colorHex,
      Value<String?> unit,
      Value<int> scaleMin,
      Value<int> scaleMax,
      Value<String?> lowLabel,
      Value<String?> highLabel,
      Value<int> sortOrder,
      required int createdAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });
typedef $$MetricsTableUpdateCompanionBuilder =
    MetricsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> name,
      Value<String> domain,
      Value<String> kind,
      Value<String> aggregation,
      Value<String?> displayStyle,
      Value<String?> colorHex,
      Value<String?> unit,
      Value<int> scaleMin,
      Value<int> scaleMax,
      Value<String?> lowLabel,
      Value<String?> highLabel,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });

class $$MetricsTableFilterComposer
    extends Composer<_$PatternsDatabase, $MetricsTable> {
  $$MetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregation => $composableBuilder(
    column: $table.aggregation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayStyle => $composableBuilder(
    column: $table.displayStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scaleMin => $composableBuilder(
    column: $table.scaleMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scaleMax => $composableBuilder(
    column: $table.scaleMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lowLabel => $composableBuilder(
    column: $table.lowLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get highLabel => $composableBuilder(
    column: $table.highLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricsTableOrderingComposer
    extends Composer<_$PatternsDatabase, $MetricsTable> {
  $$MetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregation => $composableBuilder(
    column: $table.aggregation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayStyle => $composableBuilder(
    column: $table.displayStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scaleMin => $composableBuilder(
    column: $table.scaleMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scaleMax => $composableBuilder(
    column: $table.scaleMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lowLabel => $composableBuilder(
    column: $table.lowLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get highLabel => $composableBuilder(
    column: $table.highLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricsTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $MetricsTable> {
  $$MetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get aggregation => $composableBuilder(
    column: $table.aggregation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayStyle => $composableBuilder(
    column: $table.displayStyle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get scaleMin =>
      $composableBuilder(column: $table.scaleMin, builder: (column) => column);

  GeneratedColumn<int> get scaleMax =>
      $composableBuilder(column: $table.scaleMax, builder: (column) => column);

  GeneratedColumn<String> get lowLabel =>
      $composableBuilder(column: $table.lowLabel, builder: (column) => column);

  GeneratedColumn<String> get highLabel =>
      $composableBuilder(column: $table.highLabel, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$MetricsTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $MetricsTable,
          MetricRow,
          $$MetricsTableFilterComposer,
          $$MetricsTableOrderingComposer,
          $$MetricsTableAnnotationComposer,
          $$MetricsTableCreateCompanionBuilder,
          $$MetricsTableUpdateCompanionBuilder,
          (
            MetricRow,
            BaseReferences<_$PatternsDatabase, $MetricsTable, MetricRow>,
          ),
          MetricRow,
          PrefetchHooks Function()
        > {
  $$MetricsTableTableManager(_$PatternsDatabase db, $MetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> aggregation = const Value.absent(),
                Value<String?> displayStyle = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> scaleMin = const Value.absent(),
                Value<int> scaleMax = const Value.absent(),
                Value<String?> lowLabel = const Value.absent(),
                Value<String?> highLabel = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                domain: domain,
                kind: kind,
                aggregation: aggregation,
                displayStyle: displayStyle,
                colorHex: colorHex,
                unit: unit,
                scaleMin: scaleMin,
                scaleMax: scaleMax,
                lowLabel: lowLabel,
                highLabel: highLabel,
                sortOrder: sortOrder,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String name,
                required String domain,
                required String kind,
                required String aggregation,
                Value<String?> displayStyle = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> scaleMin = const Value.absent(),
                Value<int> scaleMax = const Value.absent(),
                Value<String?> lowLabel = const Value.absent(),
                Value<String?> highLabel = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                domain: domain,
                kind: kind,
                aggregation: aggregation,
                displayStyle: displayStyle,
                colorHex: colorHex,
                unit: unit,
                scaleMin: scaleMin,
                scaleMax: scaleMax,
                lowLabel: lowLabel,
                highLabel: highLabel,
                sortOrder: sortOrder,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $MetricsTable,
      MetricRow,
      $$MetricsTableFilterComposer,
      $$MetricsTableOrderingComposer,
      $$MetricsTableAnnotationComposer,
      $$MetricsTableCreateCompanionBuilder,
      $$MetricsTableUpdateCompanionBuilder,
      (MetricRow, BaseReferences<_$PatternsDatabase, $MetricsTable, MetricRow>),
      MetricRow,
      PrefetchHooks Function()
    >;
typedef $$MetricOptionsTableCreateCompanionBuilder =
    MetricOptionsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String metricId,
      required String label,
      Value<String?> colorHex,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$MetricOptionsTableUpdateCompanionBuilder =
    MetricOptionsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> metricId,
      Value<String> label,
      Value<String?> colorHex,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<int> rowid,
    });

class $$MetricOptionsTableFilterComposer
    extends Composer<_$PatternsDatabase, $MetricOptionsTable> {
  $$MetricOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricOptionsTableOrderingComposer
    extends Composer<_$PatternsDatabase, $MetricOptionsTable> {
  $$MetricOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricOptionsTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $MetricOptionsTable> {
  $$MetricOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get metricId =>
      $composableBuilder(column: $table.metricId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$MetricOptionsTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $MetricOptionsTable,
          MetricOptionRow,
          $$MetricOptionsTableFilterComposer,
          $$MetricOptionsTableOrderingComposer,
          $$MetricOptionsTableAnnotationComposer,
          $$MetricOptionsTableCreateCompanionBuilder,
          $$MetricOptionsTableUpdateCompanionBuilder,
          (
            MetricOptionRow,
            BaseReferences<
              _$PatternsDatabase,
              $MetricOptionsTable,
              MetricOptionRow
            >,
          ),
          MetricOptionRow,
          PrefetchHooks Function()
        > {
  $$MetricOptionsTableTableManager(
    _$PatternsDatabase db,
    $MetricOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> metricId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricOptionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                metricId: metricId,
                label: label,
                colorHex: colorHex,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String metricId,
                required String label,
                Value<String?> colorHex = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricOptionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                metricId: metricId,
                label: label,
                colorHex: colorHex,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $MetricOptionsTable,
      MetricOptionRow,
      $$MetricOptionsTableFilterComposer,
      $$MetricOptionsTableOrderingComposer,
      $$MetricOptionsTableAnnotationComposer,
      $$MetricOptionsTableCreateCompanionBuilder,
      $$MetricOptionsTableUpdateCompanionBuilder,
      (
        MetricOptionRow,
        BaseReferences<
          _$PatternsDatabase,
          $MetricOptionsTable,
          MetricOptionRow
        >,
      ),
      MetricOptionRow,
      PrefetchHooks Function()
    >;
typedef $$ObservationsTableCreateCompanionBuilder =
    ObservationsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required String metricId,
      required int recordedAt,
      required String valueJson,
      Value<bool> enteredLate,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ObservationsTableUpdateCompanionBuilder =
    ObservationsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String> metricId,
      Value<int> recordedAt,
      Value<String> valueJson,
      Value<bool> enteredLate,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$ObservationsTableFilterComposer
    extends Composer<_$PatternsDatabase, $ObservationsTable> {
  $$ObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enteredLate => $composableBuilder(
    column: $table.enteredLate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ObservationsTableOrderingComposer
    extends Composer<_$PatternsDatabase, $ObservationsTable> {
  $$ObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enteredLate => $composableBuilder(
    column: $table.enteredLate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ObservationsTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $ObservationsTable> {
  $$ObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metricId =>
      $composableBuilder(column: $table.metricId, builder: (column) => column);

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<bool> get enteredLate => $composableBuilder(
    column: $table.enteredLate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ObservationsTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $ObservationsTable,
          ObservationRow,
          $$ObservationsTableFilterComposer,
          $$ObservationsTableOrderingComposer,
          $$ObservationsTableAnnotationComposer,
          $$ObservationsTableCreateCompanionBuilder,
          $$ObservationsTableUpdateCompanionBuilder,
          (
            ObservationRow,
            BaseReferences<
              _$PatternsDatabase,
              $ObservationsTable,
              ObservationRow
            >,
          ),
          ObservationRow,
          PrefetchHooks Function()
        > {
  $$ObservationsTableTableManager(
    _$PatternsDatabase db,
    $ObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> metricId = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<bool> enteredLate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObservationsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                metricId: metricId,
                recordedAt: recordedAt,
                valueJson: valueJson,
                enteredLate: enteredLate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required String metricId,
                required int recordedAt,
                required String valueJson,
                Value<bool> enteredLate = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ObservationsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                metricId: metricId,
                recordedAt: recordedAt,
                valueJson: valueJson,
                enteredLate: enteredLate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $ObservationsTable,
      ObservationRow,
      $$ObservationsTableFilterComposer,
      $$ObservationsTableOrderingComposer,
      $$ObservationsTableAnnotationComposer,
      $$ObservationsTableCreateCompanionBuilder,
      $$ObservationsTableUpdateCompanionBuilder,
      (
        ObservationRow,
        BaseReferences<_$PatternsDatabase, $ObservationsTable, ObservationRow>,
      ),
      ObservationRow,
      PrefetchHooks Function()
    >;
typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      Value<String?> metricId,
      Value<String?> observationId,
      required String fileName,
      required String thumbFileName,
      Value<String?> caption,
      required int byteSize,
      required int capturedAt,
      Value<int> rowid,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String?> metricId,
      Value<String?> observationId,
      Value<String> fileName,
      Value<String> thumbFileName,
      Value<String?> caption,
      Value<int> byteSize,
      Value<int> capturedAt,
      Value<int> rowid,
    });

class $$PhotosTableFilterComposer
    extends Composer<_$PatternsDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observationId => $composableBuilder(
    column: $table.observationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbFileName => $composableBuilder(
    column: $table.thumbFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotosTableOrderingComposer
    extends Composer<_$PatternsDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observationId => $composableBuilder(
    column: $table.observationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbFileName => $composableBuilder(
    column: $table.thumbFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metricId =>
      $composableBuilder(column: $table.metricId, builder: (column) => column);

  GeneratedColumn<String> get observationId => $composableBuilder(
    column: $table.observationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get thumbFileName => $composableBuilder(
    column: $table.thumbFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $PhotosTable,
          PhotoRow,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (
            PhotoRow,
            BaseReferences<_$PatternsDatabase, $PhotosTable, PhotoRow>,
          ),
          PhotoRow,
          PrefetchHooks Function()
        > {
  $$PhotosTableTableManager(_$PatternsDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String?> metricId = const Value.absent(),
                Value<String?> observationId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> thumbFileName = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> capturedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                metricId: metricId,
                observationId: observationId,
                fileName: fileName,
                thumbFileName: thumbFileName,
                caption: caption,
                byteSize: byteSize,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                Value<String?> metricId = const Value.absent(),
                Value<String?> observationId = const Value.absent(),
                required String fileName,
                required String thumbFileName,
                Value<String?> caption = const Value.absent(),
                required int byteSize,
                required int capturedAt,
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                metricId: metricId,
                observationId: observationId,
                fileName: fileName,
                thumbFileName: thumbFileName,
                caption: caption,
                byteSize: byteSize,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $PhotosTable,
      PhotoRow,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (PhotoRow, BaseReferences<_$PatternsDatabase, $PhotosTable, PhotoRow>),
      PhotoRow,
      PrefetchHooks Function()
    >;
typedef $$SavedReportsTableCreateCompanionBuilder =
    SavedReportsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String name,
      required String seriesJson,
      required String period,
      required String axis,
      Value<int> sortOrder,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SavedReportsTableUpdateCompanionBuilder =
    SavedReportsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> name,
      Value<String> seriesJson,
      Value<String> period,
      Value<String> axis,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$SavedReportsTableFilterComposer
    extends Composer<_$PatternsDatabase, $SavedReportsTable> {
  $$SavedReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesJson => $composableBuilder(
    column: $table.seriesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get axis => $composableBuilder(
    column: $table.axis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedReportsTableOrderingComposer
    extends Composer<_$PatternsDatabase, $SavedReportsTable> {
  $$SavedReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesJson => $composableBuilder(
    column: $table.seriesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axis => $composableBuilder(
    column: $table.axis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedReportsTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $SavedReportsTable> {
  $$SavedReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get seriesJson => $composableBuilder(
    column: $table.seriesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get axis =>
      $composableBuilder(column: $table.axis, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedReportsTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $SavedReportsTable,
          SavedReportRow,
          $$SavedReportsTableFilterComposer,
          $$SavedReportsTableOrderingComposer,
          $$SavedReportsTableAnnotationComposer,
          $$SavedReportsTableCreateCompanionBuilder,
          $$SavedReportsTableUpdateCompanionBuilder,
          (
            SavedReportRow,
            BaseReferences<
              _$PatternsDatabase,
              $SavedReportsTable,
              SavedReportRow
            >,
          ),
          SavedReportRow,
          PrefetchHooks Function()
        > {
  $$SavedReportsTableTableManager(
    _$PatternsDatabase db,
    $SavedReportsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> seriesJson = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<String> axis = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedReportsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                seriesJson: seriesJson,
                period: period,
                axis: axis,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String name,
                required String seriesJson,
                required String period,
                required String axis,
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavedReportsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                seriesJson: seriesJson,
                period: period,
                axis: axis,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $SavedReportsTable,
      SavedReportRow,
      $$SavedReportsTableFilterComposer,
      $$SavedReportsTableOrderingComposer,
      $$SavedReportsTableAnnotationComposer,
      $$SavedReportsTableCreateCompanionBuilder,
      $$SavedReportsTableUpdateCompanionBuilder,
      (
        SavedReportRow,
        BaseReferences<_$PatternsDatabase, $SavedReportsTable, SavedReportRow>,
      ),
      SavedReportRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$PatternsDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$PatternsDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            Setting,
            BaseReferences<_$PatternsDatabase, $SettingsTable, Setting>,
          ),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$PatternsDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$PatternsDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String deviceInstallId,
      required int installedAt,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> deviceInstallId,
      Value<int> installedAt,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$PatternsDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$PatternsDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$PatternsDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$PatternsDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$PatternsDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$PatternsDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> deviceInstallId = const Value.absent(),
                Value<int> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                deviceInstallId: deviceInstallId,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String deviceInstallId,
                required int installedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                deviceInstallId: deviceInstallId,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$PatternsDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (
        AppMetaRow,
        BaseReferences<_$PatternsDatabase, $AppMetaTable, AppMetaRow>,
      ),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $PatternsDatabaseManager {
  final _$PatternsDatabase _db;
  $PatternsDatabaseManager(this._db);
  $$MetricsTableTableManager get metrics =>
      $$MetricsTableTableManager(_db, _db.metrics);
  $$MetricOptionsTableTableManager get metricOptions =>
      $$MetricOptionsTableTableManager(_db, _db.metricOptions);
  $$ObservationsTableTableManager get observations =>
      $$ObservationsTableTableManager(_db, _db.observations);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$SavedReportsTableTableManager get savedReports =>
      $$SavedReportsTableTableManager(_db, _db.savedReports);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
