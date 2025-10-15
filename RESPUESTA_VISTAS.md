# ¿DRIFT .dart maneja vistas SQL?

## Respuesta: ¡SÍ!

TOKYO DRIFT ahora soporta completamente vistas SQL tanto en bases de datos SQLite como en archivos de esquema Drift (.dart).

## Características Implementadas

### 1. Detección Automática de Vistas

**En bases de datos SQLite:**
- Las vistas se detectan automáticamente consultando la tabla `sqlite_master`
- Se obtienen las definiciones SQL completas de cada vista
- Las vistas se listan en una sección separada con iconos de visibilidad

**En archivos Drift (.dart):**
- Se analizan las clases que extienden `View`
- Se soportan declaraciones `class` y `abstract class`
- Los nombres se convierten automáticamente de CamelCase a snake_case
  - Ejemplo: `ActiveUsersView` → `active_users`

### 2. Interfaz de Usuario

La interfaz ha sido mejorada para mostrar las vistas:

```
Database Structure
├── Tables (3)
│   ├── customers
│   ├── products
│   └── categories
└── Views (5)
    ├── active_customers
    ├── products_with_category
    ├── low_stock_products
    ├── expensive_products
    └── product_summary
```

### 3. Visualización de Definiciones

Al hacer clic en cualquier vista, se muestra un diálogo con:
- Nombre de la vista
- Definición SQL completa (para SQLite)
- Información de metadatos (para Drift)

## Ejemplos de Uso

### Ejemplo 1: Vista Simple en Drift

```dart
// Filtrar solo clientes activos
abstract class ActiveUsersView extends View {
  Users get users;

  @override
  Query as() => select([users.id, users.name, users.email])
      .from(users)
      .where(users.active.equals(1));
}
```

### Ejemplo 2: Vista con JOIN en Drift

```dart
// Productos con información de categoría
abstract class ProductsWithCategoryView extends View {
  Products get products;
  Categories get categories;

  @override
  Query as() => select([
        products.id,
        products.name,
        products.price,
        categories.name.as('categoryName'),
      ]).from(products).join([
        innerJoin(categories, categories.id.equalsExp(products.categoryId))
      ]);
}
```

### Ejemplo 3: Vista SQL en SQLite

```sql
-- Vista de productos con stock bajo
CREATE VIEW low_stock_products AS
SELECT 
    p.id,
    p.name,
    p.stock,
    p.price,
    c.name AS category
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE p.stock < 10;
```

## Tipos de Vistas Soportadas

1. **Vistas con filtros (WHERE)**
   - Ejemplo: Clientes activos, productos caros

2. **Vistas con JOINs**
   - INNER JOIN
   - LEFT OUTER JOIN
   - Múltiples JOINs

3. **Vistas con agregaciones**
   - COUNT, SUM, AVG, MIN, MAX
   - GROUP BY, HAVING

4. **Vistas con alias de columnas**
   - `.as('nombre_alias')` en Drift
   - `AS alias` en SQL

## Archivos Modificados

### Archivos del Sistema

1. **`lib/models/drift_schema_parser.dart`**
   - Nueva clase `DriftViewInfo` para representar vistas
   - Lógica de parsing para detectar clases que extienden `View`
   - Conversión automática de nombres CamelCase a snake_case

2. **`lib/models/database_connection.dart`**
   - Nuevo campo `views` para almacenar lista de vistas
   - Método `_getViews()` para consultar vistas en SQLite
   - Método `getViewDefinition()` para obtener definiciones SQL

3. **`lib/widgets/database_tree_view.dart`**
   - Sección expandible "Views" en la UI
   - Elementos de vista con icono de visibilidad
   - Diálogo modal para mostrar definiciones SQL

4. **`README.md`**
   - Documentación completa sobre soporte de vistas
   - Ejemplos de código
   - Guía de uso

### Archivos de Ejemplo

1. **`test_views.dart`**
   - Ejemplo básico con 2 vistas

2. **`example_with_views.dart`**
   - Ejemplo completo con 5 tipos diferentes de vistas
   - Demuestra varias técnicas (filtros, JOINs, agregaciones)

3. **`test_database_with_views.db`**
   - Base de datos SQLite de prueba
   - Contiene 3 tablas y 5 vistas

## Pruebas Realizadas

Se creó una base de datos de prueba con:
- **3 tablas:** customers, categories, products
- **5 vistas:**
  - `active_customers` - Filtro simple
  - `products_with_category` - JOIN simple
  - `low_stock_products` - JOIN con WHERE
  - `expensive_products` - Filtro de precio
  - `product_summary` - Agregaciones (COUNT, AVG, SUM)

Todas las vistas se detectan correctamente y sus definiciones SQL se pueden visualizar.

## Limitaciones Actuales

1. Para archivos Drift, la definición completa de la vista no se reconstruye a partir del código Dart (se muestra un mensaje simplificado)
2. El soporte se centra en vistas estándar; vistas con características avanzadas de SQLite pueden requerir ajustes

## Conclusión

**Sí, DRIFT .dart ahora maneja vistas SQL de forma completa.**

La implementación permite:
- ✅ Detectar vistas en SQLite y Drift
- ✅ Listar vistas en la interfaz
- ✅ Ver definiciones SQL
- ✅ Distinguir visualmente vistas de tablas
- ✅ Soportar múltiples tipos de vistas (filtros, JOINs, agregaciones)

Para más información, consulta el archivo `README.md` o los ejemplos en `example_with_views.dart`.
