import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database_connection.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import '../services/drift_parser.dart';

class DataBrowserPanel extends StatefulWidget {
  final DatabaseConnection database;
  final String tableName;

  const DataBrowserPanel({
    super.key,
    required this.database,
    required this.tableName,
  });

  @override
  State<DataBrowserPanel> createState() => _DataBrowserPanelState();
}

class _DataBrowserPanelState extends State<DataBrowserPanel> {
  List<Map<String, dynamic>> _data = [];
  List<ColumnInfo> _columns = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 100;
  int _totalRows = 0;
  String? _error;
  String? _sortColumn;
  bool _sortAscending = true;
  sql.Database? _tempDatabase; // For Drift files

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tempDatabase?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DataBrowserPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tableName != widget.tableName) {
      _currentPage = 1;
      _sortColumn = null;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.database.type == DatabaseType.driftSchema) {
        // For Drift schema files, create temporary database with seed data
        await _loadDriftTableData();
        return;
      }

      // Load table schema
      final columns = await widget.database.getTableSchema(widget.tableName);

      if (widget.database.isReadOnly) {
        // For other read-only databases, only show structure
        setState(() {
          _columns = columns;
          _data = [];
          _totalRows = 0;
          _isLoading = false;
        });
        return;
      }

      // Load row count
      final totalRows = await widget.database.getTableRowCount(
        widget.tableName,
      );

      // Build SQL query with sorting and pagination
      final offset = (_currentPage - 1) * _pageSize;
      String sql = 'SELECT * FROM "${widget.tableName}"';

      if (_sortColumn != null) {
        sql += ' ORDER BY "$_sortColumn" ${_sortAscending ? "ASC" : "DESC"}';
      }

      sql += ' LIMIT $_pageSize OFFSET $offset';

      final data = await widget.database.query(sql);

      setState(() {
        _columns = columns;
        _data = data;
        _totalRows = totalRows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDriftTableData() async {
    try {
      // Parse Drift file to get table structure
      final driftTables = DriftParser.parseDriftFile(widget.database.path);

      // Find the table (case-insensitive match)
      final tableNameLower = widget.tableName.toLowerCase();
      final driftTable = driftTables.firstWhere(
        (t) => t.tableName.toLowerCase() == tableNameLower,
        orElse: () => throw Exception('Table $tableNameLower not found in Drift file. Available tables: ${driftTables.map((t) => t.tableName).join(", ")}'),
      );

      // Dispose any previous temporary database to ensure schema refresh
      _tempDatabase?.dispose();

      // Create temporary database with the actual table name from drift parser
      _tempDatabase = DriftParser.createTempDatabase([driftTable]);

      // Execute seed data from the Drift file
      DriftParser.executeSeedData(_tempDatabase!, widget.database.path);

      // Use the actual table name from the drift parser (not the lowercased version)
      final actualTableName = driftTable.tableName;

      final convertedColumns = driftTable.columns
          .map(
            (column) => ColumnInfo(
              name: column.name,
              type: column.toSqlType(),
              notNull: !column.isNullable && !column.isPrimaryKey,
              defaultValue: column.defaultValue,
              primaryKey: column.isPrimaryKey,
            ),
          )
          .toList();

      // Get row count
      final result = _tempDatabase!.select('SELECT COUNT(*) as count FROM "$actualTableName"');
      final totalRows = result.first['count'] as int;

      // Load data with pagination and sorting
      final offset = (_currentPage - 1) * _pageSize;
      String sql = 'SELECT * FROM "$actualTableName"';

      if (_sortColumn != null) {
        sql += ' ORDER BY "$_sortColumn" ${_sortAscending ? "ASC" : "DESC"}';
      }

      sql += ' LIMIT ? OFFSET ?';

      final data = _tempDatabase!.select(sql, [_pageSize, offset]);

      setState(() {
        _columns = convertedColumns;
        _data = data.map((row) => Map<String, dynamic>.from(row)).toList();
        _totalRows = totalRows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading Drift table data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (widget.database.type == DatabaseType.driftSchema && _tempDatabase == null && !_isLoading)
          Expanded(child: _buildSchemaOnlyView())
        else
          Expanded(child: _buildDataView()),
      ],
    );
  }

  Widget _buildHeader() {
    final totalPages = (_totalRows / _pageSize).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.table_view, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Data: ${widget.tableName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.database.type == DatabaseType.driftSchema && _tempDatabase != null
                      ? '$_totalRows row(s) from seed data, ${_columns.length} column(s)'
                      : widget.database.isReadOnly
                      ? 'Schema view only'
                      : '$_totalRows row(s), ${_columns.length} column(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!widget.database.isReadOnly && totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: _currentPage > 1 ? () => _changePage(1) : null,
              tooltip: 'First Page',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1
                  ? () => _changePage(_currentPage - 1)
                  : null,
              tooltip: 'Previous Page',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Page $_currentPage of $totalPages',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < totalPages
                  ? () => _changePage(_currentPage + 1)
                  : null,
              tooltip: 'Next Page',
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed: _currentPage < totalPages
                  ? () => _changePage(totalPages)
                  : null,
              tooltip: 'Last Page',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaOnlyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schema,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Schema View Only',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This is a Drift schema file. No actual data is available.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Switch to "Database Structure" tab to view column definitions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_columns.isEmpty) {
      return const Center(child: Text('No columns found'));
    }

    if (_data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No data in this table',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            sortColumnIndex: _sortColumn != null
                ? _columns.indexWhere((c) => c.name == _sortColumn)
                : null,
            sortAscending: _sortAscending,
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columns: _columns.map((column) {
              return DataColumn(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (column.primaryKey)
                      Icon(
                        Icons.key,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    if (column.primaryKey) const SizedBox(width: 4),
                    Text(
                      column.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: column.primaryKey
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
                onSort: (columnIndex, ascending) {
                  setState(() {
                    _sortColumn = column.name;
                    _sortAscending = ascending;
                  });
                  _loadData();
                },
              );
            }).toList(),
            rows: _data.map((row) {
              return DataRow(
                cells: _columns.map((column) {
                  final value = row[column.name];
                  return DataCell(
                    GestureDetector(
                      onTap: () => _showCellValue(column.name, value),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          _formatCellValue(value),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: value is num ? 'monospace' : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ), // Fixed: Added proper closing parenthesis for DataTable
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String && value.isEmpty) return '(empty)';
    return value.toString();
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadData();
  }

  void _showCellValue(String columnName, dynamic value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Column: $columnName'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
          child: SingleChildScrollView(
            child: SelectableText(
              _formatCellValue(value),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value?.toString() ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Value copied to clipboard')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
