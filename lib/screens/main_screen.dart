import 'package:flutter/material.dart';
import '../widgets/database_explorer.dart';
import '../widgets/query_editor.dart';
import '../widgets/table_viewer.dart';
import '../models/database_connection.dart';
import 'database_browser_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DatabaseConnection? _currentDatabase;
  String? _selectedTable;
  int _selectedIndex = 0;

  void _onDatabaseOpened(DatabaseConnection database) {
    setState(() {
      _currentDatabase = database;
      _selectedTable = null;
    });
  }

  void _onTableSelected(String tableName) {
    setState(() {
      _selectedTable = tableName;
      if (tableName == '__sql_mode__') {
        // Special signal to switch to SQL tab for Drift working mode
        _selectedIndex = 2; // Switch to SQL Editor
      } else {
        _selectedIndex = 1; // Switch to Table Viewer
      }
    });
  }

  void _onDatabaseClosed() {
    setState(() {
      _currentDatabase = null;
      _selectedTable = null;
    });
  }

  Future<void> _refreshCurrentDatabase() async {
    final current = _currentDatabase;
    if (current == null) return;

    final path = current.path;

    try {
      final refreshed = await DatabaseConnection.open(path);
      current.close();

      if (!mounted) {
        refreshed.close();
        return;
      }

      setState(() {
        _currentDatabase = refreshed;
        if (_selectedTable != null &&
            !refreshed.tables.contains(_selectedTable!)) {
          _selectedTable = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing database: $e')),
      );
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return DatabaseExplorer(
          database: _currentDatabase,
          onDatabaseOpened: _onDatabaseOpened,
          onTableSelected: _onTableSelected,
          onDatabaseClosed: _onDatabaseClosed,
        );
      case 1:
        return TableViewer(
          database: _currentDatabase,
          tableName: _selectedTable,
        );
      case 2:
        return QueryEditor(database: _currentDatabase);
      default:
        return const Center(child: Text('Unknown page'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a database is open, use the new database browser interface
    if (_currentDatabase != null) {
      return DatabaseBrowserScreen(
        database: _currentDatabase,
        onDatabaseClosed: _onDatabaseClosed,
        onSchemaChanged: _refreshCurrentDatabase,
      );
    }

    // Otherwise, show the main screen with database explorer
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storage, size: 28),
            SizedBox(width: 8),
            Text('TOKYO DRIFT', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Explorer'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart),
                label: Text('Table Viewer'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.code_outlined),
                selectedIcon: Icon(Icons.code),
                label: Text('Query Editor'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
