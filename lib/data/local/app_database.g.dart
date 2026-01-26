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
  @override
  List<GeneratedColumn> get $columns => [id, userId, moodId, createdAt];
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
  const MoodEntry(
      {required this.id,
      required this.userId,
      required this.moodId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['mood_id'] = Variable<int>(moodId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      moodId: Value(moodId),
      createdAt: Value(createdAt),
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
    };
  }

  MoodEntry copyWith(
          {int? id, String? userId, int? moodId, DateTime? createdAt}) =>
      MoodEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        moodId: moodId ?? this.moodId,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('MoodEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, moodId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.moodId == this.moodId &&
          other.createdAt == this.createdAt);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntry> {
  final Value<int> id;
  final Value<String> userId;
  final Value<int> moodId;
  final Value<DateTime> createdAt;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.moodId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required int moodId,
    this.createdAt = const Value.absent(),
  })  : userId = Value(userId),
        moodId = Value(moodId);
  static Insertable<MoodEntry> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<int>? moodId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (moodId != null) 'mood_id': moodId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MoodEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<int>? moodId,
      Value<DateTime>? createdAt}) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      moodId: moodId ?? this.moodId,
      createdAt: createdAt ?? this.createdAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('moodId: $moodId, ')
          ..write('createdAt: $createdAt')
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
  @override
  List<GeneratedColumn> get $columns => [id, name, type, isCustom, isActive];
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
  const ContextTag(
      {required this.id,
      required this.name,
      required this.type,
      required this.isCustom,
      required this.isActive});
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
    return map;
  }

  ContextTagsCompanion toCompanion(bool nullToAbsent) {
    return ContextTagsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      isCustom: Value(isCustom),
      isActive: Value(isActive),
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
    };
  }

  ContextTag copyWith(
          {int? id,
          String? name,
          ContextTagType? type,
          bool? isCustom,
          bool? isActive}) =>
      ContextTag(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        isCustom: isCustom ?? this.isCustom,
        isActive: isActive ?? this.isActive,
      );
  @override
  String toString() {
    return (StringBuffer('ContextTag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isCustom: $isCustom, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, isCustom, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextTag &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.isCustom == this.isCustom &&
          other.isActive == this.isActive);
}

class ContextTagsCompanion extends UpdateCompanion<ContextTag> {
  final Value<int> id;
  final Value<String> name;
  final Value<ContextTagType> type;
  final Value<bool> isCustom;
  final Value<bool> isActive;
  const ContextTagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  ContextTagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required ContextTagType type,
    this.isCustom = const Value.absent(),
    this.isActive = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<ContextTag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? isCustom,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (isCustom != null) 'is_custom': isCustom,
      if (isActive != null) 'is_active': isActive,
    });
  }

  ContextTagsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<ContextTagType>? type,
      Value<bool>? isCustom,
      Value<bool>? isActive}) {
    return ContextTagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextTagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isCustom: $isCustom, ')
          ..write('isActive: $isActive')
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
  @override
  List<GeneratedColumn> get $columns => [moodEntryId, tagId];
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
  const MoodEntryTag({required this.moodEntryId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mood_entry_id'] = Variable<int>(moodEntryId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  MoodEntryTagsCompanion toCompanion(bool nullToAbsent) {
    return MoodEntryTagsCompanion(
      moodEntryId: Value(moodEntryId),
      tagId: Value(tagId),
    );
  }

  factory MoodEntryTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntryTag(
      moodEntryId: serializer.fromJson<int>(json['moodEntryId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'moodEntryId': serializer.toJson<int>(moodEntryId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  MoodEntryTag copyWith({int? moodEntryId, int? tagId}) => MoodEntryTag(
        moodEntryId: moodEntryId ?? this.moodEntryId,
        tagId: tagId ?? this.tagId,
      );
  @override
  String toString() {
    return (StringBuffer('MoodEntryTag(')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(moodEntryId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntryTag &&
          other.moodEntryId == this.moodEntryId &&
          other.tagId == this.tagId);
}

class MoodEntryTagsCompanion extends UpdateCompanion<MoodEntryTag> {
  final Value<int> moodEntryId;
  final Value<int> tagId;
  final Value<int> rowid;
  const MoodEntryTagsCompanion({
    this.moodEntryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoodEntryTagsCompanion.insert({
    required int moodEntryId,
    required int tagId,
    this.rowid = const Value.absent(),
  })  : moodEntryId = Value(moodEntryId),
        tagId = Value(tagId);
  static Insertable<MoodEntryTag> custom({
    Expression<int>? moodEntryId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoodEntryTagsCompanion copyWith(
      {Value<int>? moodEntryId, Value<int>? tagId, Value<int>? rowid}) {
    return MoodEntryTagsCompanion(
      moodEntryId: moodEntryId ?? this.moodEntryId,
      tagId: tagId ?? this.tagId,
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, moodEntryId, note, voicePath, photoPath];
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
  const ContextDetail(
      {required this.id,
      required this.moodEntryId,
      this.note,
      this.voicePath,
      this.photoPath});
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
    };
  }

  ContextDetail copyWith(
          {int? id,
          int? moodEntryId,
          Value<String?> note = const Value.absent(),
          Value<String?> voicePath = const Value.absent(),
          Value<String?> photoPath = const Value.absent()}) =>
      ContextDetail(
        id: id ?? this.id,
        moodEntryId: moodEntryId ?? this.moodEntryId,
        note: note.present ? note.value : this.note,
        voicePath: voicePath.present ? voicePath.value : this.voicePath,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
      );
  @override
  String toString() {
    return (StringBuffer('ContextDetail(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('note: $note, ')
          ..write('voicePath: $voicePath, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moodEntryId, note, voicePath, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextDetail &&
          other.id == this.id &&
          other.moodEntryId == this.moodEntryId &&
          other.note == this.note &&
          other.voicePath == this.voicePath &&
          other.photoPath == this.photoPath);
}

class ContextDetailsCompanion extends UpdateCompanion<ContextDetail> {
  final Value<int> id;
  final Value<int> moodEntryId;
  final Value<String?> note;
  final Value<String?> voicePath;
  final Value<String?> photoPath;
  const ContextDetailsCompanion({
    this.id = const Value.absent(),
    this.moodEntryId = const Value.absent(),
    this.note = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.photoPath = const Value.absent(),
  });
  ContextDetailsCompanion.insert({
    this.id = const Value.absent(),
    required int moodEntryId,
    this.note = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.photoPath = const Value.absent(),
  }) : moodEntryId = Value(moodEntryId);
  static Insertable<ContextDetail> custom({
    Expression<int>? id,
    Expression<int>? moodEntryId,
    Expression<String>? note,
    Expression<String>? voicePath,
    Expression<String>? photoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (note != null) 'note': note,
      if (voicePath != null) 'voice_path': voicePath,
      if (photoPath != null) 'photo_path': photoPath,
    });
  }

  ContextDetailsCompanion copyWith(
      {Value<int>? id,
      Value<int>? moodEntryId,
      Value<String?>? note,
      Value<String?>? voicePath,
      Value<String?>? photoPath}) {
    return ContextDetailsCompanion(
      id: id ?? this.id,
      moodEntryId: moodEntryId ?? this.moodEntryId,
      note: note ?? this.note,
      voicePath: voicePath ?? this.voicePath,
      photoPath: photoPath ?? this.photoPath,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextDetailsCompanion(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('note: $note, ')
          ..write('voicePath: $voicePath, ')
          ..write('photoPath: $photoPath')
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
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _conditionMeta =
      const VerificationMeta('condition');
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
      'condition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, moodEntryId, temperature, condition];
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
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('condition')) {
      context.handle(_conditionMeta,
          condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta));
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
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature']),
      condition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}condition']),
    );
  }

  @override
  $WeatherDataTable createAlias(String alias) {
    return $WeatherDataTable(attachedDatabase, alias);
  }
}

class WeatherDataData extends DataClass implements Insertable<WeatherDataData> {
  final int id;
  final int moodEntryId;
  final double? temperature;
  final String? condition;
  const WeatherDataData(
      {required this.id,
      required this.moodEntryId,
      this.temperature,
      this.condition});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['mood_entry_id'] = Variable<int>(moodEntryId);
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    return map;
  }

  WeatherDataCompanion toCompanion(bool nullToAbsent) {
    return WeatherDataCompanion(
      id: Value(id),
      moodEntryId: Value(moodEntryId),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
    );
  }

  factory WeatherDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherDataData(
      id: serializer.fromJson<int>(json['id']),
      moodEntryId: serializer.fromJson<int>(json['moodEntryId']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      condition: serializer.fromJson<String?>(json['condition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'moodEntryId': serializer.toJson<int>(moodEntryId),
      'temperature': serializer.toJson<double?>(temperature),
      'condition': serializer.toJson<String?>(condition),
    };
  }

  WeatherDataData copyWith(
          {int? id,
          int? moodEntryId,
          Value<double?> temperature = const Value.absent(),
          Value<String?> condition = const Value.absent()}) =>
      WeatherDataData(
        id: id ?? this.id,
        moodEntryId: moodEntryId ?? this.moodEntryId,
        temperature: temperature.present ? temperature.value : this.temperature,
        condition: condition.present ? condition.value : this.condition,
      );
  @override
  String toString() {
    return (StringBuffer('WeatherDataData(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('temperature: $temperature, ')
          ..write('condition: $condition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moodEntryId, temperature, condition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherDataData &&
          other.id == this.id &&
          other.moodEntryId == this.moodEntryId &&
          other.temperature == this.temperature &&
          other.condition == this.condition);
}

class WeatherDataCompanion extends UpdateCompanion<WeatherDataData> {
  final Value<int> id;
  final Value<int> moodEntryId;
  final Value<double?> temperature;
  final Value<String?> condition;
  const WeatherDataCompanion({
    this.id = const Value.absent(),
    this.moodEntryId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.condition = const Value.absent(),
  });
  WeatherDataCompanion.insert({
    this.id = const Value.absent(),
    required int moodEntryId,
    this.temperature = const Value.absent(),
    this.condition = const Value.absent(),
  }) : moodEntryId = Value(moodEntryId);
  static Insertable<WeatherDataData> custom({
    Expression<int>? id,
    Expression<int>? moodEntryId,
    Expression<double>? temperature,
    Expression<String>? condition,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moodEntryId != null) 'mood_entry_id': moodEntryId,
      if (temperature != null) 'temperature': temperature,
      if (condition != null) 'condition': condition,
    });
  }

  WeatherDataCompanion copyWith(
      {Value<int>? id,
      Value<int>? moodEntryId,
      Value<double?>? temperature,
      Value<String?>? condition}) {
    return WeatherDataCompanion(
      id: id ?? this.id,
      moodEntryId: moodEntryId ?? this.moodEntryId,
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
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
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherDataCompanion(')
          ..write('id: $id, ')
          ..write('moodEntryId: $moodEntryId, ')
          ..write('temperature: $temperature, ')
          ..write('condition: $condition')
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
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sleepHoursMeta =
      const VerificationMeta('sleepHours');
  @override
  late final GeneratedColumn<double> sleepHours = GeneratedColumn<double>(
      'sleep_hours', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _activityLevelMeta =
      const VerificationMeta('activityLevel');
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel?, String>
      activityLevel = GeneratedColumn<String>(
              'activity_level', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<ActivityLevel?>(
              $HealthDataTable.$converteractivityLeveln);
  static const VerificationMeta _cycleDayMeta =
      const VerificationMeta('cycleDay');
  @override
  late final GeneratedColumn<int> cycleDay = GeneratedColumn<int>(
      'cycle_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, sleepHours, activityLevel, cycleDay];
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
    if (data.containsKey('sleep_hours')) {
      context.handle(
          _sleepHoursMeta,
          sleepHours.isAcceptableOrUnknown(
              data['sleep_hours']!, _sleepHoursMeta));
    }
    context.handle(_activityLevelMeta, const VerificationResult.success());
    if (data.containsKey('cycle_day')) {
      context.handle(_cycleDayMeta,
          cycleDay.isAcceptableOrUnknown(data['cycle_day']!, _cycleDayMeta));
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
      sleepHours: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sleep_hours']),
      activityLevel: $HealthDataTable.$converteractivityLeveln.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}activity_level'])),
      cycleDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cycle_day']),
    );
  }

  @override
  $HealthDataTable createAlias(String alias) {
    return $HealthDataTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ActivityLevel, String, String>
      $converteractivityLevel =
      const EnumNameConverter<ActivityLevel>(ActivityLevel.values);
  static JsonTypeConverter2<ActivityLevel?, String?, String?>
      $converteractivityLeveln =
      JsonTypeConverter2.asNullable($converteractivityLevel);
}

class HealthDataData extends DataClass implements Insertable<HealthDataData> {
  final int id;
  final DateTime date;
  final double? sleepHours;
  final ActivityLevel? activityLevel;
  final int? cycleDay;
  const HealthDataData(
      {required this.id,
      required this.date,
      this.sleepHours,
      this.activityLevel,
      this.cycleDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || sleepHours != null) {
      map['sleep_hours'] = Variable<double>(sleepHours);
    }
    if (!nullToAbsent || activityLevel != null) {
      map['activity_level'] = Variable<String>(
          $HealthDataTable.$converteractivityLeveln.toSql(activityLevel));
    }
    if (!nullToAbsent || cycleDay != null) {
      map['cycle_day'] = Variable<int>(cycleDay);
    }
    return map;
  }

  HealthDataCompanion toCompanion(bool nullToAbsent) {
    return HealthDataCompanion(
      id: Value(id),
      date: Value(date),
      sleepHours: sleepHours == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepHours),
      activityLevel: activityLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(activityLevel),
      cycleDay: cycleDay == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleDay),
    );
  }

  factory HealthDataData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthDataData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      sleepHours: serializer.fromJson<double?>(json['sleepHours']),
      activityLevel: $HealthDataTable.$converteractivityLeveln
          .fromJson(serializer.fromJson<String?>(json['activityLevel'])),
      cycleDay: serializer.fromJson<int?>(json['cycleDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'sleepHours': serializer.toJson<double?>(sleepHours),
      'activityLevel': serializer.toJson<String?>(
          $HealthDataTable.$converteractivityLeveln.toJson(activityLevel)),
      'cycleDay': serializer.toJson<int?>(cycleDay),
    };
  }

  HealthDataData copyWith(
          {int? id,
          DateTime? date,
          Value<double?> sleepHours = const Value.absent(),
          Value<ActivityLevel?> activityLevel = const Value.absent(),
          Value<int?> cycleDay = const Value.absent()}) =>
      HealthDataData(
        id: id ?? this.id,
        date: date ?? this.date,
        sleepHours: sleepHours.present ? sleepHours.value : this.sleepHours,
        activityLevel:
            activityLevel.present ? activityLevel.value : this.activityLevel,
        cycleDay: cycleDay.present ? cycleDay.value : this.cycleDay,
      );
  @override
  String toString() {
    return (StringBuffer('HealthDataData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('cycleDay: $cycleDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, sleepHours, activityLevel, cycleDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthDataData &&
          other.id == this.id &&
          other.date == this.date &&
          other.sleepHours == this.sleepHours &&
          other.activityLevel == this.activityLevel &&
          other.cycleDay == this.cycleDay);
}

class HealthDataCompanion extends UpdateCompanion<HealthDataData> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double?> sleepHours;
  final Value<ActivityLevel?> activityLevel;
  final Value<int?> cycleDay;
  const HealthDataCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.sleepHours = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.cycleDay = const Value.absent(),
  });
  HealthDataCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.sleepHours = const Value.absent(),
    this.activityLevel = const Value.absent(),
    this.cycleDay = const Value.absent(),
  }) : date = Value(date);
  static Insertable<HealthDataData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? sleepHours,
    Expression<String>? activityLevel,
    Expression<int>? cycleDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (cycleDay != null) 'cycle_day': cycleDay,
    });
  }

  HealthDataCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<double?>? sleepHours,
      Value<ActivityLevel?>? activityLevel,
      Value<int?>? cycleDay}) {
    return HealthDataCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      sleepHours: sleepHours ?? this.sleepHours,
      activityLevel: activityLevel ?? this.activityLevel,
      cycleDay: cycleDay ?? this.cycleDay,
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
    if (sleepHours.present) {
      map['sleep_hours'] = Variable<double>(sleepHours.value);
    }
    if (activityLevel.present) {
      map['activity_level'] = Variable<String>(
          $HealthDataTable.$converteractivityLeveln.toSql(activityLevel.value));
    }
    if (cycleDay.present) {
      map['cycle_day'] = Variable<int>(cycleDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthDataCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sleepHours: $sleepHours, ')
          ..write('activityLevel: $activityLevel, ')
          ..write('cycleDay: $cycleDay')
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
        dailyMoodStats
      ];
}
