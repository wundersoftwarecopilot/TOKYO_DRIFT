import 'dart:io';
import 'lib/models/drift_schema_parser.dart';

void main() async {
  print('Testing view parsing...\n');
  
  // Test with test_views.dart
  try {
    final schema = await DriftSchemaParser.parseFile('test_views.dart');
    
    print('Database: ${schema.databaseName}');
    print('Tables found: ${schema.tables.length}');
    for (var table in schema.tables) {
      print('  - ${table.name} (${table.columns.length} columns)');
    }
    
    print('\nViews found: ${schema.views.length}');
    for (var view in schema.views) {
      print('  - ${view.name}');
      print('    SQL name: ${view.sqlViewName}');
    }
    
    print('\n✓ Test passed!');
  } catch (e) {
    print('✗ Error: $e');
    exit(1);
  }
}
