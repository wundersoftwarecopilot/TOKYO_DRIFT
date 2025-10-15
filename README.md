# TOKYO DRIFT

TOKYO DRIFT is a Flutter desktop experience for inspecting and editing local SQLite databases and Drift schema files. The app combines a schema-aware explorer, a table structure viewer, and a SQL playground so you can jump between schema design and data exploration without switching tools.

## Key Features

- **Database explorer** – open existing SQLite databases (`.db`, `.sqlite`, `.sqlite3`) or Drift schema files (`.dart`), review metadata, and drill into table and view lists quickly.
- **Table structure viewer** – inspect column definitions, constraints, and sample data for SQLite sources, or read-only schema information when browsing Drift files.
- **View support** – discover and inspect SQL views in both SQLite databases and Drift schema files. View definitions are displayed in a dedicated section with the ability to examine the underlying SQL.
- **SQL editor** – run ad hoc queries against SQLite databases with history and copy-to-clipboard helpers. The editor automatically disables itself in Drift schema mode to avoid accidental writes.
- **Modern UI** – built with Material Design 3, dynamic light/dark themes, tabbed navigation, and visual indicators that highlight the current database type.

## Getting Started

### Prerequisites

- Flutter SDK (3.19 or newer; see the `sdk` constraint in `pubspec.yaml`)
- A local SQLite installation when you plan to open raw database files

### Installation

```bash
git clone https://github.com/wundersoftwarecopilot/TOKYO_DRIFT.git
cd TOKYO_DRIFT/drift_admin
flutter pub get
```

### Running the App

```bash
flutter run
```

The project ships with a splash screen and desktop runners for Windows, macOS, and Linux. Mobile builds are possible but have not been the focus of testing.

## Using TOKYO DRIFT

### Opening Files

1. **SQLite databases** – full read/write experience: browse tables, inspect schema, and execute queries. Supported extensions are `.db`, `.sqlite`, and `.sqlite3`. Views are automatically detected and displayed in a separate section.
2. **Drift schema files** – supply a `.dart` file that defines tables and views with Drift. TOKYO DRIFT parses the file, builds an in-memory database, and presents the structure in read-only mode. A sample file lives at `example_database.dart`.

### Navigation Overview

- **Explorer** tab shows the database tree, key metadata, and action shortcuts. Tables and views are listed in separate expandable sections.
- **Table Viewer** displays schema details and (for SQLite) paginated data grids.
- **Query Editor** lets you run SQL statements, review history, and copy results. The editor is automatically hidden for Drift schemas.

### Drift Schema Handling

When you open a Drift file the app:

1. Parses table definitions and column builders (`integer()`, `text()`, `real()`, etc.).
2. Parses view definitions (classes extending `View`) and extracts their metadata.
3. Maps Drift column types to SQLite equivalents (for example, `IntColumn` → `INTEGER`).
4. Builds a temporary SQLite database for quick preview and seeds data if the schema declares it.
5. Surfaces the schema as read-only so you can audit structure without mutating source code.

### Example Supported Schema

```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

// Views are also supported
abstract class ActiveUsersView extends View {
  Users get users;

  @override
  Query as() => select([users.id, users.name, users.email])
      .from(users)
      .where(users.active.equals(1));
}
```

### Working with SQL Views

TOKYO DRIFT supports SQL views in both SQLite databases and Drift schema files:

**In SQLite databases:**
- Views are automatically detected from the `sqlite_master` table
- Click on any view in the Views section to see its SQL definition
- Views appear with a visibility icon to distinguish them from tables

**In Drift schema files:**
- Views are parsed from classes that extend `View`
- Both `class` and `abstract class` declarations are supported
- View names are automatically converted from CamelCase to snake_case (e.g., `ActiveUsersView` → `active_users`)
- Click on any view to see its metadata

**Example SQL View Creation:**
```sql
CREATE VIEW products_with_category AS
SELECT 
    p.id,
    p.name,
    p.price,
    c.name as category_name
FROM products p
JOIN categories c ON p.category_id = c.id;
```

## Project Structure

```
lib/
├─ main.dart                     # App entry point
├─ models/
│  ├─ database_connection.dart   # Unified interface for SQLite & Drift
│  └─ drift_schema_parser.dart   # Schema extraction helpers
├─ screens/
│  ├─ splash_screen.dart         # Animated splash and navigation bootstrap
│  └─ main_screen.dart           # Hosts desktop layout logic
├─ widgets/
│  ├─ database_explorer.dart
│  ├─ table_viewer.dart
│  ├─ query_editor.dart
│  ├─ data_browser_panel.dart
│  ├─ table_structure_panel.dart
│  └─ sql_editor_panel.dart
└─ services/
   └─ drift_parser.dart          # Generates Drift code & seeds temporary DBs
```

Desktop-specific build files live under `windows/`, `macos/`, and `linux/` respectively. Assets include the TOKYO DRIFT logo located at `assets/images/tokyo_drift_logo.png` (see the `pubspec.yaml` entry for bundling).

## Development Workflow

| Task | Command |
|------|---------|
| Fetch dependencies | `flutter pub get` |
| Static analysis | `dart analyze` |
| Run tests | `flutter test` |
| Format Dart code | `dart format .` |

The repository enables modern Flutter lints through `analysis_options.yaml`. The default test suite exercises the splash navigation and verifies the explorer UI once the splash animation finishes.

## Limitations

- Drift schemas are rendered read-only (no query execution).
- The parser focuses on common column builders; exotic macros may require manual tweaks.
- SQLite features that rely on extensions or virtual tables are not currently exposed in the UI.
- View definitions in Drift schemas show simplified metadata (full query reconstruction is not yet supported).

## Roadmap Ideas

1. Allow editing Drift schemas directly in the UI with safe regeneration.
2. Add import/export for query history and seed scripts.
3. Provide database diffing and migration helpers.

## Contributing

1. Fork the repository and clone your copy.
2. Create a feature branch: `git checkout -b feature/my-update`.
3. Run `dart analyze` and `flutter test` before submitting changes.
4. Commit with clear messages and open a pull request against `main`.

## License

This project is released under the MIT License. See [`LICENSE`](LICENSE) for details.

## Acknowledgements

- Flutter SDK and the Material 3 design system
- Drift ORM and SQLite for powering the data layer
- The TOKYO DRIFT logo (`assets/images/tokyo_drift_logo.png`) supplied with the repository
