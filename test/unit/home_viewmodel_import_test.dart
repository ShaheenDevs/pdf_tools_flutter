import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';
import 'package:pdf_tools_flutter/ui/views/home/home_viewmodel.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  late AppDatabase database;
  late Directory root;
  late FileStorageService storage;
  late DocumentRepository repository;
  late HomeViewModel viewModel;

  setUp(() async {
    database = AppDatabase.forTesting();
    root = await Directory.systemTemp.createTemp('pdf-import-vm-test-');
    storage = FileStorageService(rootDirectory: root);
    repository = DocumentRepository(database: database, fileStorage: storage);
    viewModel = HomeViewModel(repository: repository, fileStorage: storage);
    await viewModel.loadDocuments();
  });

  tearDown(() async {
    await database.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('imports an image, persists its thumbnail, and refreshes the library', () async {
    final img.Image source = img.Image(width: 720, height: 480);
    final Uint8List bytes = Uint8List.fromList(img.encodePng(source));

    await viewModel.importPlatformFile(
      PlatformFile(name: 'Receipt.png', size: bytes.length, bytes: bytes),
    );

    final documents = await repository.getDocuments();
    expect(documents, hasLength(1));
    expect(documents.single.title, 'Receipt');
    expect(documents.single.pageCount, 1);
    expect(documents.single.thumbnailPath, isNotNull);
    expect(await storage.readBytes(documents.single.thumbnailPath!), isNotEmpty);
    expect(viewModel.documents, hasLength(1));
    expect(viewModel.errorMessage, isNull);
  });

  test('rejects unsupported file extensions without adding a document', () async {
    await viewModel.importPlatformFile(
      PlatformFile(name: 'notes.txt', size: 3, bytes: Uint8List.fromList([1, 2, 3])),
    );

    expect(await repository.getDocuments(), isEmpty);
    expect(viewModel.errorMessage, contains('Import failed'));
  });
}
