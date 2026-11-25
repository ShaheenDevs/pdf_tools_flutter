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
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final storage = FileStorageService(rootDirectory: storageRoot);
    final repository = DocumentRepository(
      database: database,
      fileStorage: storage,
    );
    final viewModel = HomeViewModel(
      repository: repository,
      fileStorage: storage,
      loadOnCreate: false,
    );
    await viewModel.loadDocuments();
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(home: HomeView(testViewModel: viewModel)),
    );
    await tester.pump();

    expect(find.text('PDF Tools & Scanner'), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);

    expect(find.text('Scan document'), findsOneWidget);
    expect(find.text('Recent documents'), findsOneWidget);
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);

    await repository.importDocument(
      title: 'Travel notes',
      bytes: [1, 2, 3],
      extension: 'png',
      pageCount: 1,
      sourceType: 'imported_image',
    );
    await viewModel.loadDocuments();
    await tester.pump();
    expect(find.text('Travel notes'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'missing title');
    await tester.pump();
    expect(find.text('No documents match your search.'), findsOneWidget);
  });
}
