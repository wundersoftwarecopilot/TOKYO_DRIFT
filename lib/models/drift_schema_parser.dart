import 'dart:io';

class DriftSchemaParser {
  static Future<DriftSchemaInfo> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Drift file does not exist: $filePath');
    }

    final content = await file.readAsString();
    return _parseContent(content, filePath);
  }

  static DriftSchemaInfo _parseContent(String content, String filePath) {
    final tables = <DriftTableInfo>[];
    final lines = content.split('\n');

    String? currentTableName;
    List<DriftColumnInfo> currentColumns = [];
    bool inTableClass = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Detectar inicio de clase tabla
      if (line.startsWith('class ') && line.contains('extends Table')) {
        final match = RegExp(
          r'class\s+(\w+)\s+extends\s+Table',
        ).firstMatch(line);
        if (match != null) {
          currentTableName = match.group(1);
          currentColumns = [];
          inTableClass = true;
        }
      }
      // Detectar fin de clase tabla
      else if (inTableClass && line == '}') {
        if (currentTableName != null && currentColumns.isNotEmpty) {
          tables.add(
            DriftTableInfo(
              name: currentTableName,
              columns: List.from(currentColumns),
            ),
          );
        }
        inTableClass = false;
        currentTableName = null;
        currentColumns = [];
      }
      // Detectar columnas dentro de clase tabla
      else if (inTableClass && line.contains('=>')) {
        final columnInfo = _parseColumnDefinition(line);
        if (columnInfo != null) {
          currentColumns.add(columnInfo);
        }
      }
    }

    // Extraer nombre de la base de datos de la anotación @DriftDatabase
    String? databaseName;
    final dbMatch = RegExp(r'@DriftDatabase\s*\([^)]*\)').firstMatch(content);
    if (dbMatch != null) {
      final classMatch = RegExp(
        r'class\s+(\w+)\s+extends',
      ).firstMatch(content.substring(dbMatch.end));
      if (classMatch != null) {
        databaseName = classMatch.group(1);
      }
    }

    return DriftSchemaInfo(
      filePath: filePath,
      databaseName: databaseName ?? 'UnknownDatabase',
      tables: tables,
    );
  }

  static DriftColumnInfo? _parseColumnDefinition(String line) {
    // Ejemplos de líneas a parsear:
    // IntColumn get id => integer().autoIncrement()();
    // TextColumn get nombre => text()();
    // RealColumn get peso => real()();
    // DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();

    final getMatch = RegExp(
      r'(\w+)\s+get\s+(\w+)\s*=>\s*(.+)',
    ).firstMatch(line);
    if (getMatch == null) return null;

    final columnType = getMatch.group(1)!;
    final columnName = getMatch.group(2)!;
    final definition = getMatch.group(3)!;

    // Determinar tipo SQL equivalente
    String sqlType;
    switch (columnType) {
      case 'IntColumn':
        sqlType = 'INTEGER';
        break;
      case 'TextColumn':
        sqlType = 'TEXT';
        break;
      case 'RealColumn':
        sqlType = 'REAL';
        break;
      case 'DateTimeColumn':
        sqlType = 'INTEGER'; // Drift almacena DateTime como Unix timestamp
        break;
      case 'BoolColumn':
        sqlType = 'INTEGER'; // Drift almacena bool como 0/1
        break;
      default:
        sqlType = 'TEXT';
    }

    // Detectar constraints
    final isPrimaryKey = definition.contains('autoIncrement()');
    final isNotNull = !definition.contains('nullable()');
    final hasDefault =
        definition.contains('withDefault(') ||
        definition.contains('clientDefault(');

    return DriftColumnInfo(
      name: columnName,
      dartType: columnType,
      sqlType: sqlType,
      isPrimaryKey: isPrimaryKey,
      isNotNull: isNotNull,
      hasDefault: hasDefault,
    );
  }
}

class DriftSchemaInfo {
  final String filePath;
  final String databaseName;
  final List<DriftTableInfo> tables;

  DriftSchemaInfo({
    required this.filePath,
    required this.databaseName,
    required this.tables,
  });

  String get fileName => filePath.split(Platform.pathSeparator).last;

  int get size => File(filePath).lengthSync();

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class DriftTableInfo {
  final String name;
  final List<DriftColumnInfo> columns;

  DriftTableInfo({required this.name, required this.columns});

  String get sqlTableName => _camelCaseToSnakeCase(name);

  static String _camelCaseToSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .substring(1); // Remove leading underscore
  }
}

class DriftColumnInfo {
  final String name;
  final String dartType;
  final String sqlType;
  final bool isPrimaryKey;
  final bool isNotNull;
  final bool hasDefault;

  DriftColumnInfo({
    required this.name,
    required this.dartType,
    required this.sqlType,
    required this.isPrimaryKey,
    required this.isNotNull,
    required this.hasDefault,
  });
}
