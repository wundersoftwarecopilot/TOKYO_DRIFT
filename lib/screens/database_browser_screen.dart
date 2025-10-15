import 'package:flutter/material.dart';
import '../models/database_connection.dart';
import '../widgets/database_tree_view.dart';
import '../widgets/table_structure_panel.dart';
import '../widgets/sql_editor_panel.dart';
import '../widgets/data_browser_panel.dart';

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
  int _selectedTabIndex = 0; // 0: Data Browser, 1: Structure, 2: SQL Editor

  @override
  void didUpdateWidget(covariant DatabaseBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.database != null &&
        _selectedTable != null &&
        !widget.database!.tables.contains(_selectedTable)) {
      setState(() {
        _selectedTable = null;
        _selectedTabIndex = 0;
      });
    }
  }

  void _onTableSelected(String tableName) {
    setState(() {
      _selectedTable = tableName;
      _selectedTabIndex = 1; // Switch to Browse Data when table is selected
    });
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
            child: Column(
              children: [
                // Tab bar
                if (_selectedTable != null) _buildTabBar(),
                // Content area
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton('Database Structure', Icons.account_tree, 0),
          _buildTabButton('Browse Data', Icons.table_view, 1),
          _buildTabButton('Execute SQL', Icons.code, 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3)
                : null,
            border: isSelected
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18, // Increased icon size slightly
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15, // Increased font size
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.database == null) {
      return _buildWelcomeScreen();
    }

    if (_selectedTable == null) {
      return _buildNoTableSelected();
    }

    switch (_selectedTabIndex) {
      case 0: // Database Structure
        return TableStructurePanel(
          database: widget.database!,
          tableName: _selectedTable!,
        );
      case 1: // Browse Data
        return DataBrowserPanel(
          database: widget.database!,
          tableName: _selectedTable!,
        );
      case 2: // Execute SQL
        return SqlEditorPanel(
          databasePath: widget.database!.path,
          onSchemaChanged: widget.onSchemaChanged,
        );
      default:
        return const Center(child: Text('Unknown tab'));
    }
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

  Widget _buildNoTableSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a table from the database tree',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a table to view its data, structure, or execute SQL queries',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
