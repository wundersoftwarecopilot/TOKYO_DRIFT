# TOKYO DRIFT - AI Coding Agent Instructions

## Overview
TOKYO DRIFT is a Flutter desktop app for inspecting SQLite databases and Drift schema files. It provides a unified interface for database exploration, table viewing, and SQL query execution with dual-mode support for live SQLite databases (read/write) and Drift schema files (read-only preview).

## Architecture & Key Patterns

### Dual Database Mode System
The core architecture revolves around `DatabaseConnection` class (`lib/models/database_connection.dart`) which abstracts two distinct modes:
- **SQLite Mode**: Direct database access via `sqlite3` package for live querying
- **Drift Schema Mode**: Parses `.dart` files to extract table definitions and creates temporary in-memory databases for preview

Key pattern: Check `database.type` and `database.isReadOnly` before enabling query execution features.

### Schema Parsing Strategy
Drift schema parsing (`lib/models/drift_schema_parser.dart`) uses regex patterns to extract:
- Table class definitions: `class (\w+) extends Table`
- Column definitions: `(\w+Column) get (\w+) => (\w+)()`
- Column modifiers: `.autoIncrement()`, `.nullable()`, `.withDefault()`

Example Drift syntax: `IntColumn get id => integer().autoIncrement()();`

### UI Navigation Patterns
- **Conditional UI**: Main interface switches between `MainScreen` (file explorer) and `DatabaseBrowserScreen` (active database) based on `_currentDatabase` state
- **Navigation Rail**: Three-panel desktop layout (Explorer/Table Viewer/Query Editor)
- **Special Navigation**: Table selection with `"__sql_mode__"` string triggers automatic switch to SQL Editor tab

## Development Workflow

### Essential Commands
```bash
flutter pub get                    # Dependencies
flutter run -d windows            # Desktop development
dart analyze                      # Static analysis (required before commits)
flutter test                     # Run widget tests
dart format .                     # Code formatting

# Troubleshooting Windows symlink issues:
flutter clean                     # Clean build cache
flutter pub get                   # Reinstall dependencies
```

### Testing Strategy
- Widget tests focus on UI state transitions (`test/widget_test.dart`)
- Test navigation between splash screen and main interface
- Verify database connection state management

### File Organization Conventions
```
lib/
├── models/          # Data abstractions (DatabaseConnection, parsers)
├── screens/         # Full-screen UI components  
├── widgets/         # Reusable UI panels
├── services/        # Business logic (DriftParser for code generation)
```

## Critical Integration Points

### Database Abstraction Layer
`DatabaseConnection.open()` auto-detects file type by extension:
- `.dart` → Drift schema parsing mode
- `.db/.sqlite/.sqlite3` → Direct SQLite access

Query execution is type-safe: `query()` and `execute()` methods throw exceptions for Drift schema files.

### Schema-to-SQL Mapping
Drift column types map to SQLite equivalents in `DriftColumnInfo.sqlType`:
- `IntColumn` → `INTEGER`
- `TextColumn` → `TEXT`  
- `DateTimeColumn` → `INTEGER` (Unix timestamp)
- `BoolColumn` → `INTEGER` (0/1)

### State Management Patterns
- Database connections are managed at screen level, not globally
- Table selection drives tab switching via `_onTableSelected()`
- Use `setState()` for UI updates when database state changes

## Project-Specific Conventions

### Error Handling
- Database operations wrapped in try-catch with user-friendly error messages
- File access validation before database operations
- Graceful degradation for unsupported Drift syntax

### Material Design 3 Implementation
- Dynamic theme with green seed color: `Color(0xFF2E7D32)` (light), `Color(0xFF4CAF50)` (dark)
- System theme mode detection
- Consistent icon usage: `Icons.storage` for database, `Icons.table_chart` for tables

### Code Generation Workflow
`DriftParser.updateDriftFile()` generates complete Drift schemas with:
- Seed functions: `seedDatabaseName()`
- Migration strategies: `buildDatabaseNameMigration()`
- Proper import statements and table class structure

When modifying schema parsing, always test with `example_database.dart` which contains representative Spanish-language table definitions (`Usuarios`, `Productos`, `Pedidos`).