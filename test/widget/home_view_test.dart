import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_view.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_viewmodel.dart';

void main() {
  late AppDatabase database;
  late Directory storageRoot;

  setUp(() async {
    database = AppDatabase.forTesting();
    storageRoot = await Directory.systemTemp.createTemp('pdf-tools-widget-');
  });

  tearDown(() async {
    await database.close();
    if (await storageRoot.exists()) {
      await storageRoot.delete(recursive: true);
    }
  });

  testWidgets('home view displays the document workspace and empty library', (
    WidgetTester tester,
  ) async {
    final storage = FileStorageService(rootDirectory: storageRoot);
    final repository = DocumentRepository(
      database: database,
      fileStorage: storage,
    );
    final viewModel = HomeViewModel(
      repository: repository,
      fileStorage: storage,
    );
    await tester.pumpWidget(
      MaterialApp(home: HomeView(testViewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text('PDF Tools & Scanner'), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent documents'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Recent documents'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });
}
