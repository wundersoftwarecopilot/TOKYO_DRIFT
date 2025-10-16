import 'package:flutter/material.dart';
import '../models/database_connection.dart';
import '../widgets/database_tree_view.dart';
import '../widgets/table_structure_panel.dart';
import '../widgets/sql_editor_panel.dart';
import '../widgets/data_browser_panel.dart';
import 'package:drift_admin/screens/_adjustable_panels.dart';

class DatabaseBrowserScreen extends StatefulWidget {
  final DatabaseConnection? database;
  final VoidCallback onDatabaseClosed;
  final Future<void> Function()? onSchemaChanged;

  const DatabaseBrowserScreen({
    super.key,
    this.database,
    required this.onDatabaseClosed,
    this.onSchemaChanged,
  });

  @override
  State<DatabaseBrowserScreen> createState() => _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends State<DatabaseBrowserScreen> {
  String? _selectedTable;
  List<Map<String, dynamic>>? _queryResults;
  String? _lastExecutedQuery;

  @override
  void didUpdateWidget(covariant DatabaseBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.database != null &&
        _selectedTable != null &&
        !widget.database!.tables.contains(_selectedTable)) {
      setState(() {
        _selectedTable = null;
      });
    }
  }

  void _onTableSelected(String tableName) {
    if (tableName == '__sql_mode__') {
      // Keep the current selected table when entering SQL mode
      return;
    }

    setState(() {
      _selectedTable = tableName;
    });
  }

  void _onQueryExecuted(String query, List<Map<String, dynamic>>? results) {
    setState(() {
      _lastExecutedQuery = query;
      _queryResults = results;
    });
    
    // If schema changed, refresh the database tree
    if (query.toLowerCase().contains('create') || 
        query.toLowerCase().contains('drop') || 
        query.toLowerCase().contains('alter')) {
      widget.onSchemaChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel - Database tree view
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: DatabaseTreeView(
              database: widget.database,
              onTableSelected: _onTableSelected,
              onDatabaseClosed: widget.onDatabaseClosed,
              selectedTable: _selectedTable,
            ),
          ),
          // Right panel - Main content area
          Expanded(
            child: widget.database != null ? _buildMainLayout() : _buildWelcomeScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLayout() {
    // Use LayoutBuilder to get constraints for Split widgets
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a horizontal Split for the three columns
        return Row(
          children: [
            Expanded(
              child: AdjustablePanels(
                minWidth: 180,
                maxWidth: constraints.maxWidth,
                minHeight: 120,
                maxHeight: constraints.maxHeight,
                sqlEditorBuilder: (context, width, height) => Column(
                children: [
                  _buildSectionHeader('Execute SQL', Icons.code),
                  Expanded(
                    child: SqlEditorPanel(
                      databasePath: widget.database!.path,
                      onSchemaChanged: widget.onSchemaChanged,
                      onQueryExecuted: _onQueryExecuted,
                    ),
                  ),
                ],
              ),
              resultsBuilder: (context, width, height) => Column(
                children: [
                  _buildSectionHeader('Results', Icons.table_rows),
                  Expanded(
                    child: _buildResultsPanel(),
                  ),
                ],
              ),
              databaseStructureBuilder: (context, width, height) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSectionHeader('Database Structure', Icons.account_tree),
                    Expanded(
                      child: _selectedTable == null
                          ? _buildChooseTableMessage('CHOOSE A TABLE OR VIEW')
                          : _buildDatabaseStructureContent(),
                    ),
                  ],
                ),
              ),
              browseDataBuilder: (context, width, height) => Column(
                children: [
                  _buildSectionHeader('Browse Data', Icons.table_view),
                  Expanded(
                    child: _selectedTable == null
                        ? _buildChooseTableMessage('CHOOSE A TABLE OR VIEW')
                        : _buildBrowseDataContent(),
                  ),
                ],
              ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseTableMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a table from the tree on the left',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseStructureContent() {
    // Check if table has structure
    final table = widget.database!.tables.firstWhere(
      (t) => t == _selectedTable,
      orElse: () => '',
    );
    
    if (table.isEmpty) {
      return _buildNoStructureMessage();
    }

    return TableStructurePanel(
      database: widget.database!,
      tableName: _selectedTable!,
    );
  }

  Widget _buildBrowseDataContent() {
    // Check if table has data structure
    final table = widget.database!.tables.firstWhere(
      (t) => t == _selectedTable,
      orElse: () => '',
    );
    
    if (table.isEmpty) {
      return _buildNoStructureMessage();
    }

    return DataBrowserPanel(
      database: widget.database!,
      tableName: _selectedTable!,
    );
  }

  Widget _buildNoStructureMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'TABLE WITHOUT STRUCTURE OR DATA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This table appears to be empty or malformed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel() {
    if (_queryResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Execute a query to see results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Write SQL in the editor above and press Ctrl+Enter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_queryResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Query executed successfully',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No rows returned',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Build results table
    final columns = _queryResults!.first.keys.toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with row count
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '${_queryResults!.length} row(s) returned',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          // Results table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 8,
              headingRowHeight: 40,
              dataRowMinHeight: 32,
              dataRowMaxHeight: 48,
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(
                        column,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: _queryResults!
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map(
                            (column) => DataCell(
                              Text(
                                row[column]?.toString() ?? 'NULL',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            size: 96,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'TOKYO DRIFT',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Open a database to start browsing',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
