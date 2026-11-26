// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValueLocalTable extends KeyValueLocal with TableInfo<$KeyValueLocalTable, KeyValueLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueLocalTable(this.attachedDatabase, [this._alias]);
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
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value';
  @override
  VerificationContext validateIntegrity(Insertable<KeyValueLocalData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueLocalData(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KeyValueLocalTable createAlias(String alias) {
    return $KeyValueLocalTable(attachedDatabase, alias);
  }
}

class KeyValueLocalData extends DataClass implements Insertable<KeyValueLocalData> {
  final String key;
  final String value;
  const KeyValueLocalData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueLocalCompanion toCompanion(bool nullToAbsent) {
    return KeyValueLocalCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueLocalData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueLocalData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  KeyValueLocalData copyWith({String? key, String? value}) =>
      KeyValueLocalData(key: key ?? this.key, value: value ?? this.value);
  KeyValueLocalData copyWithCompanion(KeyValueLocalCompanion data) {
    return KeyValueLocalData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueLocalData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KeyValueLocalData && other.key == this.key && other.value == this.value);
}

class KeyValueLocalCompanion extends UpdateCompanion<KeyValueLocalData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueLocalCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueLocalCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<KeyValueLocalData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueLocalCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KeyValueLocalCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
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
    return (StringBuffer('KeyValueLocalCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ErrorLogLocalTable extends ErrorLogLocal with TableInfo<$ErrorLogLocalTable, ErrorLogLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ErrorLogLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta('message');
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shownMeta = const VerificationMeta('shown');
  @override
  late final GeneratedColumn<bool> shown = GeneratedColumn<bool>(
    'shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("shown" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, action, source, message, error, shown];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'error_log';
  @override
  VerificationContext validateIntegrity(Insertable<ErrorLogLocalData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta, action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta, message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('error')) {
      context.handle(_errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('shown')) {
      context.handle(_shownMeta, shown.isAcceptableOrUnknown(data['shown']!, _shownMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ErrorLogLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ErrorLogLocalData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      action: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}action']),
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source']),
      message: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}message'])!,
      error: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error']),
      shown: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}shown'])!,
    );
  }

  @override
  $ErrorLogLocalTable createAlias(String alias) {
    return $ErrorLogLocalTable(attachedDatabase, alias);
  }
}

class ErrorLogLocalData extends DataClass implements Insertable<ErrorLogLocalData> {
  final String id;
  final DateTime createdAt;

  /// Flow and operation labels, outermost first: `download.probe > engine.probe`.
  final String? action;

  /// The notifier that showed it.
  final String? source;
  final String message;
  final String? error;
  final bool shown;
  const ErrorLogLocalData({
    required this.id,
    required this.createdAt,
    this.action,
    this.source,
    required this.message,
    this.error,
    required this.shown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || action != null) {
      map['action'] = Variable<String>(action);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['shown'] = Variable<bool>(shown);
    return map;
  }

  ErrorLogLocalCompanion toCompanion(bool nullToAbsent) {
    return ErrorLogLocalCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      action: action == null && nullToAbsent ? const Value.absent() : Value(action),
      source: source == null && nullToAbsent ? const Value.absent() : Value(source),
      message: Value(message),
      error: error == null && nullToAbsent ? const Value.absent() : Value(error),
      shown: Value(shown),
    );
  }

  factory ErrorLogLocalData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ErrorLogLocalData(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      action: serializer.fromJson<String?>(json['action']),
      source: serializer.fromJson<String?>(json['source']),
      message: serializer.fromJson<String>(json['message']),
      error: serializer.fromJson<String?>(json['error']),
      shown: serializer.fromJson<bool>(json['shown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'action': serializer.toJson<String?>(action),
      'source': serializer.toJson<String?>(source),
      'message': serializer.toJson<String>(message),
      'error': serializer.toJson<String?>(error),
      'shown': serializer.toJson<bool>(shown),
    };
  }

  ErrorLogLocalData copyWith({
    String? id,
    DateTime? createdAt,
    Value<String?> action = const Value.absent(),
    Value<String?> source = const Value.absent(),
    String? message,
    Value<String?> error = const Value.absent(),
    bool? shown,
  }) => ErrorLogLocalData(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    action: action.present ? action.value : this.action,
    source: source.present ? source.value : this.source,
    message: message ?? this.message,
    error: error.present ? error.value : this.error,
    shown: shown ?? this.shown,
  );
  ErrorLogLocalData copyWithCompanion(ErrorLogLocalCompanion data) {
    return ErrorLogLocalData(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      action: data.action.present ? data.action.value : this.action,
      source: data.source.present ? data.source.value : this.source,
      message: data.message.present ? data.message.value : this.message,
      error: data.error.present ? data.error.value : this.error,
      shown: data.shown.present ? data.shown.value : this.shown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogLocalData(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('source: $source, ')
          ..write('message: $message, ')
          ..write('error: $error, ')
          ..write('shown: $shown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, action, source, message, error, shown);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ErrorLogLocalData &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.action == this.action &&
          other.source == this.source &&
          other.message == this.message &&
          other.error == this.error &&
          other.shown == this.shown);
}

class ErrorLogLocalCompanion extends UpdateCompanion<ErrorLogLocalData> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String?> action;
  final Value<String?> source;
  final Value<String> message;
  final Value<String?> error;
  final Value<bool> shown;
  final Value<int> rowid;
  const ErrorLogLocalCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.action = const Value.absent(),
    this.source = const Value.absent(),
    this.message = const Value.absent(),
    this.error = const Value.absent(),
    this.shown = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ErrorLogLocalCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.action = const Value.absent(),
    this.source = const Value.absent(),
    required String message,
    this.error = const Value.absent(),
    this.shown = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       message = Value(message);
  static Insertable<ErrorLogLocalData> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? action,
    Expression<String>? source,
    Expression<String>? message,
    Expression<String>? error,
    Expression<bool>? shown,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (action != null) 'action': action,
      if (source != null) 'source': source,
      if (message != null) 'message': message,
      if (error != null) 'error': error,
      if (shown != null) 'shown': shown,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ErrorLogLocalCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String?>? action,
    Value<String?>? source,
    Value<String>? message,
    Value<String?>? error,
    Value<bool>? shown,
    Value<int>? rowid,
  }) {
    return ErrorLogLocalCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      action: action ?? this.action,
      source: source ?? this.source,
      message: message ?? this.message,
      error: error ?? this.error,
      shown: shown ?? this.shown,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (shown.present) {
      map['shown'] = Variable<bool>(shown.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ErrorLogLocalCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('action: $action, ')
          ..write('source: $source, ')
          ..write('message: $message, ')
          ..write('error: $error, ')
          ..write('shown: $shown, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryItemLocalTable extends LibraryItemLocal with TableInfo<$LibraryItemLocalTable, LibraryItemLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryItemLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
    'site',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploaderMeta = const VerificationMeta('uploader');
  @override
  late final GeneratedColumn<String> uploader = GeneratedColumn<String>(
    'uploader',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta('sourceUrl');
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailRelativePathMeta = const VerificationMeta('thumbnailRelativePath');
  @override
  late final GeneratedColumn<String> thumbnailRelativePath = GeneratedColumn<String>(
    'thumbnail_relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('download'),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIndexMeta = const VerificationMeta('groupIndex');
  @override
  late final GeneratedColumn<int> groupIndex = GeneratedColumn<int>(
    'group_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedToPhotosAtMeta = const VerificationMeta('savedToPhotosAt');
  @override
  late final GeneratedColumn<DateTime> savedToPhotosAt = GeneratedColumn<DateTime>(
    'saved_to_photos_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedToFilesAtMeta = const VerificationMeta('savedToFilesAt');
  @override
  late final GeneratedColumn<DateTime> savedToFilesAt = GeneratedColumn<DateTime>(
    'saved_to_files_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    site,
    title,
    uploader,
    sourceUrl,
    relativePath,
    thumbnailRelativePath,
    sizeBytes,
    durationMs,
    format,
    origin,
    groupId,
    groupIndex,
    savedToPhotosAt,
    savedToFilesAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_item';
  @override
  VerificationContext validateIntegrity(Insertable<LibraryItemLocalData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('site')) {
      context.handle(_siteMeta, site.isAcceptableOrUnknown(data['site']!, _siteMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('uploader')) {
      context.handle(_uploaderMeta, uploader.isAcceptableOrUnknown(data['uploader']!, _uploaderMeta));
    }
    if (data.containsKey('source_url')) {
      context.handle(_sourceUrlMeta, sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta));
    }
    if (data.containsKey('relative_path')) {
      context.handle(_relativePathMeta, relativePath.isAcceptableOrUnknown(data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumbnail_relative_path')) {
      context.handle(
        _thumbnailRelativePathMeta,
        thumbnailRelativePath.isAcceptableOrUnknown(data['thumbnail_relative_path']!, _thumbnailRelativePathMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta, format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta, origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta, groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    if (data.containsKey('group_index')) {
      context.handle(_groupIndexMeta, groupIndex.isAcceptableOrUnknown(data['group_index']!, _groupIndexMeta));
    }
    if (data.containsKey('saved_to_photos_at')) {
      context.handle(
        _savedToPhotosAtMeta,
        savedToPhotosAt.isAcceptableOrUnknown(data['saved_to_photos_at']!, _savedToPhotosAtMeta),
      );
    }
    if (data.containsKey('saved_to_files_at')) {
      context.handle(
        _savedToFilesAtMeta,
        savedToFilesAt.isAcceptableOrUnknown(data['saved_to_files_at']!, _savedToFilesAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryItemLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryItemLocalData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      site: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}site']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      uploader: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}uploader']),
      sourceUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_url']),
      relativePath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      thumbnailRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_relative_path'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      format: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      origin: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      groupId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}group_id']),
      groupIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}group_index']),
      savedToPhotosAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_to_photos_at'],
      ),
      savedToFilesAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_to_files_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LibraryItemLocalTable createAlias(String alias) {
    return $LibraryItemLocalTable(attachedDatabase, alias);
  }
}

class LibraryItemLocalData extends DataClass implements Insertable<LibraryItemLocalData> {
  final String id;

  /// MediaKind name: video / audio / photo.
  final String kind;

  /// Site name, null for converted local files.
  final String? site;
  final String title;
  final String? uploader;
  final String? sourceUrl;
  final String relativePath;
  final String? thumbnailRelativePath;
  final int sizeBytes;
  final int? durationMs;

  /// File extension: mp4, mp3, jpg…
  final String format;

  /// download / convert.
  final String origin;

  /// Shared by every item of one post (carousel); null for single files.
  final String? groupId;

  /// Position inside the group, from 0.
  final int? groupIndex;
  final DateTime? savedToPhotosAt;
  final DateTime? savedToFilesAt;
  final DateTime createdAt;
  const LibraryItemLocalData({
    required this.id,
    required this.kind,
    this.site,
    required this.title,
    this.uploader,
    this.sourceUrl,
    required this.relativePath,
    this.thumbnailRelativePath,
    required this.sizeBytes,
    this.durationMs,
    required this.format,
    required this.origin,
    this.groupId,
    this.groupIndex,
    this.savedToPhotosAt,
    this.savedToFilesAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || site != null) {
      map['site'] = Variable<String>(site);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || uploader != null) {
      map['uploader'] = Variable<String>(uploader);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbnailRelativePath != null) {
      map['thumbnail_relative_path'] = Variable<String>(thumbnailRelativePath);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['format'] = Variable<String>(format);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || groupIndex != null) {
      map['group_index'] = Variable<int>(groupIndex);
    }
    if (!nullToAbsent || savedToPhotosAt != null) {
      map['saved_to_photos_at'] = Variable<DateTime>(savedToPhotosAt);
    }
    if (!nullToAbsent || savedToFilesAt != null) {
      map['saved_to_files_at'] = Variable<DateTime>(savedToFilesAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LibraryItemLocalCompanion toCompanion(bool nullToAbsent) {
    return LibraryItemLocalCompanion(
      id: Value(id),
      kind: Value(kind),
      site: site == null && nullToAbsent ? const Value.absent() : Value(site),
      title: Value(title),
      uploader: uploader == null && nullToAbsent ? const Value.absent() : Value(uploader),
      sourceUrl: sourceUrl == null && nullToAbsent ? const Value.absent() : Value(sourceUrl),
      relativePath: Value(relativePath),
      thumbnailRelativePath: thumbnailRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailRelativePath),
      sizeBytes: Value(sizeBytes),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      format: Value(format),
      origin: Value(origin),
      groupId: groupId == null && nullToAbsent ? const Value.absent() : Value(groupId),
      groupIndex: groupIndex == null && nullToAbsent ? const Value.absent() : Value(groupIndex),
      savedToPhotosAt: savedToPhotosAt == null && nullToAbsent ? const Value.absent() : Value(savedToPhotosAt),
      savedToFilesAt: savedToFilesAt == null && nullToAbsent ? const Value.absent() : Value(savedToFilesAt),
      createdAt: Value(createdAt),
    );
  }

  factory LibraryItemLocalData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryItemLocalData(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      site: serializer.fromJson<String?>(json['site']),
      title: serializer.fromJson<String>(json['title']),
      uploader: serializer.fromJson<String?>(json['uploader']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbnailRelativePath: serializer.fromJson<String?>(json['thumbnailRelativePath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      format: serializer.fromJson<String>(json['format']),
      origin: serializer.fromJson<String>(json['origin']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      groupIndex: serializer.fromJson<int?>(json['groupIndex']),
      savedToPhotosAt: serializer.fromJson<DateTime?>(json['savedToPhotosAt']),
      savedToFilesAt: serializer.fromJson<DateTime?>(json['savedToFilesAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'site': serializer.toJson<String?>(site),
      'title': serializer.toJson<String>(title),
      'uploader': serializer.toJson<String?>(uploader),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbnailRelativePath': serializer.toJson<String?>(thumbnailRelativePath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'durationMs': serializer.toJson<int?>(durationMs),
      'format': serializer.toJson<String>(format),
      'origin': serializer.toJson<String>(origin),
      'groupId': serializer.toJson<String?>(groupId),
      'groupIndex': serializer.toJson<int?>(groupIndex),
      'savedToPhotosAt': serializer.toJson<DateTime?>(savedToPhotosAt),
      'savedToFilesAt': serializer.toJson<DateTime?>(savedToFilesAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LibraryItemLocalData copyWith({
    String? id,
    String? kind,
    Value<String?> site = const Value.absent(),
    String? title,
    Value<String?> uploader = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    String? relativePath,
    Value<String?> thumbnailRelativePath = const Value.absent(),
    int? sizeBytes,
    Value<int?> durationMs = const Value.absent(),
    String? format,
    String? origin,
    Value<String?> groupId = const Value.absent(),
    Value<int?> groupIndex = const Value.absent(),
    Value<DateTime?> savedToPhotosAt = const Value.absent(),
    Value<DateTime?> savedToFilesAt = const Value.absent(),
    DateTime? createdAt,
  }) => LibraryItemLocalData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    site: site.present ? site.value : this.site,
    title: title ?? this.title,
    uploader: uploader.present ? uploader.value : this.uploader,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    relativePath: relativePath ?? this.relativePath,
    thumbnailRelativePath: thumbnailRelativePath.present ? thumbnailRelativePath.value : this.thumbnailRelativePath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    format: format ?? this.format,
    origin: origin ?? this.origin,
    groupId: groupId.present ? groupId.value : this.groupId,
    groupIndex: groupIndex.present ? groupIndex.value : this.groupIndex,
    savedToPhotosAt: savedToPhotosAt.present ? savedToPhotosAt.value : this.savedToPhotosAt,
    savedToFilesAt: savedToFilesAt.present ? savedToFilesAt.value : this.savedToFilesAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LibraryItemLocalData copyWithCompanion(LibraryItemLocalCompanion data) {
    return LibraryItemLocalData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      site: data.site.present ? data.site.value : this.site,
      title: data.title.present ? data.title.value : this.title,
      uploader: data.uploader.present ? data.uploader.value : this.uploader,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      relativePath: data.relativePath.present ? data.relativePath.value : this.relativePath,
      thumbnailRelativePath: data.thumbnailRelativePath.present
          ? data.thumbnailRelativePath.value
          : this.thumbnailRelativePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      format: data.format.present ? data.format.value : this.format,
      origin: data.origin.present ? data.origin.value : this.origin,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupIndex: data.groupIndex.present ? data.groupIndex.value : this.groupIndex,
      savedToPhotosAt: data.savedToPhotosAt.present ? data.savedToPhotosAt.value : this.savedToPhotosAt,
      savedToFilesAt: data.savedToFilesAt.present ? data.savedToFilesAt.value : this.savedToFilesAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItemLocalData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('site: $site, ')
          ..write('title: $title, ')
          ..write('uploader: $uploader, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailRelativePath: $thumbnailRelativePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('origin: $origin, ')
          ..write('groupId: $groupId, ')
          ..write('groupIndex: $groupIndex, ')
          ..write('savedToPhotosAt: $savedToPhotosAt, ')
          ..write('savedToFilesAt: $savedToFilesAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    site,
    title,
    uploader,
    sourceUrl,
    relativePath,
    thumbnailRelativePath,
    sizeBytes,
    durationMs,
    format,
    origin,
    groupId,
    groupIndex,
    savedToPhotosAt,
    savedToFilesAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryItemLocalData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.site == this.site &&
          other.title == this.title &&
          other.uploader == this.uploader &&
          other.sourceUrl == this.sourceUrl &&
          other.relativePath == this.relativePath &&
          other.thumbnailRelativePath == this.thumbnailRelativePath &&
          other.sizeBytes == this.sizeBytes &&
          other.durationMs == this.durationMs &&
          other.format == this.format &&
          other.origin == this.origin &&
          other.groupId == this.groupId &&
          other.groupIndex == this.groupIndex &&
          other.savedToPhotosAt == this.savedToPhotosAt &&
          other.savedToFilesAt == this.savedToFilesAt &&
          other.createdAt == this.createdAt);
}

class LibraryItemLocalCompanion extends UpdateCompanion<LibraryItemLocalData> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> site;
  final Value<String> title;
  final Value<String?> uploader;
  final Value<String?> sourceUrl;
  final Value<String> relativePath;
  final Value<String?> thumbnailRelativePath;
  final Value<int> sizeBytes;
  final Value<int?> durationMs;
  final Value<String> format;
  final Value<String> origin;
  final Value<String?> groupId;
  final Value<int?> groupIndex;
  final Value<DateTime?> savedToPhotosAt;
  final Value<DateTime?> savedToFilesAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LibraryItemLocalCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.site = const Value.absent(),
    this.title = const Value.absent(),
    this.uploader = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbnailRelativePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.format = const Value.absent(),
    this.origin = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupIndex = const Value.absent(),
    this.savedToPhotosAt = const Value.absent(),
    this.savedToFilesAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryItemLocalCompanion.insert({
    required String id,
    required String kind,
    this.site = const Value.absent(),
    required String title,
    this.uploader = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    required String relativePath,
    this.thumbnailRelativePath = const Value.absent(),
    required int sizeBytes,
    this.durationMs = const Value.absent(),
    required String format,
    this.origin = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupIndex = const Value.absent(),
    this.savedToPhotosAt = const Value.absent(),
    this.savedToFilesAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       title = Value(title),
       relativePath = Value(relativePath),
       sizeBytes = Value(sizeBytes),
       format = Value(format),
       createdAt = Value(createdAt);
  static Insertable<LibraryItemLocalData> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? site,
    Expression<String>? title,
    Expression<String>? uploader,
    Expression<String>? sourceUrl,
    Expression<String>? relativePath,
    Expression<String>? thumbnailRelativePath,
    Expression<int>? sizeBytes,
    Expression<int>? durationMs,
    Expression<String>? format,
    Expression<String>? origin,
    Expression<String>? groupId,
    Expression<int>? groupIndex,
    Expression<DateTime>? savedToPhotosAt,
    Expression<DateTime>? savedToFilesAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (site != null) 'site': site,
      if (title != null) 'title': title,
      if (uploader != null) 'uploader': uploader,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbnailRelativePath != null) 'thumbnail_relative_path': thumbnailRelativePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (durationMs != null) 'duration_ms': durationMs,
      if (format != null) 'format': format,
      if (origin != null) 'origin': origin,
      if (groupId != null) 'group_id': groupId,
      if (groupIndex != null) 'group_index': groupIndex,
      if (savedToPhotosAt != null) 'saved_to_photos_at': savedToPhotosAt,
      if (savedToFilesAt != null) 'saved_to_files_at': savedToFilesAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryItemLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? site,
    Value<String>? title,
    Value<String?>? uploader,
    Value<String?>? sourceUrl,
    Value<String>? relativePath,
    Value<String?>? thumbnailRelativePath,
    Value<int>? sizeBytes,
    Value<int?>? durationMs,
    Value<String>? format,
    Value<String>? origin,
    Value<String?>? groupId,
    Value<int?>? groupIndex,
    Value<DateTime?>? savedToPhotosAt,
    Value<DateTime?>? savedToFilesAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LibraryItemLocalCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      site: site ?? this.site,
      title: title ?? this.title,
      uploader: uploader ?? this.uploader,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      relativePath: relativePath ?? this.relativePath,
      thumbnailRelativePath: thumbnailRelativePath ?? this.thumbnailRelativePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationMs: durationMs ?? this.durationMs,
      format: format ?? this.format,
      origin: origin ?? this.origin,
      groupId: groupId ?? this.groupId,
      groupIndex: groupIndex ?? this.groupIndex,
      savedToPhotosAt: savedToPhotosAt ?? this.savedToPhotosAt,
      savedToFilesAt: savedToFilesAt ?? this.savedToFilesAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (uploader.present) {
      map['uploader'] = Variable<String>(uploader.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbnailRelativePath.present) {
      map['thumbnail_relative_path'] = Variable<String>(thumbnailRelativePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (groupIndex.present) {
      map['group_index'] = Variable<int>(groupIndex.value);
    }
    if (savedToPhotosAt.present) {
      map['saved_to_photos_at'] = Variable<DateTime>(savedToPhotosAt.value);
    }
    if (savedToFilesAt.present) {
      map['saved_to_files_at'] = Variable<DateTime>(savedToFilesAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryItemLocalCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('site: $site, ')
          ..write('title: $title, ')
          ..write('uploader: $uploader, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailRelativePath: $thumbnailRelativePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('format: $format, ')
          ..write('origin: $origin, ')
          ..write('groupId: $groupId, ')
          ..write('groupIndex: $groupIndex, ')
          ..write('savedToPhotosAt: $savedToPhotosAt, ')
          ..write('savedToFilesAt: $savedToFilesAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadJobLocalTable extends DownloadJobLocal with TableInfo<$DownloadJobLocalTable, DownloadJobLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestMeta = const VerificationMeta('request');
  @override
  late final GeneratedColumn<String> request = GeneratedColumn<String>(
    'request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _libraryItemIdsMeta = const VerificationMeta('libraryItemIds');
  @override
  late final GeneratedColumn<String> libraryItemIds = GeneratedColumn<String>(
    'library_item_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta('finishedAt');
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    request,
    stage,
    errorMessage,
    libraryItemIds,
    sizeBytes,
    createdAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_job';
  @override
  VerificationContext validateIntegrity(Insertable<DownloadJobLocalData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('request')) {
      context.handle(_requestMeta, request.isAcceptableOrUnknown(data['request']!, _requestMeta));
    } else if (isInserting) {
      context.missing(_requestMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(_stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(_errorMessageMeta, errorMessage.isAcceptableOrUnknown(data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('library_item_ids')) {
      context.handle(
        _libraryItemIdsMeta,
        libraryItemIds.isAcceptableOrUnknown(data['library_item_ids']!, _libraryItemIdsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta, sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(_finishedAtMeta, finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadJobLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJobLocalData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      request: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}request'])!,
      stage: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}stage'])!,
      errorMessage: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      libraryItemIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_item_ids'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      finishedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}finished_at']),
    );
  }

  @override
  $DownloadJobLocalTable createAlias(String alias) {
    return $DownloadJobLocalTable(attachedDatabase, alias);
  }
}

class DownloadJobLocalData extends DataClass implements Insertable<DownloadJobLocalData> {
  final String id;

  /// DownloadRequest as JSON (url, site, title, kind, quality…).
  final String request;

  /// JobStage name.
  final String stage;
  final String? errorMessage;

  /// JSON list of Library item ids, once done.
  final String libraryItemIds;
  final int? sizeBytes;
  final DateTime createdAt;
  final DateTime? finishedAt;
  const DownloadJobLocalData({
    required this.id,
    required this.request,
    required this.stage,
    this.errorMessage,
    required this.libraryItemIds,
    this.sizeBytes,
    required this.createdAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['request'] = Variable<String>(request);
    map['stage'] = Variable<String>(stage);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['library_item_ids'] = Variable<String>(libraryItemIds);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  DownloadJobLocalCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobLocalCompanion(
      id: Value(id),
      request: Value(request),
      stage: Value(stage),
      errorMessage: errorMessage == null && nullToAbsent ? const Value.absent() : Value(errorMessage),
      libraryItemIds: Value(libraryItemIds),
      sizeBytes: sizeBytes == null && nullToAbsent ? const Value.absent() : Value(sizeBytes),
      createdAt: Value(createdAt),
      finishedAt: finishedAt == null && nullToAbsent ? const Value.absent() : Value(finishedAt),
    );
  }

  factory DownloadJobLocalData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJobLocalData(
      id: serializer.fromJson<String>(json['id']),
      request: serializer.fromJson<String>(json['request']),
      stage: serializer.fromJson<String>(json['stage']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      libraryItemIds: serializer.fromJson<String>(json['libraryItemIds']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'request': serializer.toJson<String>(request),
      'stage': serializer.toJson<String>(stage),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'libraryItemIds': serializer.toJson<String>(libraryItemIds),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  DownloadJobLocalData copyWith({
    String? id,
    String? request,
    String? stage,
    Value<String?> errorMessage = const Value.absent(),
    String? libraryItemIds,
    Value<int?> sizeBytes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => DownloadJobLocalData(
    id: id ?? this.id,
    request: request ?? this.request,
    stage: stage ?? this.stage,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    libraryItemIds: libraryItemIds ?? this.libraryItemIds,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  DownloadJobLocalData copyWithCompanion(DownloadJobLocalCompanion data) {
    return DownloadJobLocalData(
      id: data.id.present ? data.id.value : this.id,
      request: data.request.present ? data.request.value : this.request,
      stage: data.stage.present ? data.stage.value : this.stage,
      errorMessage: data.errorMessage.present ? data.errorMessage.value : this.errorMessage,
      libraryItemIds: data.libraryItemIds.present ? data.libraryItemIds.value : this.libraryItemIds,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      finishedAt: data.finishedAt.present ? data.finishedAt.value : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobLocalData(')
          ..write('id: $id, ')
          ..write('request: $request, ')
          ..write('stage: $stage, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('libraryItemIds: $libraryItemIds, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, request, stage, errorMessage, libraryItemIds, sizeBytes, createdAt, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJobLocalData &&
          other.id == this.id &&
          other.request == this.request &&
          other.stage == this.stage &&
          other.errorMessage == this.errorMessage &&
          other.libraryItemIds == this.libraryItemIds &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt &&
          other.finishedAt == this.finishedAt);
}

class DownloadJobLocalCompanion extends UpdateCompanion<DownloadJobLocalData> {
  final Value<String> id;
  final Value<String> request;
  final Value<String> stage;
  final Value<String?> errorMessage;
  final Value<String> libraryItemIds;
  final Value<int?> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const DownloadJobLocalCompanion({
    this.id = const Value.absent(),
    this.request = const Value.absent(),
    this.stage = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.libraryItemIds = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadJobLocalCompanion.insert({
    required String id,
    required String request,
    required String stage,
    this.errorMessage = const Value.absent(),
    this.libraryItemIds = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required DateTime createdAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       request = Value(request),
       stage = Value(stage),
       createdAt = Value(createdAt);
  static Insertable<DownloadJobLocalData> custom({
    Expression<String>? id,
    Expression<String>? request,
    Expression<String>? stage,
    Expression<String>? errorMessage,
    Expression<String>? libraryItemIds,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (request != null) 'request': request,
      if (stage != null) 'stage': stage,
      if (errorMessage != null) 'error_message': errorMessage,
      if (libraryItemIds != null) 'library_item_ids': libraryItemIds,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadJobLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? request,
    Value<String>? stage,
    Value<String?>? errorMessage,
    Value<String>? libraryItemIds,
    Value<int?>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return DownloadJobLocalCompanion(
      id: id ?? this.id,
      request: request ?? this.request,
      stage: stage ?? this.stage,
      errorMessage: errorMessage ?? this.errorMessage,
      libraryItemIds: libraryItemIds ?? this.libraryItemIds,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (request.present) {
      map['request'] = Variable<String>(request.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (libraryItemIds.present) {
      map['library_item_ids'] = Variable<String>(libraryItemIds.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobLocalCompanion(')
          ..write('id: $id, ')
          ..write('request: $request, ')
          ..write('stage: $stage, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('libraryItemIds: $libraryItemIds, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValueLocalTable keyValueLocal = $KeyValueLocalTable(this);
  late final $ErrorLogLocalTable errorLogLocal = $ErrorLogLocalTable(this);
  late final $LibraryItemLocalTable libraryItemLocal = $LibraryItemLocalTable(this);
  late final $DownloadJobLocalTable downloadJobLocal = $DownloadJobLocalTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueLocal,
    errorLogLocal,
    libraryItemLocal,
    downloadJobLocal,
  ];
}

typedef $$KeyValueLocalTableCreateCompanionBuilder = KeyValueLocalCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValueLocalTableUpdateCompanionBuilder = KeyValueLocalCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValueLocalTableFilterComposer extends Composer<_$AppDatabase, $KeyValueLocalTable> {
  $$KeyValueLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KeyValueLocalTableOrderingComposer extends Composer<_$AppDatabase, $KeyValueLocalTable> {
  $$KeyValueLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KeyValueLocalTableAnnotationComposer extends Composer<_$AppDatabase, $KeyValueLocalTable> {
  $$KeyValueLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValueLocalTable,
          KeyValueLocalData,
          $$KeyValueLocalTableFilterComposer,
          $$KeyValueLocalTableOrderingComposer,
          $$KeyValueLocalTableAnnotationComposer,
          $$KeyValueLocalTableCreateCompanionBuilder,
          $$KeyValueLocalTableUpdateCompanionBuilder,
          (KeyValueLocalData, BaseReferences<_$AppDatabase, $KeyValueLocalTable, KeyValueLocalData>),
          KeyValueLocalData,
          PrefetchHooks Function()
        > {
  $$KeyValueLocalTableTableManager(_$AppDatabase db, $KeyValueLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KeyValueLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KeyValueLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$KeyValueLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValueLocalCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValueLocalCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValueLocalTable, KeyValueLocalData>(table),
                  BaseReferences<_$AppDatabase, $KeyValueLocalTable, KeyValueLocalData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValueLocalTable,
      KeyValueLocalData,
      $$KeyValueLocalTableFilterComposer,
      $$KeyValueLocalTableOrderingComposer,
      $$KeyValueLocalTableAnnotationComposer,
      $$KeyValueLocalTableCreateCompanionBuilder,
      $$KeyValueLocalTableUpdateCompanionBuilder,
      (KeyValueLocalData, BaseReferences<_$AppDatabase, $KeyValueLocalTable, KeyValueLocalData>),
      KeyValueLocalData,
      PrefetchHooks Function()
    >;
typedef $$ErrorLogLocalTableCreateCompanionBuilder = ErrorLogLocalCompanion Function({
  required String id,
  required DateTime createdAt,
  Value<String?> action,
  Value<String?> source,
  required String message,
  Value<String?> error,
  Value<bool> shown,
  Value<int> rowid,
});
typedef $$ErrorLogLocalTableUpdateCompanionBuilder = ErrorLogLocalCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<String?> action,
  Value<String?> source,
  Value<String> message,
  Value<String?> error,
  Value<bool> shown,
  Value<int> rowid,
});

class $$ErrorLogLocalTableFilterComposer extends Composer<_$AppDatabase, $ErrorLogLocalTable> {
  $$ErrorLogLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get shown => $composableBuilder(column: $table.shown, builder: (column) => ColumnFilters(column));
}

class $$ErrorLogLocalTableOrderingComposer extends Composer<_$AppDatabase, $ErrorLogLocalTable> {
  $$ErrorLogLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get shown =>
      $composableBuilder(column: $table.shown, builder: (column) => ColumnOrderings(column));
}

class $$ErrorLogLocalTableAnnotationComposer extends Composer<_$AppDatabase, $ErrorLogLocalTable> {
  $$ErrorLogLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get action => $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get message => $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get error => $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<bool> get shown => $composableBuilder(column: $table.shown, builder: (column) => column);
}

class $$ErrorLogLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ErrorLogLocalTable,
          ErrorLogLocalData,
          $$ErrorLogLocalTableFilterComposer,
          $$ErrorLogLocalTableOrderingComposer,
          $$ErrorLogLocalTableAnnotationComposer,
          $$ErrorLogLocalTableCreateCompanionBuilder,
          $$ErrorLogLocalTableUpdateCompanionBuilder,
          (ErrorLogLocalData, BaseReferences<_$AppDatabase, $ErrorLogLocalTable, ErrorLogLocalData>),
          ErrorLogLocalData,
          PrefetchHooks Function()
        > {
  $$ErrorLogLocalTableTableManager(_$AppDatabase db, $ErrorLogLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ErrorLogLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ErrorLogLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ErrorLogLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> action = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<bool> shown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorLogLocalCompanion(
                id: id,
                createdAt: createdAt,
                action: action,
                source: source,
                message: message,
                error: error,
                shown: shown,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<String?> action = const Value.absent(),
                Value<String?> source = const Value.absent(),
                required String message,
                Value<String?> error = const Value.absent(),
                Value<bool> shown = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ErrorLogLocalCompanion.insert(
                id: id,
                createdAt: createdAt,
                action: action,
                source: source,
                message: message,
                error: error,
                shown: shown,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ErrorLogLocalTable, ErrorLogLocalData>(table),
                  BaseReferences<_$AppDatabase, $ErrorLogLocalTable, ErrorLogLocalData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ErrorLogLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ErrorLogLocalTable,
      ErrorLogLocalData,
      $$ErrorLogLocalTableFilterComposer,
      $$ErrorLogLocalTableOrderingComposer,
      $$ErrorLogLocalTableAnnotationComposer,
      $$ErrorLogLocalTableCreateCompanionBuilder,
      $$ErrorLogLocalTableUpdateCompanionBuilder,
      (ErrorLogLocalData, BaseReferences<_$AppDatabase, $ErrorLogLocalTable, ErrorLogLocalData>),
      ErrorLogLocalData,
      PrefetchHooks Function()
    >;
typedef $$LibraryItemLocalTableCreateCompanionBuilder = LibraryItemLocalCompanion Function({
  required String id,
  required String kind,
  Value<String?> site,
  required String title,
  Value<String?> uploader,
  Value<String?> sourceUrl,
  required String relativePath,
  Value<String?> thumbnailRelativePath,
  required int sizeBytes,
  Value<int?> durationMs,
  required String format,
  Value<String> origin,
  Value<String?> groupId,
  Value<int?> groupIndex,
  Value<DateTime?> savedToPhotosAt,
  Value<DateTime?> savedToFilesAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LibraryItemLocalTableUpdateCompanionBuilder = LibraryItemLocalCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String?> site,
  Value<String> title,
  Value<String?> uploader,
  Value<String?> sourceUrl,
  Value<String> relativePath,
  Value<String?> thumbnailRelativePath,
  Value<int> sizeBytes,
  Value<int?> durationMs,
  Value<String> format,
  Value<String> origin,
  Value<String?> groupId,
  Value<int?> groupIndex,
  Value<DateTime?> savedToPhotosAt,
  Value<DateTime?> savedToFilesAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LibraryItemLocalTableFilterComposer extends Composer<_$AppDatabase, $LibraryItemLocalTable> {
  $$LibraryItemLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get site => $composableBuilder(column: $table.site, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath =>
      $composableBuilder(column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailRelativePath =>
      $composableBuilder(column: $table.thumbnailRelativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get groupIndex =>
      $composableBuilder(column: $table.groupIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedToPhotosAt =>
      $composableBuilder(column: $table.savedToPhotosAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedToFilesAt =>
      $composableBuilder(column: $table.savedToFilesAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LibraryItemLocalTableOrderingComposer extends Composer<_$AppDatabase, $LibraryItemLocalTable> {
  $$LibraryItemLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploader =>
      $composableBuilder(column: $table.uploader, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath =>
      $composableBuilder(column: $table.relativePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailRelativePath =>
      $composableBuilder(column: $table.thumbnailRelativePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get groupIndex =>
      $composableBuilder(column: $table.groupIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedToPhotosAt =>
      $composableBuilder(column: $table.savedToPhotosAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedToFilesAt =>
      $composableBuilder(column: $table.savedToFilesAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LibraryItemLocalTableAnnotationComposer extends Composer<_$AppDatabase, $LibraryItemLocalTable> {
  $$LibraryItemLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get site => $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get uploader => $composableBuilder(column: $table.uploader, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl => $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get relativePath =>
      $composableBuilder(column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailRelativePath =>
      $composableBuilder(column: $table.thumbnailRelativePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get format => $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get origin => $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get groupId => $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get groupIndex => $composableBuilder(column: $table.groupIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get savedToPhotosAt =>
      $composableBuilder(column: $table.savedToPhotosAt, builder: (column) => column);

  GeneratedColumn<DateTime> get savedToFilesAt =>
      $composableBuilder(column: $table.savedToFilesAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LibraryItemLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryItemLocalTable,
          LibraryItemLocalData,
          $$LibraryItemLocalTableFilterComposer,
          $$LibraryItemLocalTableOrderingComposer,
          $$LibraryItemLocalTableAnnotationComposer,
          $$LibraryItemLocalTableCreateCompanionBuilder,
          $$LibraryItemLocalTableUpdateCompanionBuilder,
          (LibraryItemLocalData, BaseReferences<_$AppDatabase, $LibraryItemLocalTable, LibraryItemLocalData>),
          LibraryItemLocalData,
          PrefetchHooks Function()
        > {
  $$LibraryItemLocalTableTableManager(_$AppDatabase db, $LibraryItemLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LibraryItemLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LibraryItemLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LibraryItemLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> site = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> uploader = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String?> thumbnailRelativePath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> groupIndex = const Value.absent(),
                Value<DateTime?> savedToPhotosAt = const Value.absent(),
                Value<DateTime?> savedToFilesAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryItemLocalCompanion(
                id: id,
                kind: kind,
                site: site,
                title: title,
                uploader: uploader,
                sourceUrl: sourceUrl,
                relativePath: relativePath,
                thumbnailRelativePath: thumbnailRelativePath,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                format: format,
                origin: origin,
                groupId: groupId,
                groupIndex: groupIndex,
                savedToPhotosAt: savedToPhotosAt,
                savedToFilesAt: savedToFilesAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> site = const Value.absent(),
                required String title,
                Value<String?> uploader = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                required String relativePath,
                Value<String?> thumbnailRelativePath = const Value.absent(),
                required int sizeBytes,
                Value<int?> durationMs = const Value.absent(),
                required String format,
                Value<String> origin = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> groupIndex = const Value.absent(),
                Value<DateTime?> savedToPhotosAt = const Value.absent(),
                Value<DateTime?> savedToFilesAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryItemLocalCompanion.insert(
                id: id,
                kind: kind,
                site: site,
                title: title,
                uploader: uploader,
                sourceUrl: sourceUrl,
                relativePath: relativePath,
                thumbnailRelativePath: thumbnailRelativePath,
                sizeBytes: sizeBytes,
                durationMs: durationMs,
                format: format,
                origin: origin,
                groupId: groupId,
                groupIndex: groupIndex,
                savedToPhotosAt: savedToPhotosAt,
                savedToFilesAt: savedToFilesAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryItemLocalTable, LibraryItemLocalData>(table),
                  BaseReferences<_$AppDatabase, $LibraryItemLocalTable, LibraryItemLocalData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryItemLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryItemLocalTable,
      LibraryItemLocalData,
      $$LibraryItemLocalTableFilterComposer,
      $$LibraryItemLocalTableOrderingComposer,
      $$LibraryItemLocalTableAnnotationComposer,
      $$LibraryItemLocalTableCreateCompanionBuilder,
      $$LibraryItemLocalTableUpdateCompanionBuilder,
      (LibraryItemLocalData, BaseReferences<_$AppDatabase, $LibraryItemLocalTable, LibraryItemLocalData>),
      LibraryItemLocalData,
      PrefetchHooks Function()
    >;
typedef $$DownloadJobLocalTableCreateCompanionBuilder = DownloadJobLocalCompanion Function({
  required String id,
  required String request,
  required String stage,
  Value<String?> errorMessage,
  Value<String> libraryItemIds,
  Value<int?> sizeBytes,
  required DateTime createdAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});
typedef $$DownloadJobLocalTableUpdateCompanionBuilder = DownloadJobLocalCompanion Function({
  Value<String> id,
  Value<String> request,
  Value<String> stage,
  Value<String?> errorMessage,
  Value<String> libraryItemIds,
  Value<int?> sizeBytes,
  Value<DateTime> createdAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});

class $$DownloadJobLocalTableFilterComposer extends Composer<_$AppDatabase, $DownloadJobLocalTable> {
  $$DownloadJobLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get request =>
      $composableBuilder(column: $table.request, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get libraryItemIds =>
      $composableBuilder(column: $table.libraryItemIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnFilters(column));
}

class $$DownloadJobLocalTableOrderingComposer extends Composer<_$AppDatabase, $DownloadJobLocalTable> {
  $$DownloadJobLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get request =>
      $composableBuilder(column: $table.request, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get libraryItemIds =>
      $composableBuilder(column: $table.libraryItemIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => ColumnOrderings(column));
}

class $$DownloadJobLocalTableAnnotationComposer extends Composer<_$AppDatabase, $DownloadJobLocalTable> {
  $$DownloadJobLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get request => $composableBuilder(column: $table.request, builder: (column) => column);

  GeneratedColumn<String> get stage => $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get errorMessage =>
      $composableBuilder(column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get libraryItemIds =>
      $composableBuilder(column: $table.libraryItemIds, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes => $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt =>
      $composableBuilder(column: $table.finishedAt, builder: (column) => column);
}

class $$DownloadJobLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadJobLocalTable,
          DownloadJobLocalData,
          $$DownloadJobLocalTableFilterComposer,
          $$DownloadJobLocalTableOrderingComposer,
          $$DownloadJobLocalTableAnnotationComposer,
          $$DownloadJobLocalTableCreateCompanionBuilder,
          $$DownloadJobLocalTableUpdateCompanionBuilder,
          (DownloadJobLocalData, BaseReferences<_$AppDatabase, $DownloadJobLocalTable, DownloadJobLocalData>),
          DownloadJobLocalData,
          PrefetchHooks Function()
        > {
  $$DownloadJobLocalTableTableManager(_$AppDatabase db, $DownloadJobLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$DownloadJobLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$DownloadJobLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$DownloadJobLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> request = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String> libraryItemIds = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobLocalCompanion(
                id: id,
                request: request,
                stage: stage,
                errorMessage: errorMessage,
                libraryItemIds: libraryItemIds,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String request,
                required String stage,
                Value<String?> errorMessage = const Value.absent(),
                Value<String> libraryItemIds = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadJobLocalCompanion.insert(
                id: id,
                request: request,
                stage: stage,
                errorMessage: errorMessage,
                libraryItemIds: libraryItemIds,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadJobLocalTable, DownloadJobLocalData>(table),
                  BaseReferences<_$AppDatabase, $DownloadJobLocalTable, DownloadJobLocalData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadJobLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadJobLocalTable,
      DownloadJobLocalData,
      $$DownloadJobLocalTableFilterComposer,
      $$DownloadJobLocalTableOrderingComposer,
      $$DownloadJobLocalTableAnnotationComposer,
      $$DownloadJobLocalTableCreateCompanionBuilder,
      $$DownloadJobLocalTableUpdateCompanionBuilder,
      (DownloadJobLocalData, BaseReferences<_$AppDatabase, $DownloadJobLocalTable, DownloadJobLocalData>),
      DownloadJobLocalData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValueLocalTableTableManager get keyValueLocal => $$KeyValueLocalTableTableManager(_db, _db.keyValueLocal);
  $$ErrorLogLocalTableTableManager get errorLogLocal => $$ErrorLogLocalTableTableManager(_db, _db.errorLogLocal);
  $$LibraryItemLocalTableTableManager get libraryItemLocal =>
      $$LibraryItemLocalTableTableManager(_db, _db.libraryItemLocal);
  $$DownloadJobLocalTableTableManager get downloadJobLocal =>
      $$DownloadJobLocalTableTableManager(_db, _db.downloadJobLocal);
}
