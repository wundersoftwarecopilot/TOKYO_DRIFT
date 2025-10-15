import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database_connection.dart';

class QueryEditor extends StatefulWidget {
  final DatabaseConnection? database;

  const QueryEditor({super.key, this.database});

  @override
  State<QueryEditor> createState() => _QueryEditorState();
}

class _QueryEditorState extends State<QueryEditor>
    with TickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final List<QueryResult> _queryHistory = [];
  late TabController _tabController;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _queryController.text = 'SELECT * FROM sqlite_master WHERE type=\'table\';';
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.database == null) {
      return _buildEmptyState();
    }

    if (widget.database!.isReadOnly) {
      return _buildReadOnlyState();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SQL Query Editor'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.code), text: 'Query'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildQueryTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Open a database to start writing queries',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Query Editor Disabled',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'SQL queries are not available for Drift schema files.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Use the Explorer and Table Viewer to examine the schema structure.',
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

  Widget _buildQueryTab() {
    return Column(
      children: [
        _buildQueryInput(),
        _buildActionButtons(),
        Expanded(child: _buildResultsView()),
      ],
    );
  }

  Widget _buildQueryInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SQL Query', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _queryController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Enter your SQL query here...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _isExecuting ? null : _executeQuery,
            icon: _isExecuting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(_isExecuting ? 'Executing...' : 'Execute'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _clearQuery,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
          const Spacer(),
          Text(
            'Tip: Use Ctrl+Enter to execute',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_queryHistory.isEmpty) {
      return const Center(
        child: Text(
          'Execute a query to see results here',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final latestResult = _queryHistory.last;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Results', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(child: _buildQueryResultCard(latestResult)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_queryHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No query history',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              'Execute some queries to see them here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _queryHistory.length,
      itemBuilder: (context, index) {
        final result = _queryHistory[_queryHistory.length - 1 - index];
        return _buildQueryResultCard(result);
      },
    );
  }

  Widget _buildQueryResultCard(QueryResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isSuccess ? Icons.check_circle : Icons.error,
                  color: result.isSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.timestamp.toString().substring(0, 19),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyQuery(result.query),
                  tooltip: 'Copy Query',
                  iconSize: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.query,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            if (result.isSuccess) ...[
              Text(
                'Results: ${result.data!.length} row(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              if (result.data!.isNotEmpty)
                _buildResultTable(result.data!)
              else
                const Text('No rows returned'),
            ] else ...[
              Text(
                'Error:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(result.error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const Text('No data');

    final columns = data.first.keys.toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            columns: columns
                .map(
                  (column) => DataColumn(
                    label: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
            rows: data
                .take(50)
                .map(
                  (row) => DataRow(
                    cells: columns
                        .map(
                          (column) => DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                _formatValue(row[column]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is String && value.isEmpty) return '(empty)';
    return value.toString();
  }

  Future<void> _executeQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || widget.database == null) return;

    setState(() {
      _isExecuting = true;
    });

    try {
      final data = await widget.database!.query(query);
      final result = QueryResult(
        query: query,
        isSuccess: true,
        data: data,
        timestamp: DateTime.now(),
      );

      setState(() {
        _queryHistory.add(result);
        _isExecuting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Query executed successfully. ${data.length} row(s) returned.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final result = QueryResult(
        query: query,
        isSuccess: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );

      setState(() {
        _queryHistory.add(result);
        _isExecuting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Query failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearQuery() {
    _queryController.clear();
  }

  void _clearHistory() {
    setState(() {
      _queryHistory.clear();
    });
  }

  void _copyQuery(String query) {
    Clipboard.setData(ClipboardData(text: query));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Query copied to clipboard')));
  }
}

class QueryResult {
  final String query;
  final bool isSuccess;
  final List<Map<String, dynamic>>? data;
  final String? error;
  final DateTime timestamp;

  QueryResult({
    required this.query,
    required this.isSuccess,
    this.data,
    this.error,
    required this.timestamp,
  });
}
