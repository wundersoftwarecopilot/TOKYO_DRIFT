import 'package:drift/drift.dart';

class ExampleUsers extends Table {
  IntColumn get id => int().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  IntColumn get createdAt => int()();
}

class ExampleOrders extends Table {
  IntColumn get id => int().autoIncrement()();
  IntColumn get userId => int()();
  RealColumn get total => real()();
  TextColumn get status => text()();
}

Future<void> seedNewDatabase2Database(GeneratedDatabase db) async {
  // No seed data available for this schema.
}


MigrationStrategy buildNewDatabase2DatabaseMigration(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedNewDatabase2Database(db);
    },
    onUpgrade: (m, from, to) async {
      await m.createAll();
      await seedNewDatabase2Database(db);
    },
  );
}

// Usage:
// @override
// MigrationStrategy get migration => buildNewDatabase2DatabaseMigration(this);

