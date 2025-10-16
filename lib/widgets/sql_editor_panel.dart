import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'dart:io';
import '../services/drift_parser.dart';

enum SqlQueryType { select, insert, update, delete, create, drop, alter, other }

class QueryResult {
  final bool isSuccess;
  final List<Map<String, dynamic>>? data;
  final String? error;
  final DateTime timestamp;
  final SqlQueryType queryType;
  final int? affectedRows;

  QueryResult({
    required this.isSuccess,
    this.data,
    this.error,
    required this.timestamp,
    this.queryType = SqlQueryType.other,
    this.affectedRows,
  });
}

class SqlEditorPanel extends StatefulWidget {
  final String? databasePath;
  final Function(String)? onDatabaseSelected;
  final bool _isWorkingMode;
  final Future<void> Function()? onSchemaChanged;
  final Function(String query, List<Map<String, dynamic>>? results)? onQueryExecuted;

  const SqlEditorPanel({
    super.key,
    this.databasePath,
    this.onDatabaseSelected,
    bool isWorkingMode = false,
    this.onSchemaChanged,
    this.onQueryExecuted,
  }) : _isWorkingMode = isWorkingMode;

  @override
  State<SqlEditorPanel> createState() => _SqlEditorPanelState();
}

class _SqlEditorPanelState extends State<SqlEditorPanel> {
  final TextEditingController _queryController = TextEditingController();
  final List<QueryResult> _queryHistory = [];
  bool _isExecuting = false;
  Database? _workingDatabase;
  final FocusNode _queryFocusNode = FocusNode();
  List<DriftTable> _driftTables = [];
  bool _isDriftMode = false;

  @override
  void initState() {
    super.initState();
    if (widget._isWorkingMode) {
      _createWorkingDatabase();
    } else if (widget.databasePath != null) {
      _initializeDriftMode();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    _workingDatabase?.dispose();
    super.dispose();
  }

  void _initializeDriftMode() {
    if (widget.databasePath?.toLowerCase().endsWith('.dart') == true) {
      setState(() {
        _isDriftMode = true;
      });
      _loadDriftFileAndCreateTempDatabase();
    }
  }

  void _loadDriftFileAndCreateTempDatabase() {
    try {
      // Parse the Drift file
      _driftTables = DriftParser.parseDriftFile(widget.databasePath!);

      if (_driftTables.isNotEmpty) {
        // Create temporary database with Drift structure
        _workingDatabase = DriftParser.createTempDatabase(_driftTables);

        // Execute seed data from the Drift file if it exists
        DriftParser.executeSeedData(_workingDatabase!, widget.databasePath!);

        // Check if seed data was inserted
        bool hasSeedData = false;
        for (final table in _driftTables) {
          final count =
              _workingDatabase!
                      .select(
                        'SELECT COUNT(*) as count FROM ${table.tableName}',
                      )
                      .first['count']
                  as int;
          if (count > 0) {
            hasSeedData = true;
            break;
          }
        }

        // Insert example data only if no seed data was found
        if (!hasSeedData) {
          _insertExampleData();
        }

        setState(() {});
        print(
          'Temporary database created from Drift file: ${widget.databasePath}',
        );

        // Add informative message
        setState(() {
          _queryHistory.add(
            QueryResult(
              isSuccess: true,
              data: [
                {
                  'message':
                      'Temporary database created from Drift. ${_driftTables.length} table(s) loaded.${hasSeedData ? ' Seed data loaded.' : ''}',
                },
              ],
              timestamp: DateTime.now(),
              queryType: SqlQueryType.other,
            ),
          );
        });
      }
    } catch (e) {
      print('Error parsing Drift file: $e');
      setState(() {
        _queryHistory.add(
          QueryResult(
            isSuccess: false,
            error: 'Error parsing Drift file: $e',
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void _insertExampleData() {
    if (_workingDatabase == null) return;

    try {
      for (final table in _driftTables) {
        switch (table.tableName.toLowerCase()) {
          case 'customers':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (name, email, phone, active) VALUES 
              ('John Doe', 'john@email.com', '555-0123', 1),
              ('Jane Smith', 'jane@email.com', '555-0124', 1),
              ('Bob Johnson', 'bob@email.com', '555-0125', 0)
            ''');
            break;
          case 'products':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (name, description, price, stock) VALUES 
              ('Laptop', 'Gaming laptop 16GB RAM', 1299.99, 5),
              ('Mouse', 'Wireless mouse', 29.99, 20),
              ('Keyboard', 'Mechanical RGB keyboard', 89.99, 15)
            ''');
            break;
          case 'orders':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (customerId, date, total, status) VALUES 
              (1, strftime('%s', 'now'), 1329.98, 'completed'),
              (2, strftime('%s', 'now'), 119.98, 'pending'),
              (3, strftime('%s', 'now'), 29.99, 'cancelled')
            ''');
            break;
          case 'usuarios':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (nombre, email, fechaRegistro, activo) VALUES 
              ('Juan Pérez', 'juan@email.com', strftime('%s', 'now'), 1),
              ('María García', 'maria@email.com', strftime('%s', 'now'), 1),
              ('Carlos López', 'carlos@email.com', strftime('%s', 'now'), 0)
            ''');
            break;
          case 'productos':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (nombre, descripcion, precio, stock) VALUES 
              ('Laptop', 'Laptop gaming 16GB RAM', 1299.99, 5),
              ('Mouse', 'Mouse inalámbrico', 29.99, 20),
              ('Teclado', 'Teclado mecánico RGB', 89.99, 15)
            ''');
            break;
          case 'pedidos':
            _workingDatabase!.execute('''
              INSERT INTO ${table.tableName} (usuarioId, fecha, total, estado) VALUES 
              (1, strftime('%s', 'now'), 1329.98, 'completado'),
              (2, strftime('%s', 'now'), 119.98, 'pendiente'),
              (3, strftime('%s', 'now'), 29.99, 'cancelado')
            ''');
            break;
        }
      }
    } catch (e) {
      print('Error inserting example data: $e');
    }
  }

  void _createWorkingDatabase() {
    try {
      _workingDatabase = sqlite3.openInMemory();

      // Create example tables for working mode
      _workingDatabase!.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          registration_date INTEGER NOT NULL,
          active INTEGER DEFAULT 1
        )
      ''');

      _workingDatabase!.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          stock INTEGER DEFAULT 0
        )
      ''');

      _workingDatabase!.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          date INTEGER NOT NULL,
          total REAL NOT NULL,
          status TEXT DEFAULT 'pending',
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      // Insert example data
      _workingDatabase!.execute('''
        INSERT INTO users (name, email, registration_date) VALUES 
        ('John Doe', 'john@email.com', strftime('%s', 'now')),
        ('Jane Smith', 'jane@email.com', strftime('%s', 'now')),
        ('Bob Johnson', 'bob@email.com', strftime('%s', 'now'))
      ''');

      _workingDatabase!.execute('''
        INSERT INTO products (name, description, price, stock) VALUES 
        ('Laptop', 'Gaming laptop 16GB RAM', 1299.99, 5),
        ('Mouse', 'Wireless mouse', 29.99, 20),
        ('Keyboard', 'Mechanical RGB keyboard', 89.99, 15)
      ''');
    } catch (e) {
      print('Error creating working database: $e');
    }
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.enter) {
        _executeQuery();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: (node, event) {
        return _handleKeyPress(event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      child: Column(
        children: [
          _buildToolbar(theme),
          Expanded(
            child: _buildQueryEditor(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    final executeButton = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isExecuting ? null : _executeQuery,
        icon: _isExecuting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.play_arrow, size: 18),
        label: Text(_isExecuting ? 'Executing...' : 'Execute'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onPrimary,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (widget._isWorkingMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.science,
                    size: 16,
                    color: Colors.purple.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Work Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.purple.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isDriftMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.deepOrange.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.integration_instructions,
                    size: 16,
                    color: Colors.orange.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Drift Mode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget._isWorkingMode || _isDriftMode) ...[
            const SizedBox(width: 12),
            executeButton,
          ] else ...[
            Icon(
              Icons.folder_open,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              widget.databasePath?.split(Platform.pathSeparator).last ??
                  'No database',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 12),
            executeButton,
          ],
          const Spacer(),
          if (_queryHistory.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _clearHistory,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear history'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildQueryEditor(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'SQL Editor',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ctrl+Enter to execute',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _queryController,
                focusNode: _queryFocusNode,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: _getHintText(),
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    if (widget._isWorkingMode) {
      return 'Write your SQL query here...\n\nAvailable tables: users, products, orders\n\nExamples:\nSELECT * FROM users;\nSELECT name, price FROM products WHERE price > 50;\nINSERT INTO users (name, email, registration_date) VALUES (\'Test\', \'test@email.com\', strftime(\'%s\', \'now\'));\n\nPress Ctrl+Enter to execute';
    } else if (_isDriftMode && _driftTables.isNotEmpty) {
      final tableNames = _driftTables.map((t) => t.tableName).join(', ');
      return '🎯 DRIFT MODE ACTIVE\n\nWorking with: ${widget.databasePath?.split(Platform.pathSeparator).last}\nTables: $tableNames\n\n✨ Available features:\n• SELECT, INSERT, UPDATE, DELETE\n• CREATE TABLE, ALTER TABLE, DROP TABLE\n• CREATE VIEW, DROP VIEW\n• Structural changes will update the .dart file\n\nExamples:\nSELECT * FROM $tableNames;\nCREATE TABLE new_table (id INTEGER PRIMARY KEY, name TEXT);\nCREATE VIEW active_users AS SELECT * FROM users WHERE active = 1;\nALTER TABLE users ADD COLUMN phone TEXT;\nDROP VIEW active_users;\n\nPress Ctrl+Enter to execute';
    } else {
      return 'Write your SQL query here...\n\n📝 Examples:\nSELECT * FROM table_name;\nINSERT INTO table (column) VALUES (\'value\');\nUPDATE table SET column = \'new_value\' WHERE id = 1;\nCREATE VIEW view_name AS SELECT column FROM table WHERE condition;\nDROP VIEW view_name;\n\nPress Ctrl+Enter to execute\n\n💡 Tip: If you have a .dart file, a temporary database will be created automatically';
    }
  }




  SqlQueryType _detectQueryType(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.startsWith('select')) return SqlQueryType.select;
    if (normalizedQuery.startsWith('insert')) return SqlQueryType.insert;
    if (normalizedQuery.startsWith('update')) return SqlQueryType.update;
    if (normalizedQuery.startsWith('delete')) return SqlQueryType.delete;
    if (normalizedQuery.startsWith('create')) return SqlQueryType.create;
    if (normalizedQuery.startsWith('drop')) return SqlQueryType.drop;
    if (normalizedQuery.startsWith('alter')) return SqlQueryType.alter;

    return SqlQueryType.other;
  }

  void _executeQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      final queryType = _detectQueryType(query);
      Database? db;

      if (widget._isWorkingMode) {
        db = _workingDatabase;
      } else if (widget.databasePath != null) {
        // If it's a Drift file, use the temporary database
        if (widget.databasePath!.toLowerCase().endsWith('.dart')) {
          if (_workingDatabase == null) {
            _loadDriftFileAndCreateTempDatabase();
          }
          db = _workingDatabase;
        } else {
          // Verify if it's really a SQLite database
          if (!_isDatabaseFile(widget.databasePath!)) {
            throw Exception(
              'The selected file is not a valid SQLite database.',
            );
          }
          db = sqlite3.open(widget.databasePath!);
        }
      }

      if (db == null) {
        throw Exception('No database available.');
      }

      final result = await _executeSqlQuery(db, query, queryType);

      final isDriftFile =
          widget.databasePath?.toLowerCase().endsWith('.dart') == true;
      if (isDriftFile && result.isSuccess && _shouldPersistToDrift(queryType)) {
        await _updateDriftFileFromDatabase();
      }

      setState(() {
        _queryHistory.add(result);
      });

      // Notify parent about query execution
      if (widget.onQueryExecuted != null) {
        widget.onQueryExecuted!(query, result.data);
      }

      // Only close connection if not work mode and not Drift
      if (!widget._isWorkingMode &&
          widget.databasePath != null &&
          !widget.databasePath!.toLowerCase().endsWith('.dart')) {
        db.dispose();
      }
    } catch (e) {
      setState(() {
        _queryHistory.add(
          QueryResult(
            isSuccess: false,
            error: e.toString(),
            timestamp: DateTime.now(),
            queryType: _detectQueryType(query),
          ),
        );
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  bool _isStructuralQuery(SqlQueryType queryType) {
    return queryType == SqlQueryType.create ||
        queryType == SqlQueryType.drop ||
        queryType == SqlQueryType.alter;
  }

  bool _shouldPersistToDrift(SqlQueryType queryType) {
    return _isStructuralQuery(queryType) ||
        queryType == SqlQueryType.insert ||
        queryType == SqlQueryType.update ||
        queryType == SqlQueryType.delete;
  }

  Future<void> _updateDriftFileFromDatabase() async {
    if (_workingDatabase == null || widget.databasePath == null) return;

    try {
      // Extract current database structure
      final updatedTables = DriftParser.extractTablesFromDatabase(
        _workingDatabase!,
      );

      // Update Drift file
      DriftParser.updateDriftFile(widget.databasePath!, updatedTables);

      // Update local reference
      _driftTables = updatedTables;

      if (widget.onSchemaChanged != null) {
        await widget.onSchemaChanged!();
      }

      // Show success message
      setState(() {
        _queryHistory.add(
          QueryResult(
            isSuccess: true,
            data: [
              {
                'message':
                    '✅ Drift file updated successfully with ${updatedTables.length} table(s)',
              },
            ],
            timestamp: DateTime.now(),
            queryType: SqlQueryType.other,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _queryHistory.add(
          QueryResult(
            isSuccess: false,
            error: 'Error updating Drift file: $e',
            timestamp: DateTime.now(),
            queryType: SqlQueryType.other,
          ),
        );
      });
    }
  }

  bool _isDatabaseFile(String path) {
    // Check if it's a .dart file (Drift schema)
    if (path.toLowerCase().endsWith('.dart')) {
      return false;
    }

    // Check if it's a valid SQLite file
    try {
      final file = File(path);
      if (!file.existsSync()) return false;

      // Read first bytes to verify SQLite signature
      final bytes = file.readAsBytesSync();
      if (bytes.length < 16) return false;

      // SQLite files start with "SQLite format 3\0"
      final signature = String.fromCharCodes(bytes.take(15));
      return signature == 'SQLite format 3';
    } catch (e) {
      return false;
    }
  }

  Future<QueryResult> _executeSqlQuery(
    Database db,
    String query,
    SqlQueryType queryType,
  ) async {
    try {
      switch (queryType) {
        case SqlQueryType.select:
          final rows = db.select(query);
          return QueryResult(
            isSuccess: true,
            data: rows,
            timestamp: DateTime.now(),
            queryType: queryType,
          );

        case SqlQueryType.insert:
        case SqlQueryType.update:
        case SqlQueryType.delete:
          db.execute(query);
          return QueryResult(
            isSuccess: true,
            timestamp: DateTime.now(),
            queryType: queryType,
            affectedRows: db.lastInsertRowId,
          );

        default:
          db.execute(query);
          return QueryResult(
            isSuccess: true,
            timestamp: DateTime.now(),
            queryType: queryType,
          );
      }
    } catch (e) {
      return QueryResult(
        isSuccess: false,
        error: e.toString(),
        timestamp: DateTime.now(),
        queryType: queryType,
      );
    }
  }

  void _clearHistory() {
    setState(() {
      _queryHistory.clear();
    });
  }
}
