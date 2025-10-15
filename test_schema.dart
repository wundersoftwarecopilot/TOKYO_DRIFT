import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  IntColumn get active => int()();
  TextColumn get telephone => text().nullable()();
}

class Products extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => int()();
}

Future<void> seedTestSchemaDatabase(GeneratedDatabase db) async {
  await db.batch((batch) {
    batch.execute('INSERT INTO users ("id", "name", "email", "active", "telephone") VALUES (1, 'Nuevo Usuario', 'nuevo@email.com', 1, '0000000000');');
    batch.execute('INSERT INTO users ("id", "name", "email", "active", "telephone") VALUES (2, 'Juan Pérez', 'juan@email.com', 1, '0000000000');');
    batch.execute('INSERT INTO products ("id", "name", "description", "price", "stock") VALUES (1, 'Nuevo Producto', NULL, 29.99, 5);');
  });
}


MigrationStrategy buildTestSchemaDatabaseMigration(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedTestSchemaDatabase(db);
    },
    onUpgrade: (m, from, to) async {
      await m.createAll();
      await seedTestSchemaDatabase(db);
    },
  );
}

// Usage:
// @override
// MigrationStrategy get migration => buildTestSchemaDatabaseMigration(this);

