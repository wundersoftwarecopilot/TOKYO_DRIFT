import 'dart:io';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'drift_schema_parser.dart';

enum DatabaseType { sqlite, driftSchema }

class DatabaseConnection {
  final String name;
  final String path;
  final DatabaseType type;
  final sql.Database? _sqlite3Db;
  final DriftSchemaInfo? _driftSchema;
  final List<String> tables;
  final int size;

  DatabaseConnection._({
    required this.name,
    required this.path,
    required this.type,
    sql.Database? sqlite3Db,
    DriftSchemaInfo? driftSchema,
    required this.tables,
    required this.size,
  }) : _sqlite3Db = sqlite3Db,
       _driftSchema = driftSchema;

  static Future<DatabaseConnection> open(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Database file does not exist: $filePath');
    }

    final extension = filePath.toLowerCase().split('.').last;

    if (extension == 'dart') {
      return _openDriftSchema(filePath);
    } else {
      return _openSqliteDatabase(filePath);
    }
  }

  static Future<DatabaseConnection> _openSqliteDatabase(String filePath) async {
    final file = File(filePath);

    // Open with sqlite3 for direct queries
    final sqlite3Db = sql.sqlite3.open(filePath);

    // Get database info
    final tables = await _getTables(sqlite3Db);
    final size = await file.length();

    return DatabaseConnection._(
      name: file.uri.pathSegments.last,
      path: filePath,
      type: DatabaseType.sqlite,
      sqlite3Db: sqlite3Db,
      driftSchema: null,
      tables: tables,
      size: size,
    );
  }

  static Future<DatabaseConnection> _openDriftSchema(String filePath) async {
    final file = File(filePath);

    // Parse Drift schema
    final driftSchema = await DriftSchemaParser.parseFile(filePath);

    // Extract table names
    final tables = driftSchema.tables.map((t) => t.name).toList();
    final size = await file.length();

    return DatabaseConnection._(
      name: file.uri.pathSegments.last,
      path: filePath,
      type: DatabaseType.driftSchema,
      sqlite3Db: null,
      driftSchema: driftSchema,
      tables: tables,
      size: size,
    );
  }

  static Future<List<String>> _getTables(sql.Database db) async {
    final result = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? parameters,
  ]) async {
    if (type != DatabaseType.sqlite) {
      throw Exception('Query operation not supported for Drift schema files');
    }

    try {
      final result = _sqlite3Db!.select(sql, parameters ?? []);
      return result.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      throw Exception('Query error: $e');
    }
  }

  Future<int> execute(String sql, [List<dynamic>? parameters]) async {
    if (type != DatabaseType.sqlite) {
      throw Exception('Execute operation not supported for Drift schema files');
    }

    try {
      final upperSql = sql.trim().toUpperCase();

      if (upperSql.startsWith('SELECT') ||
          upperSql.startsWith('PRAGMA') ||
          upperSql.startsWith('EXPLAIN')) {
        // For SELECT queries, use query method and return row count
        final result = await query(sql, parameters);
        return result.length;
      } else {
        // For INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, etc.
        final initialRowCount = _sqlite3Db!.updatedRows;
        _sqlite3Db.execute(sql, parameters ?? []);
        final finalRowCount = _sqlite3Db.updatedRows;

        // For DDL operations (CREATE, DROP, ALTER), return 0 as they don't affect row count
        if (upperSql.startsWith('CREATE') ||
            upperSql.startsWith('DROP') ||
            upperSql.startsWith('ALTER')) {
          return 0;
        }

        return finalRowCount - initialRowCount;
      }
    } catch (e) {
      throw Exception('Execution error: $e');
    }
  }

  Future<List<ColumnInfo>> getTableSchema(String tableName) async {
    if (type == DatabaseType.sqlite) {
      final result = _sqlite3Db!.select('PRAGMA table_info($tableName)');
      return result
          .map(
            (row) => ColumnInfo(
              name: row['name'] as String,
              type: row['type'] as String,
              notNull: (row['notnull'] as int) == 1,
              defaultValue: row['dflt_value']?.toString(),
              primaryKey: (row['pk'] as int) == 1,
            ),
          )
          .toList();
    } else {
      // Para archivos Drift, obtener schema del parser
      final table = _driftSchema!.tables.firstWhere(
        (t) => t.name == tableName,
        orElse: () => throw Exception('Table $tableName not found'),
      );

      return table.columns
          .map(
            (col) => ColumnInfo(
              name: col.name,
              type: col.sqlType,
              notNull: col.isNotNull,
              defaultValue: col.hasDefault ? 'DEFAULT' : null,
              primaryKey: col.isPrimaryKey,
            ),
          )
          .toList();
    }
  }

  Future<int> getTableRowCount(String tableName) async {
    if (type != DatabaseType.sqlite) {
      // Para archivos Drift, no podemos obtener el conteo real
      return 0;
    }

    final result = _sqlite3Db!.select(
      'SELECT COUNT(*) as count FROM "$tableName"',
    );
    return result.first['count'] as int;
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isReadOnly => type == DatabaseType.driftSchema;

  String get typeDescription {
    switch (type) {
      case DatabaseType.sqlite:
        return 'SQLite Database';
      case DatabaseType.driftSchema:
        return 'Drift Schema';
    }
  }

  void close() {
    _sqlite3Db?.dispose();
  }
}

class ColumnInfo {
  final String name;
  final String type;
  final bool notNull;
  final String? defaultValue;
  final bool primaryKey;

  ColumnInfo({
    required this.name,
    required this.type,
    required this.notNull,
    this.defaultValue,
    required this.primaryKey,
  });
}
