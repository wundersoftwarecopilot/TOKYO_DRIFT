import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database_connection.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import '../services/drift_parser.dart';

class TableViewer extends StatefulWidget {
  final DatabaseConnection? database;
  final String? tableName;

  const TableViewer({super.key, this.database, this.tableName});

  @override
  State<TableViewer> createState() => _TableViewerState();
}

class _TableViewerState extends State<TableViewer> {
  List<Map<String, dynamic>> _data = [];
  List<ColumnInfo> _columns = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 100;
  int _totalRows = 0;
  String? _error;
  sql.Database? _tempDatabase; // For Drift files

  @override
  void initState() {
    super.initState();
    if (widget.database != null && widget.tableName != null) {
      _loadTableData();
    }
  }

  @override
  void dispose() {
    _tempDatabase?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TableViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.database != oldWidget.database ||
        widget.tableName != oldWidget.tableName) {
      if (widget.database != null && widget.tableName != null) {
        _loadTableData();
      } else {
        _clearData();
      }
    }
  }

  void _clearData() {
    setState(() {
      _data = [];
      _columns = [];
      _totalRows = 0;
      _currentPage = 1;
      _error = null;
    });
  }

  Future<void> _loadTableData() async {
    if (widget.database == null || widget.tableName == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load table schema
      final columns = await widget.database!.getTableSchema(widget.tableName!);

      // For Drift schema files, create temporary database with seed data
      if (widget.database!.type == DatabaseType.driftSchema) {
        await _loadDriftTableData(columns);
        return;
      }

      // For regular SQLite databases
      // Load row count
      final totalRows = await widget.database!.getTableRowCount(
        widget.tableName!,
      );

      // Load data with pagination
      final offset = (_currentPage - 1) * _pageSize;
      final sql =
          'SELECT * FROM "${widget.tableName}" LIMIT $_pageSize OFFSET $offset';
      final data = await widget.database!.query(sql);

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

  Future<void> _loadDriftTableData(List<ColumnInfo> columns) async {
    try {
      // Parse Drift file to get table structure
      final driftTables = DriftParser.parseDriftFile(widget.database!.path);

      // Find the table (case-insensitive match)
      final tableNameLower = widget.tableName!.toLowerCase();
      final driftTable = driftTables.firstWhere(
        (t) => t.tableName.toLowerCase() == tableNameLower,
        orElse: () => throw Exception('Table $tableNameLower not found in Drift file. Available tables: ${driftTables.map((t) => t.tableName).join(", ")}'),
      );

      // Create temporary database with the actual table name from drift parser
      _tempDatabase = DriftParser.createTempDatabase([driftTable]);

      // Execute seed data from the Drift file
      DriftParser.executeSeedData(_tempDatabase!, widget.database!.path);

      // Use the actual table name from the drift parser (not the lowercased version)
      final actualTableName = driftTable.tableName;

      // Get row count
      final result = _tempDatabase!.select('SELECT COUNT(*) as count FROM "$actualTableName"');
      final totalRows = result.first['count'] as int;

      // Load data with pagination
      final offset = (_currentPage - 1) * _pageSize;
      final data = _tempDatabase!.select(
        'SELECT * FROM "$actualTableName" LIMIT ? OFFSET ?',
        [_pageSize, offset],
      );

      setState(() {
        _columns = columns;
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
    if (widget.database == null || widget.tableName == null) {
      return _buildEmptyState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Table: ${widget.tableName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTableData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildTableContent(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Select a table to view its contents',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
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
            'Error loading table data',
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
          ElevatedButton(onPressed: _loadTableData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTableContent() {
    if (_columns.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        _buildTableInfo(),
        Expanded(child: _buildDataTable()),
        _buildPagination(),
      ],
    );
  }

  Widget _buildTableInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Columns: ${_columns.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  widget.database?.type == DatabaseType.driftSchema && _tempDatabase != null
                      ? 'Total Rows: $_totalRows (from seed data)'
                      : widget.database?.type == DatabaseType.driftSchema
                      ? 'Schema File (no data)'
                      : 'Total Rows: $_totalRows',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _showTableStructure,
            icon: const Icon(Icons.info_outline),
            label: const Text('Table Structure'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (widget.database?.type == DatabaseType.driftSchema && _data.isEmpty && _tempDatabase == null) {
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
              'Use the "Table Structure" button to view column definitions.',
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: _columns
              .map(
                (column) => DataColumn(
                  label: Text(
                    column.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
          rows: _data
              .map(
                (row) => DataRow(
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
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_totalRows / _pageSize).ceil();

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _changePage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $_currentPage of $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => _changePage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
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
    _loadTableData();
  }

  void _showCellValue(String columnName, dynamic value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Column: $columnName'),
        content: SelectableText(
          _formatCellValue(value),
          style: const TextStyle(fontFamily: 'monospace'),
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

  void _showTableStructure() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Structure: ${widget.tableName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Column')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Null')),
                DataColumn(label: Text('Key')),
                DataColumn(label: Text('Default')),
              ],
              rows: _columns
                  .map(
                    (column) => DataRow(
                      cells: [
                        DataCell(Text(column.name)),
                        DataCell(Text(column.type)),
                        DataCell(Text(column.notNull ? 'NO' : 'YES')),
                        DataCell(Text(column.primaryKey ? 'PRI' : '')),
                        DataCell(Text(column.defaultValue ?? '')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
