import 'package:drift/drift.dart';

// ============================================================================
// TABLES
// ============================================================================

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get active => integer()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get active => integer()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  IntColumn get categoryId => integer()();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer()();
  IntColumn get orderDate => integer()();
  TextColumn get status => text()();
  RealColumn get total => real()();
}

// ============================================================================
// VIEWS
// ============================================================================

// View 1: Active customers only
abstract class ActiveCustomersView extends View {
  Customers get customers;

  @override
  Query as() => select([
        customers.id,
        customers.name,
        customers.email,
        customers.phone,
      ]).from(customers).where(customers.active.equals(1));
}

// View 2: Products with their category information
abstract class ProductsWithCategoryView extends View {
  Products get products;
  Categories get categories;

  @override
  Query as() => select([
        products.id,
        products.name,
        products.description,
        products.price,
        products.stock,
        categories.name.as('categoryName'),
      ]).from(products).join([
        innerJoin(
          categories,
          categories.id.equalsExp(products.categoryId),
        )
      ]);
}

// View 3: Customer orders summary
abstract class CustomerOrdersSummaryView extends View {
  Customers get customers;
  Orders get orders;

  @override
  Query as() => select([
        customers.id,
        customers.name,
        customers.email,
      ]).from(customers).join([
        leftOuterJoin(orders, orders.customerId.equalsExp(customers.id))
      ]);
}

// View 4: Low stock products (demonstrates WHERE clause)
abstract class LowStockProductsView extends View {
  Products get products;
  Categories get categories;

  @override
  Query as() => select([
        products.id,
        products.name,
        products.stock,
        products.price,
        categories.name.as('categoryName'),
      ]).from(products).join([
        innerJoin(categories, categories.id.equalsExp(products.categoryId))
      ]).where(products.stock.isSmallerThanValue(10));
}

// View 5: Expensive products (price > 100)
abstract class ExpensiveProductsView extends View {
  Products get products;

  @override
  Query as() => select([
        products.id,
        products.name,
        products.price,
        products.stock,
      ]).from(products).where(products.price.isBiggerThanValue(100));
}
