import 'package:drift/drift.dart';

class Customers extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get active => int()();
}

class Categories extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get active => int()();
}

class Products extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => int()();
  IntColumn get categoryId => int()();
}

class Sales extends Table {
  IntColumn get id => int().autoIncrement()();
  IntColumn get customerId => int()();
  RealColumn get total => real()();
}

Future<void> seedTestDatabase(GeneratedDatabase db) async {
  await db.batch((batch) {
    batch.execute('INSERT INTO customers ("id", "name", "email", "phone", "active") VALUES (1, 'John Doe', 'john@email.com', '555-0123', 1);');
    batch.execute('INSERT INTO customers ("id", "name", "email", "phone", "active") VALUES (2, 'Jane Smith', 'jane@email.com', '555-0124', 1);');
    batch.execute('INSERT INTO customers ("id", "name", "email", "phone", "active") VALUES (3, 'Bob Johnson', 'bob@email.com', '555-0125', 0);');
    batch.execute('INSERT INTO customers ("id", "name", "email", "phone", "active") VALUES (4, 'Alice Johnson', 'alice@email.com', '555-0001', 1);');
  });
}


MigrationStrategy buildTestDatabaseMigration(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedTestDatabase(db);
    },
    onUpgrade: (m, from, to) async {
      await m.createAll();
      await seedTestDatabase(db);
    },
  );
}

// Usage:
// @override
// MigrationStrategy get migration => buildTestDatabaseMigration(this);

