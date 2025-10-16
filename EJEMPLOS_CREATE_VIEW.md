# Ejemplos de CREATE VIEW para TOKYO DRIFT

## 📋 **Funcionalidades implementadas:**

✅ **Soporte completo para vistas**
✅ **Nueva interfaz con 3 paneles visibles simultáneamente**
✅ **Sincronización automática entre paneles**

## 🎯 **Nueva organización de la interfaz:**

```
┌─────────────────────┬─────────────────────┬─────────────────────┐
│                     │                     │                     │
│    SQL EDITOR       │  DATABASE STRUCTURE │    BROWSE DATA      │
│                     │                     │                     │
├─────────────────────┤                     │                     │
│                     │                     │                     │
│     RESULTS         │                     │                     │
│                     │                     │                     │
└─────────────────────┴─────────────────────┴─────────────────────┘
```

## 🚀 **Ejemplos de CREATE VIEW para probar:**

### 1. **Vista simple de usuarios activos:**
```sql
CREATE VIEW active_users AS 
SELECT id, name, email 
FROM users 
WHERE active = 1;
```

### 2. **Vista de productos caros:**
```sql
CREATE VIEW expensive_products AS 
SELECT name, price, stock 
FROM products 
WHERE price > 50;
```

### 3. **Vista con JOIN (si tienes tabla orders):**
```sql
CREATE VIEW user_order_summary AS 
SELECT 
    u.name as user_name,
    u.email,
    COUNT(o.id) as order_count,
    SUM(o.total) as total_spent
FROM users u 
LEFT JOIN orders o ON u.id = o.user_id 
GROUP BY u.id, u.name, u.email;
```

### 4. **Vista con cálculos:**
```sql
CREATE VIEW product_value AS 
SELECT 
    name,
    price,
    stock,
    (price * stock) as total_value,
    CASE 
        WHEN stock = 0 THEN 'Out of Stock'
        WHEN stock < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END as stock_status
FROM products;
```

## 🎨 **Características visuales:**

- **Tablas**: Icono azul 📊, color primario
- **Vistas**: Icono púrpura 👁️, color secundario, etiqueta "VIEW"
- **Navegación**: Tree view expandible con conteo de objetos
- **Sincronización**: Los 3 paneles se actualizan al seleccionar tabla/vista

## 📝 **Comandos útiles:**

### Ver todas las vistas:
```sql
SELECT name FROM sqlite_master WHERE type='view';
```

### Ver definición de una vista:
```sql
SELECT sql FROM sqlite_master WHERE name='active_users' AND type='view';
```

### Eliminar una vista:
```sql
DROP VIEW active_users;
```

### Consultar una vista:
```sql
SELECT * FROM active_users;
```

## 🔄 **Flujo de trabajo recomendado:**

1. **Crear tablas** con datos de prueba
2. **Crear vistas** basadas en esas tablas
3. **Seleccionar vista** en el tree view (aparecerá en la sección "Views")
4. **Ver estructura** en el panel central
5. **Ver datos** en el panel derecho
6. **Ejecutar queries** en el panel izquierdo superior
7. **Ver resultados** en el panel izquierdo inferior

¡Disfruta explorando las nuevas funcionalidades de vistas en TOKYO DRIFT! 🚀