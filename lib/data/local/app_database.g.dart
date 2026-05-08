// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MoodsTable extends Moods with TableInfo<$MoodsTable, Mood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
      'x', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
      'y', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumnWithTypeConverter<MoodCategory, String> category =
      GeneratedColumn<String>('category', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MoodCategory>($MoodsTable.$convertercategory);
  @override
  List<GeneratedColumn> get $columns => [id, name, x, y, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moods';
  @override
  VerificationContext validateIntegrity(Insertable<Mood> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    context.handle(_categoryMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mood(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      x: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}x'])!,
      y: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}y'])!,
      category: $MoodsTable.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!),
    );
  }

  @override
  $MoodsTable createAlias(String alias) {
    return $MoodsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MoodCategory, String, String> $convertercategory =
      const EnumNameConverter<MoodCategory>(MoodCategory.values);
}

class Mood extends DataClass implements Insertable<Mood> {
  final int id;
  final String name;
  final double x;
  final double y;
  final MoodCategory category;
  const Mood(
      {required this.id,
      required this.name,
      required this.x,
      required this.y,
      required this.category});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    {
      map['category'] =
          Variable<String>($MoodsTable.$convertercategory.toSql(category));
    }
    return map;
  }

  MoodsCompanion toCompanion(bool nullToAbsent) {
    return MoodsCompanion(
      id: Value(id),
      name: Value(name),
      x: Value(x),
      y: Value(y),
      category: Value(category),
    );
  }

  factory Mood.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mood(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      category: $MoodsTable.$convertercategory
          .fromJson(serializer.fromJson<String>(json['category'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'category': serializer
          .toJson<String>($MoodsTable.$convertercategory.toJson(category)),
    };
  }

  Mood copyWith(
          {int? id,
          String? name,
          double? x,
          double? y,
          MoodCategory? category}) =>
      Mood(
        id: id ?? this.id,
        name: name ?? this.name,
        x: x ?? this.x,
        y: y ?? this.y,
        category: category ?? this.category,
      );
  @override
  String toString() {
    return (StringBuffer('Mood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, x, y, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mood &&
          other.id == this.id &&
          other.name == this.name &&
          other.x == this.x &&
          other.y == this.y &&
          other.category == this.category);
}

class MoodsCompanion extends UpdateCompanion<Mood> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> x;
  final Value<double> y;
  final Value<MoodCategory> category;
  const MoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.category = const Value.absent(),
  });
  MoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double x,
    required double y,
    required MoodCategory category,
  })  : name = Value(name),
        x = Value(x),
        y = Value(y),
        category = Value(category);
  static Insertable<Mood> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? x,
    Expression<double>? y,
    Expression<String>? category,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (category != null) 'category': category,
    });
  }

  MoodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? x,
      Value<double>? y,
      Value<MoodCategory>? category}) {
    return MoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
          $MoodsTable.$convertercategory.toSql(category.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }
}

class $MoodEntriesTable extends MoodEntries
    with TableInfo<$MoodEntriesTable, MoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodIdMeta = const VerificationMeta('moodId');
  @override
  late final GeneratedColumn<int> moodId = GeneratedColumn<int>(
      'mood_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES moods (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, moodId, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entries';
  @override
  VerificationContext validateIntegrity(Insertable<MoodEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mood_id')) {
      context.handle(_moodIdMeta,
          moodId.isAcceptableOrUnknown(data['mood_id']!, _moodIdMeta));
    } else if (isInserting) {
      context.missing(_moodIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      moodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MoodEntriesTable createAlias(String alias) {
    return $MoodEntriesTable(attachedDatabase, alias);
  }
}

class MoodEntry extends DataClass implements Insertable<MoodEntry> {
  final int id;
  final String userId;
  final int moodId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MoodEntry(
      {required this.id,
      required this.userId,
      required this.moodId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['mood_id'] = Variable<int>(moodId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      moodId: Value(moodId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntry(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      moodId: serializer.fromJson<int>(json['moodId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'moodId': serializer.toJson<int>(moodId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MoodEntry copyWith(
          {int? id,
          String? userId,
          int? moodId,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MoodEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        moodId: moodId ?? this.moodId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('MoodEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, moodId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.moodId == this.moodId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntry> {
  final Value<int> id;
  final Value<String> userId;
  final Value<int> moodId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.moodId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required int moodId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : userId = Value(userId),
        moodId = Value(moodId);
  static Insertable<MoodEntry> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<int>? moodId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (moodId != null) 'mood_id': moodId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MoodEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<int>? moodId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodId: moodId ?? this.moodId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (moodId.present) {
      map['mood_id'] = Variable<int>(moodId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ContextTagsTable extends ContextTags
    with TableInfo<$ContextTagsTable, ContextTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<ContextTagType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<ContextTagType>($ContextTagsTable.$convertertype);
  static const VerificationMeta _isCustomMeta =
      const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
      'is_custom', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, isCustom, isActive, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_tags';
  @override
  VerificationContext validateIntegrity(Insertable<ContextTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta,
          isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextTag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $ContextTagsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      isCustom: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ContextTagsTable createAlias(String alias) {
    return $ContextTagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContextTagType, String, String> $convertertype =
      const EnumNameConverter<ContextTagType>(ContextTagType.values);
}

class ContextTag extends DataClass implements Insertable<ContextTag> {
  final int id;
  final String name;
  final ContextTagType type;
  final bool isCustom;
  final bool isActive;
  final DateTime updatedAt;
  const ContextTag(
      {required this.id,
      required this.name,
      required this.type,
      required this.isCustom,
      required this.isActive,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] =
          Variable<String>($ContextTagsTable.$convertertype.toSql(type));
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContextTagsCompanion toCompanion(bool nullToAbsent) {
    return ContextTagsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      isCustom: Value(isCustom),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContextTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextTag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $ContextTagsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer
          .toJson<String>($ContextTagsTable.$convertertype.toJson(type)),
      'isCustom': serializer.toJson<bool>(isCustom),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContextTag copyWith(
          {int? id,
          String? name,
          ContextTagType? type,
          bool? isCustom,
          bool? isActive,
          DateTime? updatedAt}) =>
      ContextTag(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        isCustom: isCustom ?? this.isCustom,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('ContextTag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isCustom: $isCustom, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, isCustom, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextTag &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.isCustom == this.isCustom &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ContextTagsCompanion extends UpdateCompanion<ContextTag> {
  final Value<int> id;
  final Value<String> name;
  final Value<ContextTagType> type;
  final Value<bool> isCustom;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  const ContextTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContextTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required ContextTagType type,
    this.isCustom = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<ContextTag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? isCustom,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (isCustom != null) 'is_custom': isCustom,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContextTagsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<ContextTagType>? type,
      Value<bool>? isCustom,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt}) {
    return ContextTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($ContextTagsTable.$convertertype.toSql(type.value));
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isCustom: $isCustom, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MoodEntryTagsTable extends MoodEntryTags
    with TableInfo<$MoodEntryTagsTable, MoodEntryTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _moodEntryIdMeta =
      const VerificationMeta('moodEntryId');
  @override
  late final GeneratedColumn<int> moodEntryId = GeneratedColumn<int>(
      'mood_entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES mood_entries (id)'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES context_tags (id)'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [moodEntryId, tagId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entry_tags';
  @override
  VerificationContext validateIntegrity(Insertable<MoodEntryTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mood_entry_id')) {
      context.handle(
          _moodEntryIdMeta,
          moodEntryId.isAcceptableOrUnknown(
              data['mood_entry_id']!, _moodEntryIdMeta));
    } else if (isInserting) {
      context.missing(_moodEntryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {moodEntryId, tagId};
  @override
  MoodEntryTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntryTag(
      moodEntryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_entry_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MoodEntryTagsTable createAlias(String alias) {
    return $MoodEntryTagsTable(attachedDatabase, alias);
  }
}

class MoodEntryTag extends DataClass implements Insertable<MoodEntryTag> {
  final int moodEntryId;
  final int tagId;
  final DateTime updatedAt;
  const MoodEntryTag(
      {required this.moodEntryId,
      required this.tagId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mood_entry_id'] = Variable<int>(moodEntryId);
    map['tag_id'] = Variable<int>(tagId);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MoodEntryTagsCompanion toCompanion(bool nullToAbsent) {
    return MoodEntryTagsCompanion(
      moodEntryId: Value(moodEntryId),
      tagId: Value(tagId),
      updatedAt: Value(updatedAt),
    );
  }

  factory MoodEntryTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntryTag(
      moodEntryId: serializer.fromJson<int>(json['moodEntryId']),
      tagId: serializer.fromJson<int>(json['tagId']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'moodEntryId': serializer.toJson<int>(moodEntryId),
      'tagId': serializer.toJson<int>(tagId),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MoodEntryTag copyWith({int? moodEntryId, int? tagId, DateTime? updatedAt}) =>
      MoodEntryTag(
        moodEntryId: moodEntryId ?? this.moodEntryId,
        tagId: tagId ?? this.tagId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('MoodEntryTag(')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('tagId: $tagId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(moodEntryId, tagId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntryTag &&
          other.moodEntryId == this.moodEntryId &&
          other.tagId == this.tagId &&
          other.updatedAt == this.updatedAt);
}

class MoodEntryTagsCompanion extends UpdateCompanion<MoodEntryTag> {
  final Value<int> moodEntryId;
  final Value<int> tagId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MoodEntryTagsCompanion({
    this.moodEntryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoodEntryTagsCompanion.insert({
    required int moodEntryId,
    required int tagId,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : moodEntryId = Value(moodEntryId),
        tagId = Value(tagId);
  static Insertable<MoodEntryTag> custom({
    Expression<int>? moodEntryId,
    Expression<int>? tagId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (tagId != null) 'tag_id': tagId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoodEntryTagsCompanion copyWith(
      {Value<int>? moodEntryId,
      Value<int>? tagId,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return MoodEntryTagsCompanion(
      moodEntryId: moodEntryId ?? this.moodEntryId,
      tagId: tagId ?? this.tagId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (moodEntryId.present) {
      map['mood_entry_id'] = Variable<int>(moodEntryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntryTagsCompanion(')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('tagId: $tagId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextDetailsTable extends ContextDetails
    with TableInfo<$ContextDetailsTable, ContextDetail> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _moodEntryIdMeta =
      const VerificationMeta('moodEntryId');
  @override
  late final GeneratedColumn<int> moodEntryId = GeneratedColumn<int>(
      'mood_entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES mood_entries (id)'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _voicePathMeta =
      const VerificationMeta('voicePath');
  @override
  late final GeneratedColumn<String> voicePath = GeneratedColumn<String>(
      'voice_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, moodEntryId, note, voicePath, photoPath, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_details';
  @override
  VerificationContext validateIntegrity(Insertable<ContextDetail> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mood_entry_id')) {
      context.handle(
          _moodEntryIdMeta,
          moodEntryId.isAcceptableOrUnknown(
              data['mood_entry_id']!, _moodEntryIdMeta));
    } else if (isInserting) {
      context.missing(_moodEntryIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('voice_path')) {
      context.handle(_voicePathMeta,
          voicePath.isAcceptableOrUnknown(data['voice_path']!, _voicePathMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextDetail(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      moodEntryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_entry_id'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      voicePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voice_path']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ContextDetailsTable createAlias(String alias) {
    return $ContextDetailsTable(attachedDatabase, alias);
  }
}

class ContextDetail extends DataClass implements Insertable<ContextDetail> {
  final int id;
  final int moodEntryId;
  final String? note;
  final String? voicePath;
  final String? photoPath;
  final DateTime updatedAt;
  const ContextDetail(
      {required this.id,
      required this.moodEntryId,
      this.note,
      this.voicePath,
      this.photoPath,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mood_entry_id'] = Variable<int>(moodEntryId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || voicePath != null) {
      map['voice_path'] = Variable<String>(voicePath);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ContextDetailsCompanion toCompanion(bool nullToAbsent) {
    return ContextDetailsCompanion(
      id: Value(id),
      moodEntryId: Value(moodEntryId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      voicePath: voicePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voicePath),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContextDetail.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextDetail(
      id: serializer.fromJson<int>(json['id']),
      moodEntryId: serializer.fromJson<int>(json['moodEntryId']),
      note: serializer.fromJson<String?>(json['note']),
      voicePath: serializer.fromJson<String?>(json['voicePath']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'moodEntryId': serializer.toJson<int>(moodEntryId),
      'note': serializer.toJson<String?>(note),
      'voicePath': serializer.toJson<String?>(voicePath),
      'photoPath': serializer.toJson<String?>(photoPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ContextDetail copyWith(
          {int? id,
          int? moodEntryId,
          Value<String?> note = const Value.absent(),
          Value<String?> voicePath = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          DateTime? updatedAt}) =>
      ContextDetail(
        id: id ?? this.id,
        moodEntryId: moodEntryId ?? this.moodEntryId,
        note: note.present ? note.value : this.note,
        voicePath: voicePath.present ? voicePath.value : this.voicePath,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('ContextDetail(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('note: $note, ')
          ..write('voicePath: $voicePath, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, moodEntryId, note, voicePath, photoPath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextDetail &&
          other.id == this.id &&
          other.moodEntryId == this.moodEntryId &&
          other.note == this.note &&
          other.voicePath == this.voicePath &&
          other.photoPath == this.photoPath &&
          other.updatedAt == this.updatedAt);
}

class ContextDetailsCompanion extends UpdateCompanion<ContextDetail> {
  final Value<int> id;
  final Value<int> moodEntryId;
  final Value<String?> note;
  final Value<String?> voicePath;
  final Value<String?> photoPath;
  final Value<DateTime> updatedAt;
  const ContextDetailsCompanion({
    this.id = const Value.absent(),
    this.moodEntryId = const Value.absent(),
    this.note = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ContextDetailsCompanion.insert({
    this.id = const Value.absent(),
    required int moodEntryId,
    this.note = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : moodEntryId = Value(moodEntryId);
  static Insertable<ContextDetail> custom({
    Expression<int>? id,
    Expression<int>? moodEntryId,
    Expression<String>? note,
    Expression<String>? voicePath,
    Expression<String>? photoPath,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (note != null) 'note': note,
      if (voicePath != null) 'voice_path': voicePath,
      if (photoPath != null) 'photo_path': photoPath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ContextDetailsCompanion copyWith(
      {Value<int>? id,
      Value<int>? moodEntryId,
      Value<String?>? note,
      Value<String?>? voicePath,
      Value<String?>? photoPath,
      Value<DateTime>? updatedAt}) {
    return ContextDetailsCompanion(
      id: id ?? this.id,
      moodEntryId: moodEntryId ?? this.moodEntryId,
      note: note ?? this.note,
      voicePath: voicePath ?? this.voicePath,
      photoPath: photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (moodEntryId.present) {
      map['mood_entry_id'] = Variable<int>(moodEntryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (voicePath.present) {
      map['voice_path'] = Variable<String>(voicePath.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextDetailsCompanion(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('note: $note, ')
          ..write('voicePath: $voicePath, ')
          ..write('photoPath: $photoPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherDataTable extends WeatherData
    with TableInfo<$WeatherDataTable, WeatherDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _moodEntryIdMeta =
      const VerificationMeta('moodEntryId');
  @override
  late final GeneratedColumn<int> moodEntryId = GeneratedColumn<int>(
      'mood_entry_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES mood_entries (id)'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _temperatureCategoryMeta =
      const VerificationMeta('temperatureCategory');
  @override
  late final GeneratedColumnWithTypeConverter<TemperatureCategory, int>
      temperatureCategory = GeneratedColumn<int>(
              'temperature_category', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TemperatureCategory>(
              $WeatherDataTable.$convertertemperatureCategory);
  static const VerificationMeta _rawTemperatureMeta =
      const VerificationMeta('rawTemperature');
  @override
  late final GeneratedColumn<double> rawTemperature = GeneratedColumn<double>(
      'raw_temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _precipitationMeta =
      const VerificationMeta('precipitation');
  @override
  late final GeneratedColumnWithTypeConverter<PrecipitationType?, int>
      precipitation = GeneratedColumn<int>('precipitation', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<PrecipitationType?>(
              $WeatherDataTable.$converterprecipitationn);
  static const VerificationMeta _cloudinessMeta =
      const VerificationMeta('cloudiness');
  @override
  late final GeneratedColumnWithTypeConverter<Cloudiness?, int> cloudiness =
      GeneratedColumn<int>('cloudiness', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<Cloudiness?>($WeatherDataTable.$convertercloudinessn);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        moodEntryId,
        source,
        temperatureCategory,
        rawTemperature,
        precipitation,
        cloudiness,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_data';
  @override
  VerificationContext validateIntegrity(Insertable<WeatherDataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mood_entry_id')) {
      context.handle(
          _moodEntryIdMeta,
          moodEntryId.isAcceptableOrUnknown(
              data['mood_entry_id']!, _moodEntryIdMeta));
    } else if (isInserting) {
      context.missing(_moodEntryIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    context.handle(
        _temperatureCategoryMeta, const VerificationResult.success());
    if (data.containsKey('raw_temperature')) {
      context.handle(
          _rawTemperatureMeta,
          rawTemperature.isAcceptableOrUnknown(
              data['raw_temperature']!, _rawTemperatureMeta));
    }
    context.handle(_precipitationMeta, const VerificationResult.success());
    context.handle(_cloudinessMeta, const VerificationResult.success());
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherDataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      moodEntryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mood_entry_id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      temperatureCategory: $WeatherDataTable.$convertertemperatureCategory
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int,
              data['${effectivePrefix}temperature_category'])!),
      rawTemperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}raw_temperature']),
      precipitation: $WeatherDataTable.$converterprecipitationn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}precipitation'])),
      cloudiness: $WeatherDataTable.$convertercloudinessn.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}cloudiness'])),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WeatherDataTable createAlias(String alias) {
    return $WeatherDataTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TemperatureCategory, int, int>
      $convertertemperatureCategory =
      const EnumIndexConverter<TemperatureCategory>(TemperatureCategory.values);
  static JsonTypeConverter2<PrecipitationType, int, int>
      $converterprecipitation =
      const EnumIndexConverter<PrecipitationType>(PrecipitationType.values);
  static JsonTypeConverter2<PrecipitationType?, int?, int?>
      $converterprecipitationn =
      JsonTypeConverter2.asNullable($converterprecipitation);
  static JsonTypeConverter2<Cloudiness, int, int> $convertercloudiness =
      const EnumIndexConverter<Cloudiness>(Cloudiness.values);
  static JsonTypeConverter2<Cloudiness?, int?, int?> $convertercloudinessn =
      JsonTypeConverter2.asNullable($convertercloudiness);
}

class WeatherDataData extends DataClass implements Insertable<WeatherDataData> {
  final int id;
  final int moodEntryId;

  /// auto | manual
  final String source;
  final TemperatureCategory temperatureCategory;

  /// числовая температура если api
  final double? rawTemperature;
  final PrecipitationType? precipitation;
  final Cloudiness? cloudiness;
  final DateTime updatedAt;
  const WeatherDataData(
      {required this.id,
      required this.moodEntryId,
      required this.source,
      required this.temperatureCategory,
      this.rawTemperature,
      this.precipitation,
      this.cloudiness,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mood_entry_id'] = Variable<int>(moodEntryId);
    map['source'] = Variable<String>(source);
    {
      map['temperature_category'] = Variable<int>($WeatherDataTable
          .$convertertemperatureCategory
          .toSql(temperatureCategory));
    }
    if (!nullToAbsent || rawTemperature != null) {
      map['raw_temperature'] = Variable<double>(rawTemperature);
    }
    if (!nullToAbsent || precipitation != null) {
      map['precipitation'] = Variable<int>(
          $WeatherDataTable.$converterprecipitationn.toSql(precipitation));
    }
    if (!nullToAbsent || cloudiness != null) {
      map['cloudiness'] = Variable<int>(
          $WeatherDataTable.$convertercloudinessn.toSql(cloudiness));
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WeatherDataCompanion toCompanion(bool nullToAbsent) {
    return WeatherDataCompanion(
      id: Value(id),
      moodEntryId: Value(moodEntryId),
      source: Value(source),
      temperatureCategory: Value(temperatureCategory),
      rawTemperature: rawTemperature == null && nullToAbsent
          ? const Value.absent()
          : Value(rawTemperature),
      precipitation: precipitation == null && nullToAbsent
          ? const Value.absent()
          : Value(precipitation),
      cloudiness: cloudiness == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudiness),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeatherDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherDataData(
      id: serializer.fromJson<int>(json['id']),
      moodEntryId: serializer.fromJson<int>(json['moodEntryId']),
      source: serializer.fromJson<String>(json['source']),
      temperatureCategory: $WeatherDataTable.$convertertemperatureCategory
          .fromJson(serializer.fromJson<int>(json['temperatureCategory'])),
      rawTemperature: serializer.fromJson<double?>(json['rawTemperature']),
      precipitation: $WeatherDataTable.$converterprecipitationn
          .fromJson(serializer.fromJson<int?>(json['precipitation'])),
      cloudiness: $WeatherDataTable.$convertercloudinessn
          .fromJson(serializer.fromJson<int?>(json['cloudiness'])),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'moodEntryId': serializer.toJson<int>(moodEntryId),
      'source': serializer.toJson<String>(source),
      'temperatureCategory': serializer.toJson<int>($WeatherDataTable
          .$convertertemperatureCategory
          .toJson(temperatureCategory)),
      'rawTemperature': serializer.toJson<double?>(rawTemperature),
      'precipitation': serializer.toJson<int?>(
          $WeatherDataTable.$converterprecipitationn.toJson(precipitation)),
      'cloudiness': serializer.toJson<int?>(
          $WeatherDataTable.$convertercloudinessn.toJson(cloudiness)),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WeatherDataData copyWith(
          {int? id,
          int? moodEntryId,
          String? source,
          TemperatureCategory? temperatureCategory,
          Value<double?> rawTemperature = const Value.absent(),
          Value<PrecipitationType?> precipitation = const Value.absent(),
          Value<Cloudiness?> cloudiness = const Value.absent(),
          DateTime? updatedAt}) =>
      WeatherDataData(
        id: id ?? this.id,
        moodEntryId: moodEntryId ?? this.moodEntryId,
        source: source ?? this.source,
        temperatureCategory: temperatureCategory ?? this.temperatureCategory,
        rawTemperature:
            rawTemperature.present ? rawTemperature.value : this.rawTemperature,
        precipitation:
            precipitation.present ? precipitation.value : this.precipitation,
        cloudiness: cloudiness.present ? cloudiness.value : this.cloudiness,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('WeatherDataData(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('source: $source, ')
          ..write('temperatureCategory: $temperatureCategory, ')
          ..write('rawTemperature: $rawTemperature, ')
          ..write('precipitation: $precipitation, ')
          ..write('cloudiness: $cloudiness, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moodEntryId, source, temperatureCategory,
      rawTemperature, precipitation, cloudiness, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherDataData &&
          other.id == this.id &&
          other.moodEntryId == this.moodEntryId &&
          other.source == this.source &&
          other.temperatureCategory == this.temperatureCategory &&
          other.rawTemperature == this.rawTemperature &&
          other.precipitation == this.precipitation &&
          other.cloudiness == this.cloudiness &&
          other.updatedAt == this.updatedAt);
}

class WeatherDataCompanion extends UpdateCompanion<WeatherDataData> {
  final Value<int> id;
  final Value<int> moodEntryId;
  final Value<String> source;
  final Value<TemperatureCategory> temperatureCategory;
  final Value<double?> rawTemperature;
  final Value<PrecipitationType?> precipitation;
  final Value<Cloudiness?> cloudiness;
  final Value<DateTime> updatedAt;
  const WeatherDataCompanion({
    this.id = const Value.absent(),
    this.moodEntryId = const Value.absent(),
    this.source = const Value.absent(),
    this.temperatureCategory = const Value.absent(),
    this.rawTemperature = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.cloudiness = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WeatherDataCompanion.insert({
    this.id = const Value.absent(),
    required int moodEntryId,
    required String source,
    required TemperatureCategory temperatureCategory,
    this.rawTemperature = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.cloudiness = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : moodEntryId = Value(moodEntryId),
        source = Value(source),
        temperatureCategory = Value(temperatureCategory);
  static Insertable<WeatherDataData> custom({
    Expression<int>? id,
    Expression<int>? moodEntryId,
    Expression<String>? source,
    Expression<int>? temperatureCategory,
    Expression<double>? rawTemperature,
    Expression<int>? precipitation,
    Expression<int>? cloudiness,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (source != null) 'source': source,
      if (temperatureCategory != null)
        'temperature_category': temperatureCategory,
      if (rawTemperature != null) 'raw_temperature': rawTemperature,
      if (precipitation != null) 'precipitation': precipitation,
      if (cloudiness != null) 'cloudiness': cloudiness,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WeatherDataCompanion copyWith(
      {Value<int>? id,
      Value<int>? moodEntryId,
      Value<String>? source,
      Value<TemperatureCategory>? temperatureCategory,
      Value<double?>? rawTemperature,
      Value<PrecipitationType?>? precipitation,
      Value<Cloudiness?>? cloudiness,
      Value<DateTime>? updatedAt}) {
    return WeatherDataCompanion(
      id: id ?? this.id,
      moodEntryId: moodEntryId ?? this.moodEntryId,
      source: source ?? this.source,
      temperatureCategory: temperatureCategory ?? this.temperatureCategory,
      rawTemperature: rawTemperature ?? this.rawTemperature,
      precipitation: precipitation ?? this.precipitation,
      cloudiness: cloudiness ?? this.cloudiness,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (moodEntryId.present) {
      map['mood_entry_id'] = Variable<int>(moodEntryId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (temperatureCategory.present) {
      map['temperature_category'] = Variable<int>($WeatherDataTable
          .$convertertemperatureCategory
          .toSql(temperatureCategory.value));
    }
    if (rawTemperature.present) {
      map['raw_temperature'] = Variable<double>(rawTemperature.value);
    }
    if (precipitation.present) {
      map['precipitation'] = Variable<int>($WeatherDataTable
          .$converterprecipitationn
          .toSql(precipitation.value));
    }
    if (cloudiness.present) {
      map['cloudiness'] = Variable<int>(
          $WeatherDataTable.$convertercloudinessn.toSql(cloudiness.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherDataCompanion(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('source: $source, ')
          ..write('temperatureCategory: $temperatureCategory, ')
          ..write('rawTemperature: $rawTemperature, ')
          ..write('precipitation: $precipitation, ')
          ..write('cloudiness: $cloudiness, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HealthDataTable extends HealthData
    with TableInfo<$HealthDataTable, HealthDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _sleepMinutesMeta =
      const VerificationMeta('sleepMinutes');
  @override
  late final GeneratedColumn<int> sleepMinutes = GeneratedColumn<int>(
      'sleep_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stepsAmountMeta =
      const VerificationMeta('stepsAmount');
  @override
  late final GeneratedColumn<int> stepsAmount = GeneratedColumn<int>(
      'steps_amount', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cyclePhaseMeta =
      const VerificationMeta('cyclePhase');
  @override
  late final GeneratedColumnWithTypeConverter<CyclePhase?, String> cyclePhase =
      GeneratedColumn<String>('cycle_phase', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<CyclePhase?>($HealthDataTable.$convertercyclePhasen);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, sleepMinutes, stepsAmount, cyclePhase, source, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_data';
  @override
  VerificationContext validateIntegrity(Insertable<HealthDataData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sleep_minutes')) {
      context.handle(
          _sleepMinutesMeta,
          sleepMinutes.isAcceptableOrUnknown(
              data['sleep_minutes']!, _sleepMinutesMeta));
    }
    if (data.containsKey('steps_amount')) {
      context.handle(
          _stepsAmountMeta,
          stepsAmount.isAcceptableOrUnknown(
              data['steps_amount']!, _stepsAmountMeta));
    }
    context.handle(_cyclePhaseMeta, const VerificationResult.success());
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HealthDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthDataData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      sleepMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sleep_minutes']),
      stepsAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}steps_amount']),
      cyclePhase: $HealthDataTable.$convertercyclePhasen.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}cycle_phase'])),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $HealthDataTable createAlias(String alias) {
    return $HealthDataTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CyclePhase, String, String> $convertercyclePhase =
      const EnumNameConverter<CyclePhase>(CyclePhase.values);
  static JsonTypeConverter2<CyclePhase?, String?, String?>
      $convertercyclePhasen =
      JsonTypeConverter2.asNullable($convertercyclePhase);
}

class HealthDataData extends DataClass implements Insertable<HealthDataData> {
  final int id;
  final DateTime date;
  final int? sleepMinutes;
  final int? stepsAmount;
  final CyclePhase? cyclePhase;
  final String? source;
  final DateTime updatedAt;
  const HealthDataData(
      {required this.id,
      required this.date,
      this.sleepMinutes,
      this.stepsAmount,
      this.cyclePhase,
      this.source,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || sleepMinutes != null) {
      map['sleep_minutes'] = Variable<int>(sleepMinutes);
    }
    if (!nullToAbsent || stepsAmount != null) {
      map['steps_amount'] = Variable<int>(stepsAmount);
    }
    if (!nullToAbsent || cyclePhase != null) {
      map['cycle_phase'] = Variable<String>(
          $HealthDataTable.$convertercyclePhasen.toSql(cyclePhase));
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HealthDataCompanion toCompanion(bool nullToAbsent) {
    return HealthDataCompanion(
      id: Value(id),
      date: Value(date),
      sleepMinutes: sleepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepMinutes),
      stepsAmount: stepsAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(stepsAmount),
      cyclePhase: cyclePhase == null && nullToAbsent
          ? const Value.absent()
          : Value(cyclePhase),
      source:
          source == null && nullToAbsent ? const Value.absent() : Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory HealthDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthDataData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      sleepMinutes: serializer.fromJson<int?>(json['sleepMinutes']),
      stepsAmount: serializer.fromJson<int?>(json['stepsAmount']),
      cyclePhase: $HealthDataTable.$convertercyclePhasen
          .fromJson(serializer.fromJson<String?>(json['cyclePhase'])),
      source: serializer.fromJson<String?>(json['source']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'sleepMinutes': serializer.toJson<int?>(sleepMinutes),
      'stepsAmount': serializer.toJson<int?>(stepsAmount),
      'cyclePhase': serializer.toJson<String?>(
          $HealthDataTable.$convertercyclePhasen.toJson(cyclePhase)),
      'source': serializer.toJson<String?>(source),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HealthDataData copyWith(
          {int? id,
          DateTime? date,
          Value<int?> sleepMinutes = const Value.absent(),
          Value<int?> stepsAmount = const Value.absent(),
          Value<CyclePhase?> cyclePhase = const Value.absent(),
          Value<String?> source = const Value.absent(),
          DateTime? updatedAt}) =>
      HealthDataData(
        id: id ?? this.id,
        date: date ?? this.date,
        sleepMinutes:
            sleepMinutes.present ? sleepMinutes.value : this.sleepMinutes,
        stepsAmount: stepsAmount.present ? stepsAmount.value : this.stepsAmount,
        cyclePhase: cyclePhase.present ? cyclePhase.value : this.cyclePhase,
        source: source.present ? source.value : this.source,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('HealthDataData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sleepMinutes: $sleepMinutes, ')
          ..write('stepsAmount: $stepsAmount, ')
          ..write('cyclePhase: $cyclePhase, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, sleepMinutes, stepsAmount, cyclePhase, source, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthDataData &&
          other.id == this.id &&
          other.date == this.date &&
          other.sleepMinutes == this.sleepMinutes &&
          other.stepsAmount == this.stepsAmount &&
          other.cyclePhase == this.cyclePhase &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class HealthDataCompanion extends UpdateCompanion<HealthDataData> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int?> sleepMinutes;
  final Value<int?> stepsAmount;
  final Value<CyclePhase?> cyclePhase;
  final Value<String?> source;
  final Value<DateTime> updatedAt;
  const HealthDataCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.sleepMinutes = const Value.absent(),
    this.stepsAmount = const Value.absent(),
    this.cyclePhase = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  HealthDataCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.sleepMinutes = const Value.absent(),
    this.stepsAmount = const Value.absent(),
    this.cyclePhase = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<HealthDataData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? sleepMinutes,
    Expression<int>? stepsAmount,
    Expression<String>? cyclePhase,
    Expression<String>? source,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (sleepMinutes != null) 'sleep_minutes': sleepMinutes,
      if (stepsAmount != null) 'steps_amount': stepsAmount,
      if (cyclePhase != null) 'cycle_phase': cyclePhase,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  HealthDataCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int?>? sleepMinutes,
      Value<int?>? stepsAmount,
      Value<CyclePhase?>? cyclePhase,
      Value<String?>? source,
      Value<DateTime>? updatedAt}) {
    return HealthDataCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      stepsAmount: stepsAmount ?? this.stepsAmount,
      cyclePhase: cyclePhase ?? this.cyclePhase,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (sleepMinutes.present) {
      map['sleep_minutes'] = Variable<int>(sleepMinutes.value);
    }
    if (stepsAmount.present) {
      map['steps_amount'] = Variable<int>(stepsAmount.value);
    }
    if (cyclePhase.present) {
      map['cycle_phase'] = Variable<String>(
          $HealthDataTable.$convertercyclePhasen.toSql(cyclePhase.value));
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthDataCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sleepMinutes: $sleepMinutes, ')
          ..write('stepsAmount: $stepsAmount, ')
          ..write('cyclePhase: $cyclePhase, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyMoodStatsTable extends DailyMoodStats
    with TableInfo<$DailyMoodStatsTable, DailyMoodStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyMoodStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _avgXMeta = const VerificationMeta('avgX');
  @override
  late final GeneratedColumn<double> avgX = GeneratedColumn<double>(
      'avg_x', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgYMeta = const VerificationMeta('avgY');
  @override
  late final GeneratedColumn<double> avgY = GeneratedColumn<double>(
      'avg_y', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _moodValueMeta =
      const VerificationMeta('moodValue');
  @override
  late final GeneratedColumn<double> moodValue = GeneratedColumn<double>(
      'mood_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dayTypeMeta =
      const VerificationMeta('dayType');
  @override
  late final GeneratedColumn<String> dayType = GeneratedColumn<String>(
      'day_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, avgX, avgY, moodValue, dayType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_mood_stats';
  @override
  VerificationContext validateIntegrity(Insertable<DailyMoodStat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('avg_x')) {
      context.handle(
          _avgXMeta, avgX.isAcceptableOrUnknown(data['avg_x']!, _avgXMeta));
    } else if (isInserting) {
      context.missing(_avgXMeta);
    }
    if (data.containsKey('avg_y')) {
      context.handle(
          _avgYMeta, avgY.isAcceptableOrUnknown(data['avg_y']!, _avgYMeta));
    } else if (isInserting) {
      context.missing(_avgYMeta);
    }
    if (data.containsKey('mood_value')) {
      context.handle(_moodValueMeta,
          moodValue.isAcceptableOrUnknown(data['mood_value']!, _moodValueMeta));
    } else if (isInserting) {
      context.missing(_moodValueMeta);
    }
    if (data.containsKey('day_type')) {
      context.handle(_dayTypeMeta,
          dayType.isAcceptableOrUnknown(data['day_type']!, _dayTypeMeta));
    } else if (isInserting) {
      context.missing(_dayTypeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyMoodStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyMoodStat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      avgX: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_x'])!,
      avgY: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_y'])!,
      moodValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}mood_value'])!,
      dayType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day_type'])!,
    );
  }

  @override
  $DailyMoodStatsTable createAlias(String alias) {
    return $DailyMoodStatsTable(attachedDatabase, alias);
  }
}

class DailyMoodStat extends DataClass implements Insertable<DailyMoodStat> {
  final int id;
  final DateTime date;
  final double avgX;
  final double avgY;
  final double moodValue;
  final String dayType;
  const DailyMoodStat(
      {required this.id,
      required this.date,
      required this.avgX,
      required this.avgY,
      required this.moodValue,
      required this.dayType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['avg_x'] = Variable<double>(avgX);
    map['avg_y'] = Variable<double>(avgY);
    map['mood_value'] = Variable<double>(moodValue);
    map['day_type'] = Variable<String>(dayType);
    return map;
  }

  DailyMoodStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyMoodStatsCompanion(
      id: Value(id),
      date: Value(date),
      avgX: Value(avgX),
      avgY: Value(avgY),
      moodValue: Value(moodValue),
      dayType: Value(dayType),
    );
  }

  factory DailyMoodStat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyMoodStat(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      avgX: serializer.fromJson<double>(json['avgX']),
      avgY: serializer.fromJson<double>(json['avgY']),
      moodValue: serializer.fromJson<double>(json['moodValue']),
      dayType: serializer.fromJson<String>(json['dayType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'avgX': serializer.toJson<double>(avgX),
      'avgY': serializer.toJson<double>(avgY),
      'moodValue': serializer.toJson<double>(moodValue),
      'dayType': serializer.toJson<String>(dayType),
    };
  }

  DailyMoodStat copyWith(
          {int? id,
          DateTime? date,
          double? avgX,
          double? avgY,
          double? moodValue,
          String? dayType}) =>
      DailyMoodStat(
        id: id ?? this.id,
        date: date ?? this.date,
        avgX: avgX ?? this.avgX,
        avgY: avgY ?? this.avgY,
        moodValue: moodValue ?? this.moodValue,
        dayType: dayType ?? this.dayType,
      );
  @override
  String toString() {
    return (StringBuffer('DailyMoodStat(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('avgX: $avgX, ')
          ..write('avgY: $avgY, ')
          ..write('moodValue: $moodValue, ')
          ..write('dayType: $dayType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, avgX, avgY, moodValue, dayType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyMoodStat &&
          other.id == this.id &&
          other.date == this.date &&
          other.avgX == this.avgX &&
          other.avgY == this.avgY &&
          other.moodValue == this.moodValue &&
          other.dayType == this.dayType);
}

class DailyMoodStatsCompanion extends UpdateCompanion<DailyMoodStat> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> avgX;
  final Value<double> avgY;
  final Value<double> moodValue;
  final Value<String> dayType;
  const DailyMoodStatsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.avgX = const Value.absent(),
    this.avgY = const Value.absent(),
    this.moodValue = const Value.absent(),
    this.dayType = const Value.absent(),
  });
  DailyMoodStatsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double avgX,
    required double avgY,
    required double moodValue,
    required String dayType,
  })  : date = Value(date),
        avgX = Value(avgX),
        avgY = Value(avgY),
        moodValue = Value(moodValue),
        dayType = Value(dayType);
  static Insertable<DailyMoodStat> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? avgX,
    Expression<double>? avgY,
    Expression<double>? moodValue,
    Expression<String>? dayType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (avgX != null) 'avg_x': avgX,
      if (avgY != null) 'avg_y': avgY,
      if (moodValue != null) 'mood_value': moodValue,
      if (dayType != null) 'day_type': dayType,
    });
  }

  DailyMoodStatsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<double>? avgX,
      Value<double>? avgY,
      Value<double>? moodValue,
      Value<String>? dayType}) {
    return DailyMoodStatsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      avgX: avgX ?? this.avgX,
      avgY: avgY ?? this.avgY,
      moodValue: moodValue ?? this.moodValue,
      dayType: dayType ?? this.dayType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (avgX.present) {
      map['avg_x'] = Variable<double>(avgX.value);
    }
    if (avgY.present) {
      map['avg_y'] = Variable<double>(avgY.value);
    }
    if (moodValue.present) {
      map['mood_value'] = Variable<double>(moodValue.value);
    }
    if (dayType.present) {
      map['day_type'] = Variable<String>(dayType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyMoodStatsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('avgX: $avgX, ')
          ..write('avgY: $avgY, ')
          ..write('moodValue: $moodValue, ')
          ..write('dayType: $dayType')
          ..write(')'))
        .toString();
  }
}

class $UserAchievementsTable extends UserAchievements
    with TableInfo<$UserAchievementsTable, UserAchievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _achievementIdMeta =
      const VerificationMeta('achievementId');
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
      'achievement_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isAchievedMeta =
      const VerificationMeta('isAchieved');
  @override
  late final GeneratedColumn<bool> isAchieved = GeneratedColumn<bool>(
      'is_achieved', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_achieved" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _achievedAtMeta =
      const VerificationMeta('achievedAt');
  @override
  late final GeneratedColumn<DateTime> achievedAt = GeneratedColumn<DateTime>(
      'achieved_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [achievementId, userId, isAchieved, achievedAt, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_achievements';
  @override
  VerificationContext validateIntegrity(Insertable<UserAchievement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('achievement_id')) {
      context.handle(
          _achievementIdMeta,
          achievementId.isAcceptableOrUnknown(
              data['achievement_id']!, _achievementIdMeta));
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('is_achieved')) {
      context.handle(
          _isAchievedMeta,
          isAchieved.isAcceptableOrUnknown(
              data['is_achieved']!, _isAchievedMeta));
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
          _achievedAtMeta,
          achievedAt.isAcceptableOrUnknown(
              data['achieved_at']!, _achievedAtMeta));
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, achievementId};
  @override
  UserAchievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAchievement(
      achievementId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}achievement_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      isAchieved: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_achieved'])!,
      achievedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}achieved_at']),
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
    );
  }

  @override
  $UserAchievementsTable createAlias(String alias) {
    return $UserAchievementsTable(attachedDatabase, alias);
  }
}

class UserAchievement extends DataClass implements Insertable<UserAchievement> {
  final String achievementId;
  final String userId;
  final bool isAchieved;
  final DateTime? achievedAt;
  final bool synced;
  const UserAchievement(
      {required this.achievementId,
      required this.userId,
      required this.isAchieved,
      this.achievedAt,
      required this.synced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['achievement_id'] = Variable<String>(achievementId);
    map['user_id'] = Variable<String>(userId);
    map['is_achieved'] = Variable<bool>(isAchieved);
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<DateTime>(achievedAt);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  UserAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UserAchievementsCompanion(
      achievementId: Value(achievementId),
      userId: Value(userId),
      isAchieved: Value(isAchieved),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
      synced: Value(synced),
    );
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAchievement(
      achievementId: serializer.fromJson<String>(json['achievementId']),
      userId: serializer.fromJson<String>(json['userId']),
      isAchieved: serializer.fromJson<bool>(json['isAchieved']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'achievementId': serializer.toJson<String>(achievementId),
      'userId': serializer.toJson<String>(userId),
      'isAchieved': serializer.toJson<bool>(isAchieved),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  UserAchievement copyWith(
          {String? achievementId,
          String? userId,
          bool? isAchieved,
          Value<DateTime?> achievedAt = const Value.absent(),
          bool? synced}) =>
      UserAchievement(
        achievementId: achievementId ?? this.achievementId,
        userId: userId ?? this.userId,
        isAchieved: isAchieved ?? this.isAchieved,
        achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
        synced: synced ?? this.synced,
      );
  @override
  String toString() {
    return (StringBuffer('UserAchievement(')
          ..write('achievementId: $achievementId, ')
          ..write('userId: $userId, ')
          ..write('isAchieved: $isAchieved, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(achievementId, userId, isAchieved, achievedAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAchievement &&
          other.achievementId == this.achievementId &&
          other.userId == this.userId &&
          other.isAchieved == this.isAchieved &&
          other.achievedAt == this.achievedAt &&
          other.synced == this.synced);
}

class UserAchievementsCompanion extends UpdateCompanion<UserAchievement> {
  final Value<String> achievementId;
  final Value<String> userId;
  final Value<bool> isAchieved;
  final Value<DateTime?> achievedAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const UserAchievementsCompanion({
    this.achievementId = const Value.absent(),
    this.userId = const Value.absent(),
    this.isAchieved = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserAchievementsCompanion.insert({
    required String achievementId,
    required String userId,
    this.isAchieved = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : achievementId = Value(achievementId),
        userId = Value(userId);
  static Insertable<UserAchievement> custom({
    Expression<String>? achievementId,
    Expression<String>? userId,
    Expression<bool>? isAchieved,
    Expression<DateTime>? achievedAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (achievementId != null) 'achievement_id': achievementId,
      if (userId != null) 'user_id': userId,
      if (isAchieved != null) 'is_achieved': isAchieved,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserAchievementsCompanion copyWith(
      {Value<String>? achievementId,
      Value<String>? userId,
      Value<bool>? isAchieved,
      Value<DateTime?>? achievedAt,
      Value<bool>? synced,
      Value<int>? rowid}) {
    return UserAchievementsCompanion(
      achievementId: achievementId ?? this.achievementId,
      userId: userId ?? this.userId,
      isAchieved: isAchieved ?? this.isAchieved,
      achievedAt: achievedAt ?? this.achievedAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (isAchieved.present) {
      map['is_achieved'] = Variable<bool>(isAchieved.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<DateTime>(achievedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAchievementsCompanion(')
          ..write('achievementId: $achievementId, ')
          ..write('userId: $userId, ')
          ..write('isAchieved: $isAchieved, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $MoodsTable moods = $MoodsTable(this);
  late final $MoodEntriesTable moodEntries = $MoodEntriesTable(this);
  late final $ContextTagsTable contextTags = $ContextTagsTable(this);
  late final $MoodEntryTagsTable moodEntryTags = $MoodEntryTagsTable(this);
  late final $ContextDetailsTable contextDetails = $ContextDetailsTable(this);
  late final $WeatherDataTable weatherData = $WeatherDataTable(this);
  late final $HealthDataTable healthData = $HealthDataTable(this);
  late final $DailyMoodStatsTable dailyMoodStats = $DailyMoodStatsTable(this);
  late final $UserAchievementsTable userAchievements =
      $UserAchievementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        moods,
        moodEntries,
        contextTags,
        moodEntryTags,
        contextDetails,
        weatherData,
        healthData,
        dailyMoodStats,
        userAchievements
      ];
}
