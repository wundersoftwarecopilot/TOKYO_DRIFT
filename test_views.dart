import 'package:drift/drift.dart';

// Example tables
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  IntColumn get active => integer()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  IntColumn get categoryId => integer()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
}

// Example views using @DriftView annotation
abstract class ActiveUsersView extends View {
  Users get users;

  @override
  Query as() => select([users.id, users.name, users.email])
      .from(users)
      .where(users.active.equals(1));
}

abstract class ProductsWithCategory extends View {
  Products get products;
  Categories get categories;

  @override
  Query as() => select([
        products.id,
        products.name,
        products.price,
        products.stock,
        categories.name.as('categoryName'),
      ]).from(products).join([
        innerJoin(categories, categories.id.equalsExp(products.categoryId))
      ]);
}
