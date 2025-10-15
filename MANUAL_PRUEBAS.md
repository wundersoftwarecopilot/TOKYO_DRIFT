# Testing Manual - Drift Admin

## Test Database: test_database.dart

The test database includes the following tables:

- **Customers**: ID, name, email, phone, active
- **Categories**: ID, name, description, active  
- **Products**: ID, name, description, price, stock, categoryId
- **Sales**: ID, customerId, total

## Steps to Test the System

### 1. Load Drift File
1. Run the application
2. Click "Create Working Database"
3. Select the `test_database.dart` file
4. The system will automatically create a temporary SQLite database

### 2. SQL Query Examples

#### CREATE TABLE (Add new table)
```sql
CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    date TEXT NOT NULL,
    total REAL NOT NULL
);
```

#### ALTER TABLE (Modify existing tables)
```sql
-- Add column to existing table
ALTER TABLE customers ADD COLUMN registration_date TEXT;

-- Add column with default value
ALTER TABLE products ADD COLUMN creation_date TEXT DEFAULT CURRENT_TIMESTAMP;

-- Rename table
ALTER TABLE categories RENAME TO product_categories;
```

#### INSERT (Insert data)
```sql
-- Insert customers
INSERT INTO customers (name, email, phone, active) VALUES 
('John Doe', 'john@email.com', '123-456-7890', 1),
('Jane Smith', 'jane@email.com', '098-765-4321', 1),
('Bob Johnson', 'bob@email.com', NULL, 0);

-- Insert categories
INSERT INTO categories (name, description, active) VALUES 
('Electronics', 'Electronic devices and gadgets', 1),
('Clothing', 'Apparel and accessories', 1),
('Home', 'Home articles', 1);

-- Insert products
INSERT INTO products (name, description, price, stock, category_id) VALUES 
('Smartphone', 'Latest generation smartphone', 599.99, 10, 1),
('Laptop', 'Work laptop computer', 899.99, 5, 1),
('T-shirt', '100% cotton t-shirt', 29.99, 50, 2);
```

#### UPDATE (Update data)
```sql
-- Update product price
UPDATE products SET price = 549.99 WHERE id = 1;

-- Update multiple stock
UPDATE products SET stock = stock - 1 WHERE category_id = 1;

-- Deactivate customer
UPDATE customers SET active = 0 WHERE email = 'bob@email.com';

-- Update with JOIN
UPDATE products 
SET price = price * 1.1 
WHERE category_id IN (SELECT id FROM categories WHERE name = 'Electronics');
```

#### DELETE (Delete data)
```sql
-- Delete specific customer
DELETE FROM customers WHERE id = 3;

-- Delete products without stock
DELETE FROM products WHERE stock = 0;

-- Delete inactive categories
DELETE FROM categories WHERE active = 0;
```

#### SELECT (Queries)
```sql
-- Simple query
SELECT * FROM customers WHERE active = 1;

-- Query with JOIN
SELECT 
    p.name as product,
    p.price,
    c.name as category
FROM products p
JOIN categories c ON p.category_id = c.id;

-- Query with aggregations
SELECT 
    category_id,
    COUNT(*) as total_products,
    AVG(price) as average_price,
    SUM(stock) as total_stock
FROM products 
GROUP BY category_id;
```

#### CREATE VIEW (Create views)
```sql
-- Products with category view
CREATE VIEW products_view AS
SELECT 
    p.id,
    p.name,
    p.price,
    p.stock,
    c.name as category
FROM products p
JOIN categories c ON p.category_id = c.id;

-- Active customers view
CREATE VIEW active_customers AS
SELECT id, name, email, phone
FROM customers 
WHERE active = 1;
```

#### CREATE INDEX (Create indexes)
```sql
-- Index for email searches
CREATE INDEX idx_customers_email ON customers(email);

-- Composite index
CREATE INDEX idx_products_category_price ON products(category_id, price);

-- Text index
CREATE INDEX idx_products_name ON products(name);
```

### 3. How to Use Ctrl+Enter

1. Write the SQL query in the editor
2. Select the query text (optional - if not selected, executes entire query)
3. Press **Ctrl+Enter**
4. View results in the results table

### 4. Save Changes in Drift

After executing queries that modify structure (CREATE, ALTER, DROP):

1. Changes are automatically applied to the Drift file
2. The `test_database.dart` file is updated with the new structure
3. Correct Drift syntax is maintained with `()()` at the end of each column

### 5. Verification of Changes

To verify that changes were saved correctly:

1. Review the updated `test_database.dart` file
2. New tables will appear as classes extending `Table`
3. New columns will appear with correct syntax: `textColumn() => text()()`

## Important Test Cases

### Case 1: Create complex new table
```sql
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    order_date TEXT NOT NULL,
    status TEXT DEFAULT 'pending',
    total REAL NOT NULL,
    notes TEXT,
    delivery_date TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);
```

### Case 2: Modify existing table
```sql
ALTER TABLE customers ADD COLUMN address TEXT;
ALTER TABLE customers ADD COLUMN city TEXT DEFAULT 'Not specified';
```

### Case 3: Complex operations
```sql
-- Create temporary table
CREATE TEMPORARY TABLE temp_stats AS
SELECT category_id, AVG(price) as average_price
FROM products GROUP BY category_id;

-- Update based on statistics
UPDATE products 
SET price = price * 1.05 
WHERE category_id IN (
    SELECT category_id FROM temp_stats WHERE average_price > 100
);
```

## Important Tips

1. **Always use Ctrl+Enter** to execute queries
2. **Drift mode activates automatically** when loading a .dart file
3. **Changes are saved automatically** to the original file
4. **Verify syntax** of the Drift file after major changes
5. **Make backup** of original file before extensive testing