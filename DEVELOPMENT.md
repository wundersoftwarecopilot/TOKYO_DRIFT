# Drift Admin Development Notes

## Development Setup

### Required Tools
- Flutter SDK 3.19.0 or higher
- Dart SDK 3.3.0 or higher
- VS Code with Flutter extension (recommended)
- Git

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   └── database_connection.dart # Database connection handling
├── screens/                     # Main application screens
│   └── main_screen.dart        # Primary application interface
└── widgets/                     # Reusable UI components
    ├── database_explorer.dart  # Database browsing widget
    ├── query_editor.dart       # SQL query interface
    └── table_viewer.dart       # Table data display
```

### Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.28.2              # ORM for SQLite
  sqlite3: ^2.9.3           # Direct SQLite access
  file_picker: ^10.3.3       # File selection dialog
  path: ^1.9.1               # Path manipulation

dev_dependencies:
  drift_dev: ^2.28.3         # Code generation for Drift
  build_runner: ^2.4.6       # Build system
```

### Development Commands

```bash
# Get dependencies
flutter pub get

# Run code generation (if needed for Drift)
dart run build_runner build

# Format code
dart format .

# Analyze code
dart analyze

# Run on desktop
flutter run -d windows
flutter run -d macos  
flutter run -d linux

# Build for release
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

### Database Connection Implementation

The app uses `sqlite3` package directly for maximum compatibility with existing SQLite databases. The `DatabaseConnection` class provides:

- Direct SQL query execution
- Table schema inspection
- Row counting and pagination
- Error handling

### UI Architecture

The app uses a three-panel layout:
1. **Navigation Rail**: Switch between major features
2. **Content Area**: Dynamic content based on selected feature
3. **Database Info**: Current database status and actions

### Testing Strategy

1. **Unit Tests**: Test database connection and query logic
2. **Widget Tests**: Test individual UI components
3. **Integration Tests**: Test complete workflows
4. **Manual Testing**: Test with various SQLite database files

### Performance Considerations

- **Pagination**: Large tables are loaded in chunks (100 rows default)
- **Lazy Loading**: Table schemas loaded on demand
- **Connection Pooling**: Single connection per opened database
- **Memory Management**: Proper disposal of database connections

### Future Enhancements

1. **Schema Designer**: Visual database schema editing
2. **Import/Export**: CSV, JSON data import/export
3. **Query Builder**: Visual query construction
4. **Database Comparison**: Side-by-side database comparison
5. **Backup/Restore**: Database backup and restore functionality
6. **Multi-Connection**: Support multiple open databases
7. **Plugin System**: Extensible architecture for custom features

### Known Limitations

- Currently supports read-only operations for safety
- Single database connection at a time
- Limited to SQLite databases only
- No built-in data encryption support

### Troubleshooting

#### Common Issues

1. **File Access Denied**: 
   - Check file permissions
   - Ensure database is not locked by another process

2. **Large Database Performance**:
   - Increase pagination size if needed
   - Use indexed queries for better performance

3. **Memory Issues**:
   - Close unused database connections
   - Restart app if memory usage is high

#### Debug Mode

Enable debug logging by setting environment variable:
```bash
export FLUTTER_LOG=debug
flutter run
```