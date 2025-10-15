import 'package:drift/drift.dart';

class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get email => text()();
  IntColumn get fechaRegistro => integer()();
  IntColumn get activo => integer()();
}

class Productos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  RealColumn get precio => real()();
  IntColumn get stock => integer()();
}

class Pedidos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get usuarioId => integer()();
  IntColumn get fecha => integer()();
  RealColumn get total => real()();
  TextColumn get estado => text()();
}

class DetallesPedido extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get pedidoId => integer()();
  IntColumn get productoId => integer()();
  IntColumn get cantidad => integer()();
  RealColumn get precioUnitario => real()();
}
