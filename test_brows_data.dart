import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'lib/models/database_connection.dart';
import 'lib/services/drift_parser.dart';

void main() async {
  print('=== Verificando BROWS DATA para archivos .dart ===');

  // 1. Abrir el archivo .dart
  print('1. Abriendo test_schema.dart...');
  final dbConnection = await DatabaseConnection.open('test_schema.dart');
  print('   Archivo abierto: ${dbConnection.name}');

  // 2. Verificar que es un archivo Drift
  print('2. Tipo de base de datos: ${dbConnection.typeDescription}');
  print('   Es read-only: ${dbConnection.isReadOnly}');

  // 3. Verificar tablas disponibles
  print('3. Tablas disponibles: ${dbConnection.tables.join(', ')}');

  // 4. Para cada tabla, intentar obtener datos como lo haría TableViewer
  for (final tableName in dbConnection.tables) {
    print('\n4. Probando tabla: $tableName');

    try {
      // Obtener esquema
      final columns = await dbConnection.getTableSchema(tableName);
      print('   Columnas: ${columns.map((c) => c.name).join(', ')}');

      // Para archivos Drift, crear base de datos temporal como hace TableViewer
      if (dbConnection.type == DatabaseType.driftSchema) {
        print('   Creando base de datos temporal para Drift...');

        // Parsear archivo Drift
        final driftTables = DriftParser.parseDriftFile(dbConnection.path);
        print('   Tablas encontradas en parser: ${driftTables.map((t) => t.tableName).join(', ')}');

        final driftTable = driftTables.firstWhere(
          (t) => t.tableName == tableName.toLowerCase(), // Comparar en minúscula
          orElse: () => throw Exception('Table $tableName not found (searched for ${tableName.toLowerCase()})'),
        );

        // Crear base de datos temporal
        final tempDb = DriftParser.createTempDatabase([driftTable]);

        // Ejecutar seed data
        DriftParser.executeSeedData(tempDb, dbConnection.path);

        // Obtener datos
        final data = tempDb.select('SELECT * FROM "$tableName"');
        print('   Filas encontradas: ${data.length}');

        if (data.isNotEmpty) {
          print('   Muestra de datos:');
          for (final row in data.take(3)) {
            print('     $row');
          }
        }

        tempDb.dispose();
      }
    } catch (e) {
      print('   Error: $e');
    }
  }

  dbConnection.close();
  print('\n=== Verificación completada ===');
}