import 'lib/services/drift_parser.dart';

void main() {
  print('=== Verificando carga de seed data ===');

  // 1. Parsear el archivo .dart
  final filePath = 'test_schema.dart';
  print('1. Parseando $filePath...');
  final tables = DriftParser.parseDriftFile(filePath);
  print('   Encontradas ${tables.length} tablas');

  // 2. Crear base de datos temporal
  print('2. Creando base de datos temporal...');
  final db = DriftParser.createTempDatabase(tables);
  print('   Base de datos creada');

  // 3. Verificar datos iniciales (deberían ser 0)
  print('3. Datos iniciales:');
  for (final table in tables) {
    final count = db.select('SELECT COUNT(*) as count FROM ${table.tableName}').first['count'];
    print('   ${table.tableName}: $count filas');
  }

  // 4. Ejecutar seed data
  print('4. Ejecutando seed data...');
  DriftParser.executeSeedData(db, filePath);
  print('   Seed data ejecutado');

  // 5. Verificar datos después del seed
  print('5. Datos después del seed:');
  for (final table in tables) {
    final count = db.select('SELECT COUNT(*) as count FROM ${table.tableName}').first['count'];
    print('   ${table.tableName}: $count filas');
    if (count > 0) {
      final rows = db.select('SELECT * FROM ${table.tableName} LIMIT 3');
      print('     Muestra de datos:');
      for (final row in rows) {
        print('       $row');
      }
    }
  }

  db.dispose();
  print('=== Verificación completada ===');
}