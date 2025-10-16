import 'dart:io';
import 'lib/services/drift_parser.dart';

void main() {
  print('=== Verificando guardado de INSERTs ===');

  // 1. Parsear el archivo .dart
  final filePath = 'test_schema.dart';
  print('1. Parseando $filePath...');
  final tables = DriftParser.parseDriftFile(filePath);
  print('   Encontradas ${tables.length} tablas');

  // 2. Crear base de datos temporal
  print('2. Creando base de datos temporal...');
  final db = DriftParser.createTempDatabase(tables);
  print('   Base de datos creada');

  // 3. Verificar datos iniciales
  print('3. Datos iniciales:');
  for (final table in tables) {
    final count = db.select('SELECT COUNT(*) as count FROM ${table.tableName}').first['count'];
    print('   ${table.tableName}: $count filas');
  }

  // 4. Ejecutar INSERTs
  print('4. Ejecutando INSERTs...');
  db.execute("INSERT INTO users (name, email, active) VALUES ('Nuevo Usuario', 'nuevo@email.com', 1)");
  db.execute("INSERT INTO products (name, price, stock) VALUES ('Nuevo Producto', 29.99, 5)");
  db.execute("INSERT INTO orders (user_id, product_id, quantity, date) VALUES (1, 1, 1, strftime('%s', 'now'))");
  print('   INSERTs ejecutados');

  // 5. Verificar datos después de INSERTs
  print('5. Datos después de INSERTs:');
  final allTables = DriftParser.extractTablesFromDatabase(db);
  for (final table in allTables) {
    print('   ${table.tableName}: ${table.rows.length} filas');
    if (table.rows.isNotEmpty) {
      print('     Primera fila: ${table.rows.first}');
    }
  }

  // 6. Actualizar archivo .dart
  print('6. Actualizando archivo .dart...');
  DriftParser.updateDriftFile(filePath, allTables);
  print('   Archivo actualizado');

  // 7. Verificar contenido actualizado
  print('7. Verificando contenido actualizado...');
  final updatedContent = File(filePath).readAsStringSync();
  final seedFunctionStart = updatedContent.indexOf('Future<void> seedTestSchemaDatabase');
  final seedFunctionEnd = updatedContent.indexOf('}', seedFunctionStart) + 1;
  final seedFunction = updatedContent.substring(seedFunctionStart, seedFunctionEnd);
  print('   Función seed:');
  print(seedFunction);

  db.dispose();
  print('=== Verificación completada ===');
}