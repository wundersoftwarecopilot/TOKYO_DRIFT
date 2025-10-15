# Visual Guide: SQL Views in TOKYO DRIFT

## Database Tree View with Views

```
┌─────────────────────────────────────┐
│ 🗄️ Database Structure           [×] │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💾 test_database_with_views.db  │ │
│ │                                 │ │
│ │ Type:     SQLite Database       │ │
│ │ Size:     12.5 KB               │ │
│ │ Tables:   3                     │ │
│ │ Views:    5                     │ │
│ │                                 │ │
│ │ [Read Only]                     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ▼ 📊 Tables (3)                 │ │
│ │   ├─ 📄 categories              │ │
│ │   ├─ 📄 customers               │ │
│ │   └─ 📄 products                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ▼ 👁️ Views (5)                  │ │
│ │   ├─ 👁️ active_customers    ℹ️  │ │
│ │   ├─ 👁️ expensive_products  ℹ️  │ │
│ │   ├─ 👁️ low_stock_products  ℹ️  │ │
│ │   ├─ 👁️ product_summary     ℹ️  │ │
│ │   └─ 👁️ products_with_categ ℹ️  │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## View Definition Dialog

When clicking on a view (e.g., "products_with_category"), a dialog appears:

```
┌──────────────────────────────────────────────────────┐
│ 👁️ products_with_category                        [×] │
├──────────────────────────────────────────────────────┤
│                                                      │
│  CREATE VIEW products_with_category AS               │
│  SELECT                                              │
│      p.id,                                           │
│      p.name AS product_name,                         │
│      p.price,                                        │
│      p.stock,                                        │
│      c.name AS category_name                         │
│  FROM products p                                     │
│  JOIN categories c ON p.category_id = c.id;         │
│                                                      │
│                                                      │
│                                     [Close] ────────►│
└──────────────────────────────────────────────────────┘
```

## Visual Elements

### Icons Used
- **Database:** 🗄️ `Icons.storage` (SQLite) / 💻 `Icons.code` (Drift)
- **Tables Section:** 📊 `Icons.table_chart`
- **Table Items:** 📄 `Icons.table_rows`
- **Views Section:** 👁️ `Icons.visibility`
- **View Items:** 👁️ `Icons.visibility_outlined`
- **Info Icon:** ℹ️ `Icons.info_outline`

### Color Scheme
- **Primary (Tables):** Green theme (`Color(0xFF2E7D32)` light / `Color(0xFF4CAF50)` dark)
- **Secondary (Views):** Uses `Theme.colorScheme.secondary` (typically teal/cyan)
- **Read-only Badge:** Error container color (typically red/pink)

### Interaction Flow

1. **Opening Database:**
   ```
   User clicks folder icon → File picker opens → 
   Selects .db or .dart file → Database loads →
   Tables and Views sections populate
   ```

2. **Viewing Table:**
   ```
   User clicks table name → 
   Main view switches to Table Viewer →
   Shows schema and data
   ```

3. **Viewing View Definition:**
   ```
   User clicks view name (or info icon) →
   Dialog appears with SQL definition →
   User can select/copy the SQL →
   Close button returns to main view
   ```

## Drift Schema Example UI

For a Drift schema file (example_with_views.dart):

```
┌─────────────────────────────────────┐
│ 🗄️ Database Structure           [×] │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💻 example_with_views.dart      │ │
│ │                                 │ │
│ │ Type:     Drift Schema          │ │
│ │ Size:     3.3 KB                │ │
│ │ Tables:   4                     │ │
│ │ Views:    5                     │ │
│ │                                 │ │
│ │ [🔒 Read Only]                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ▼ 📊 Tables (4)                 │ │
│ │   ├─ 📄 Customers               │ │
│ │   ├─ 📄 Categories              │ │
│ │   ├─ 📄 Products                │ │
│ │   └─ 📄 Orders                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ▼ 👁️ Views (5)                  │ │
│ │   ├─ 👁️ ActiveCustomersView ℹ️  │ │
│ │   ├─ 👁️ ProductsWithCategory ℹ️ │ │
│ │   ├─ 👁️ CustomerOrdersSumma ℹ️  │ │
│ │   ├─ 👁️ LowStockProductsVie ℹ️  │ │
│ │   └─ 👁️ ExpensiveProductsVi ℹ️  │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## Responsive Behavior

### Expandable Sections
- Click the section header to expand/collapse
- Arrow icon changes: ▶️ (collapsed) / ▼ (expanded)
- State is maintained during session

### View Count Badge
- Shows in database info panel if views > 0
- Format: "Views: {count}"
- Only appears when database has views

### Empty State
When no views are found:
```
┌─────────────────────────────────┐
│ ▼ 👁️ Views (0)                 │
│                                 │
│     No views found              │
│                                 │
└─────────────────────────────────┘
```

## Material Design 3 Compliance

- Uses Material Design 3 color scheme
- Follows elevation guidelines for cards
- Implements proper touch targets (48dp minimum)
- Supports both light and dark themes
- Uses semantic color roles (primary, secondary, error, etc.)

## Accessibility

- All interactive elements have tooltips
- Proper semantic icons for screen readers
- Sufficient color contrast ratios
- Keyboard navigation support
- Selectable text in dialogs for copying

## Future Enhancements

Potential improvements not yet implemented:
- [ ] Syntax highlighting in view definitions
- [ ] View data preview (execute view query)
- [ ] Export view definition to file
- [ ] Search/filter views by name
- [ ] View dependencies visualization
