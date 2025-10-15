import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database_connection.dart';
import '../services/drift_parser.dart';

class TableStructurePanel extends StatefulWidget {
  final DatabaseConnection database;
  final String tableName;

  const TableStructurePanel({
    super.key,
    required this.database,
    required this.tableName,
  });

  @override
  State<TableStructurePanel> createState() => _TableStructurePanelState();
}

class _TableStructurePanelState extends State<TableStructurePanel> {
  List<ColumnInfo> _columns = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTableStructure();
  }

  @override
  void didUpdateWidget(TableStructurePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tableName != widget.tableName) {
      _loadTableStructure();
    }
  }

  Future<void> _loadTableStructure() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.database.type == DatabaseType.driftSchema) {
        final driftTables = DriftParser.parseDriftFile(widget.database.path);
        final tableNameLower = widget.tableName.toLowerCase();
        final driftTable = driftTables.firstWhere(
          (table) => table.tableName.toLowerCase() == tableNameLower,
          orElse: () => throw Exception(
            'Table $tableNameLower not found in Drift file. Available tables: ${driftTables.map((t) => t.tableName).join(", ")}',
          ),
        );

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

        setState(() {
          _columns = convertedColumns;
          _isLoading = false;
        });
        return;
      }

      final columns = await widget.database.getTableSchema(widget.tableName);
      setState(() {
        _columns = columns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : _buildStructureView(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
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
          Icon(
            Icons.account_tree,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table Structure: ${widget.tableName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_columns.length} column(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTableStructure,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyCreateTableSQL,
            tooltip: 'Copy CREATE TABLE SQL',
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
            'Error loading table structure',
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
          ElevatedButton(
            onPressed: _loadTableStructure,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureView() {
    if (_columns.isEmpty) {
      return const Center(child: Text('No columns found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStructureTable(),
          const SizedBox(height: 24),
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildStructureTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Column Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Column',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Null',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Default',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _columns.map((column) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_chart,
                              size: 16,
                              color: column.primaryKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              column.name,
                              style: TextStyle(
                                fontWeight: column.primaryKey
                                    ? FontWeight.bold
                                    : null,
                                color: column.primaryKey
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(column.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getTypeColor(
                                column.type,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            column.type,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: _getTypeColor(column.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Icon(
                          column.notNull ? Icons.close : Icons.check,
                          size: 16,
                          color: column.notNull ? Colors.red : Colors.green,
                        ),
                      ),
                      DataCell(
                        column.primaryKey
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text(''),
                      ),
                      DataCell(
                        Text(
                          column.defaultValue ?? '',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'INTEGER':
        return Colors.blue;
      case 'TEXT':
        return Colors.green;
      case 'REAL':
        return Colors.orange;
      case 'BLOB':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdditionalInfo() {
    final primaryKeys = _columns.where((c) => c.primaryKey).toList();
    final notNullColumns = _columns.where((c) => c.notNull).toList();
    final hasDefaults = _columns.where((c) => c.defaultValue != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Columns', '${_columns.length}'),
            _buildSummaryRow('Primary Keys', '${primaryKeys.length}'),
            _buildSummaryRow('NOT NULL Columns', '${notNullColumns.length}'),
            _buildSummaryRow('With Defaults', '${hasDefaults.length}'),
            if (widget.database.isReadOnly) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a Drift schema file. Structure shown is inferred from code.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _copyCreateTableSQL() {
    final sql = _generateCreateTableSQL();
    Clipboard.setData(ClipboardData(text: sql));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CREATE TABLE SQL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _generateCreateTableSQL() {
    final buffer = StringBuffer();
    buffer.writeln('CREATE TABLE ${widget.tableName} (');

    for (int i = 0; i < _columns.length; i++) {
      final column = _columns[i];
      buffer.write('  ${column.name} ${column.type}');

      if (column.primaryKey) {
        buffer.write(' PRIMARY KEY');
      }

      if (column.notNull && !column.primaryKey) {
        buffer.write(' NOT NULL');
      }

      if (column.defaultValue != null && column.defaultValue!.isNotEmpty) {
        buffer.write(' DEFAULT ${column.defaultValue}');
      }

      if (i < _columns.length - 1) {
        buffer.writeln(',');
      } else {
        buffer.writeln();
      }
    }

    buffer.writeln(');');
    return buffer.toString();
  }
}
