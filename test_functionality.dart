import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'lib/services/drift_parser.dart';

void main() {
  print('=== Probando funcionalidad de DriftParser ===');

  // 1. Parsear el archivo .dart
  final filePath = 'test_schema.dart';
  print('1. Parseando $filePath...');
  final tables = DriftParser.parseDriftFile(filePath);
  print('   Encontradas ${tables.length} tablas: ${tables.map((t) => t.className).join(', ')}');

  // 2. Crear base de datos temporal
  print('2. Creando base de datos temporal...');
  final db = DriftParser.createTempDatabase(tables);
  print('   Base de datos creada');

  // 3. Ejecutar queries de modificación
  print('3. Ejecutando queries de modificación...');

  // Crear nueva tabla
  db.execute('''
    CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      date INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    )
  ''');
  print('   - Tabla orders creada');

  // Insertar datos
  db.execute("INSERT INTO users (name, email, active) VALUES ('Test User', 'test@example.com', 1)");
  db.execute("INSERT INTO products (name, price, stock) VALUES ('Test Product', 99.99, 10)");
  db.execute("INSERT INTO orders (user_id, product_id, quantity, date) VALUES (1, 1, 2, strftime('%s', 'now'))");
  print('   - Datos insertados');

  // 4. Extraer tablas actualizadas
  print('4. Extrayendo tablas actualizadas...');
  final updatedTables = DriftParser.extractTablesFromDatabase(db);
  print('   Extraídas ${updatedTables.length} tablas: ${updatedTables.map((t) => t.className).join(', ')}');

  // Mostrar datos extraídos
  for (final table in updatedTables) {
    print('   - ${table.className}: ${table.rows.length} filas');
  }

  // 5. Actualizar archivo .dart
  print('5. Actualizando archivo .dart...');
  DriftParser.updateDriftFile(filePath, updatedTables);
  print('   Archivo actualizado');

  // 6. Verificar contenido actualizado
  print('6. Verificando contenido actualizado...');
  final updatedContent = File(filePath).readAsStringSync();
  print('   Contenido del archivo:');
  print(updatedContent);

  db.dispose();
  print('=== Prueba completada ===');
}