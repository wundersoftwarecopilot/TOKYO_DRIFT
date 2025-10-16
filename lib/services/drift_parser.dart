import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';

class DriftTable {
  final String className;
  final String tableName;
  final List<DriftColumn> columns;
  final List<Map<String, dynamic>> rows;

  DriftTable({
    required this.className,
    required this.tableName,
    required this.columns,
    this.rows = const [],
  });
}

class DriftColumn {
  final String name;
  final String type;
  final bool isNullable;
  final bool isAutoIncrement;
  final bool isPrimaryKey;
  final String? defaultValue;

  DriftColumn({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.isAutoIncrement = false,
    this.isPrimaryKey = false,
    this.defaultValue,
  });

  String toSqlType() {
    switch (type) {
      case 'IntColumn':
        return 'INTEGER';
      case 'TextColumn':
        return 'TEXT';
      case 'RealColumn':
        return 'REAL';
      case 'BoolColumn':
        return 'INTEGER'; // SQLite uses INTEGER for booleans
      case 'DateTimeColumn':
        return 'INTEGER'; // Unix timestamp
      case 'BlobColumn':
        return 'BLOB';
      default:
        return 'TEXT';
    }
  }

  String toSqlDefinition() {
    var sql = '$name ${toSqlType()}';

    if (isPrimaryKey) sql += ' PRIMARY KEY';
    if (isAutoIncrement) sql += ' AUTOINCREMENT';
    if (!isNullable && !isPrimaryKey) sql += ' NOT NULL';
    if (defaultValue != null) sql += ' DEFAULT $defaultValue';

    return sql;
  }

  String toDriftCode() {
    var baseType = type.toLowerCase().replaceAll('column', '');
    var code = '$type get $name => $baseType()';

    if (isAutoIncrement) code += '.autoIncrement()';
    if (isNullable) code += '.nullable()';

    code += '();'; // Add () at the end for modern Drift syntax
    return code;
  }
}

class DriftParser {
  static List<DriftTable> parseDriftFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final content = file.readAsStringSync();
    final tables = <DriftTable>[];

    // Find classes that extend Table
    final classRegex = RegExp(
      r'class\s+(\w+)\s+extends\s+Table\s*\{([^}]+)\}',
      multiLine: true,
      dotAll: true,
    );
    final matches = classRegex.allMatches(content);

    for (final match in matches) {
      final className = match.group(1)!;
      final classBody = match.group(2)!;
      final tableName = _classNameToTableName(className);

      final columns = _parseColumns(classBody);

      tables.add(
        DriftTable(
          className: className,
          tableName: tableName,
          columns: columns,
          rows: const [],
        ),
      );
    }

    return tables;
  }

  static List<DriftColumn> _parseColumns(String classBody) {
    final columns = <DriftColumn>[];

    // Find getters that return columns
    final columnRegex = RegExp(
      r'(\w+Column)\s+get\s+(\w+)\s+=>\s+(\w+)\(\)([^;]*);',
      multiLine: true,
    );
    final matches = columnRegex.allMatches(classBody);

    for (final match in matches) {
      final columnType = match.group(1)!;
      final columnName = match.group(2)!;
      final modifiers = match.group(4) ?? '';

      final isAutoIncrement = modifiers.contains('autoIncrement()');
      final isNullable = modifiers.contains('nullable()');
      final isPrimaryKey =
          isAutoIncrement; // Auto increment implies primary key

      columns.add(
        DriftColumn(
          name: columnName,
          type: columnType,
          isAutoIncrement: isAutoIncrement,
          isNullable: isNullable,
          isPrimaryKey: isPrimaryKey,
        ),
      );
    }

    return columns;
  }

  static String _classNameToTableName(String className) {
    // Convert CamelCase to snake_case
    return className
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .substring(1); // Remove first _
  }

  static Database createTempDatabase(List<DriftTable> tables) {
    final db = sqlite3.openInMemory();

    for (final table in tables) {
      final columnDefs = table.columns
          .map((col) => col.toSqlDefinition())
          .join(', ');
      final createSql = 'CREATE TABLE ${table.tableName} ($columnDefs)';

      try {
        db.execute(createSql);
        print('Table created: ${table.tableName}');
      } catch (e) {
        print('Error creating table ${table.tableName}: $e');
      }
    }

    return db;
  }

  static void updateDriftFile(String filePath, List<DriftTable> tables) {
    final file = File(filePath);

    // Create new file content
    final buffer = StringBuffer();
    buffer.writeln("import 'package:drift/drift.dart';");
    buffer.writeln();

    for (final table in tables) {
      buffer.writeln('class ${table.className} extends Table {');
      for (final column in table.columns) {
        buffer.writeln('  ${column.toDriftCode()}');
      }
      buffer.writeln('}');
      buffer.writeln();
    }

    final databaseClassName = _fileNameToDatabaseClassName(filePath);
    buffer.writeln(_generateSeedFunction(databaseClassName, tables));
    buffer.writeln();
    buffer.writeln(_generateMigrationBuilder(databaseClassName));

    // Write updated file
    file.writeAsStringSync(buffer.toString());
    print('Drift file updated: $filePath');
  }

  static List<DriftTable> extractTablesFromDatabase(Database db) {
    final tables = <DriftTable>[];

    // Get table list
    final tableNames = db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );

    for (final tableRow in tableNames) {
      final tableName = tableRow['name'] as String;
      final className = _tableNameToClassName(tableName);

      // Get column information
      final columnInfo = db.select("PRAGMA table_info($tableName)");
      final columns = <DriftColumn>[];

      for (final colRow in columnInfo) {
        final name = colRow['name'] as String;
        final type = colRow['type'] as String;
        final notNull = (colRow['notnull'] as int) == 1;
        final isPk = (colRow['pk'] as int) == 1;

        final driftType = _sqlTypeToDriftType(type);

        columns.add(
          DriftColumn(
            name: name,
            type: driftType,
            isNullable: !notNull && !isPk,
            isPrimaryKey: isPk,
            isAutoIncrement:
                isPk &&
                driftType == 'IntColumn', // Assume autoincrement for integer PK
          ),
        );
      }

      final dataRows = db.select('SELECT * FROM "$tableName"');
      final rows = dataRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);

      tables.add(
        DriftTable(
          className: className,
          tableName: tableName,
          columns: columns,
          rows: rows,
        ),
      );
    }

    return tables;
  }

  static String _tableNameToClassName(String tableName) {
    // If already in CamelCase, keep it
    if (tableName.contains('_')) {
      // Convert snake_case to CamelCase
      return tableName
          .split('_')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '',
          )
          .join('');
    } else {
      // If no underscores, assume it's already in correct format
      return tableName[0].toUpperCase() + tableName.substring(1);
    }
  }

  static String _sqlTypeToDriftType(String sqlType) {
    final upperType = sqlType.toUpperCase();
    if (upperType.contains('INT')) return 'IntColumn';
    if (upperType.contains('TEXT') || upperType.contains('VARCHAR')) {
      return 'TextColumn';
    }
    if (upperType.contains('REAL') ||
        upperType.contains('FLOAT') ||
        upperType.contains('DOUBLE')) {
      return 'RealColumn';
    }
    if (upperType.contains('BLOB')) return 'BlobColumn';
    return 'TextColumn'; // Default
  }

  static String _fileNameToDatabaseClassName(String filePath) {
    final fileName = filePath
        .split(Platform.pathSeparator)
        .last
        .replaceAll('.dart', '');
    final parts = fileName
        .split(RegExp(r'[_\-]+'))
        .where((part) => part.isNotEmpty);
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part[0].toUpperCase());
      if (part.length > 1) {
        buffer.write(part.substring(1));
      }
    }
    var className = buffer.isEmpty ? 'SeededDatabase' : buffer.toString();
    if (!className.toLowerCase().endsWith('database')) {
      className = '${className}Database';
    }
    return className;
  }

  static String _generateSeedFunction(
    String databaseClassName,
    List<DriftTable> tables,
  ) {
    final seedName = 'seed$databaseClassName';
    final buffer = StringBuffer();
    buffer.writeln('Future<void> $seedName(GeneratedDatabase db) async {');

    final hasRows = tables.any((table) => table.rows.isNotEmpty);
    if (!hasRows) {
      buffer.writeln('  // No seed data available for this schema.');
      buffer.writeln('}');
      return buffer.toString();
    }

    buffer.writeln('  await db.batch((batch) {');
    for (final table in tables) {
      if (table.rows.isEmpty) continue;
      for (final row in table.rows) {
        final columns = row.keys.map((column) => '"$column"').join(', ');
        final values = row.keys
            .map((column) => _sqlLiteral(row[column]))
            .join(', ');
        buffer.writeln(
          "    batch.execute('INSERT INTO ${table.tableName} ($columns) VALUES ($values);');",
        );
      }
    }
    buffer.writeln('  });');
    buffer.writeln('}');
    return buffer.toString();
  }

  static String _generateMigrationBuilder(String databaseClassName) {
    final seedName = 'seed$databaseClassName';
    final builderName = 'build${databaseClassName}Migration';
    final buffer = StringBuffer();
    buffer.writeln('MigrationStrategy $builderName(GeneratedDatabase db) {');
    buffer.writeln('  return MigrationStrategy(');
    buffer.writeln('    onCreate: (m) async {');
    buffer.writeln('      await m.createAll();');
    buffer.writeln('      await $seedName(db);');
    buffer.writeln('    },');
    buffer.writeln('    onUpgrade: (m, from, to) async {');
    buffer.writeln('      await m.createAll();');
    buffer.writeln('      await $seedName(db);');
    buffer.writeln('    },');
    buffer.writeln('  );');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('// Usage:');
    buffer.writeln('// @override');
    buffer.writeln('// MigrationStrategy get migration => $builderName(this);');
    return buffer.toString();
  }

  static void executeSeedData(Database db, String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return;

    final content = file.readAsStringSync();

    // Find the seed function - look for function starting with "seed" and ending with "Database"
    final seedFunctionRegex = RegExp(r'Future<void>\s+(seed\w+Database)\s*\([^)]*\)\s*async\s*\{([^}]+)\}', multiLine: true, dotAll: true);

    final seedMatch = seedFunctionRegex.firstMatch(content);
    if (seedMatch == null) {
      print('No seed function found in file');
      return;
    }

    final seedBody = seedMatch.group(2)!;

    // Split by lines and process each batch.execute line
    final lines = seedBody.split('\n');
    int executedCount = 0;

    for (final line in lines) {
      if (line.contains('batch.execute(')) {
        // Extract SQL between the first ' and last ');
        final startIndex = line.indexOf("'");
        final endIndex = line.lastIndexOf("');");

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          final sql = line.substring(startIndex + 1, endIndex);
          try {
            db.execute(sql);
            executedCount++;
          } catch (e) {
            print('Error executing seed SQL: $e');
          }
        }
      }
    }

    print('Total seed statements executed: $executedCount');
  }

  static String _sqlLiteral(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is Uint8List) {
      final hex = value
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      return "X'$hex'";
    }
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }
}
