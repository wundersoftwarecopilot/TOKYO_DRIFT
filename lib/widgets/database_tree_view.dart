import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/database_connection.dart';

class DatabaseTreeView extends StatefulWidget {
  final DatabaseConnection? database;
  final Function(String) onTableSelected;
  final VoidCallback onDatabaseClosed;
  final String? selectedTable;

  const DatabaseTreeView({
    super.key,
    this.database,
    required this.onTableSelected,
    required this.onDatabaseClosed,
    this.selectedTable,
  });

  @override
  State<DatabaseTreeView> createState() => _DatabaseTreeViewState();
}

class _DatabaseTreeViewState extends State<DatabaseTreeView> {
  bool _isLoading = false;
  bool _tablesExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: widget.database == null
              ? _buildOpenDatabasePrompt()
              : _buildDatabaseTree(),
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
          Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Database Structure',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.database == null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _isLoading ? null : _openDatabase,
              tooltip: 'Open Database',
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onDatabaseClosed,
              tooltip: 'Close Database',
            ),
        ],
      ),
    );
  }

  Widget _buildOpenDatabasePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No database open',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click the folder icon to open a database',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseTree() {
    final database = widget.database!;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildDatabaseInfo(),
        const SizedBox(height: 8),
        _buildTablesSection(),
      ],
    );
  }

  Widget _buildDatabaseInfo() {
    final database = widget.database!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  database.type == DatabaseType.sqlite
                      ? Icons.storage
                      : Icons.code,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    database.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Type', database.typeDescription),
            _buildInfoRow('Size', database.formattedSize),
            _buildInfoRow('Tables', '${database.tables.length}'),
            if (database.isReadOnly)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Read Only',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesSection() {
    final database = widget.database!;

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _tablesExpanded = !_tablesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _tablesExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.table_chart,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tables (${database.tables.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_tablesExpanded && database.tables.isNotEmpty)
            ...database.tables.map((tableName) => _buildTableItem(tableName)),
          if (_tablesExpanded && database.tables.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tables found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableItem(String tableName) {
    final isSelected = widget.selectedTable == tableName;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 40, right: 16),
        leading: Icon(
          Icons.table_rows,
          size: 16,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        title: Text(
          tableName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
        trailing: widget.database!.isReadOnly
            ? null
            : FutureBuilder<int>(
                future: widget.database!.getTableRowCount(tableName),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${snapshot.data}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  );
                },
              ),
        onTap: () => widget.onTableSelected(tableName),
      ),
    );
  }

  Future<void> _openDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3', 'dart'],
        dialogTitle: 'Select Database File (SQLite or Drift Schema)',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final database = await DatabaseConnection.open(filePath);
        // Note: We need to pass this back to the parent widget
        // For now, this is just a placeholder
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening database: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
