import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';

void main() {
  late AppDatabase database;
  late Directory root;
  late FileStorageService storage;
  late DocumentRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting();
    root = await Directory.systemTemp.createTemp('pdf-repository-test-');
    storage = FileStorageService(rootDirectory: root);
    repository = DocumentRepository(database: database, fileStorage: storage);
  });

  tearDown(() async {
    await database.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('imports, lists, renames, and deletes a local document', () async {
    final id = await repository.importDocument(
      title: '  Contract  ',
      bytes: [37, 80, 68, 70],
      extension: 'pdf',
      pageCount: 2,
    );
    var documents = await repository.getDocuments();
    expect(documents, hasLength(1));
    expect(documents.single.title, 'Contract');
    expect(documents.single.fileSize, 4);
    expect(await storage.readBytes(documents.single.filePath), [
      37,
      80,
      68,
      70,
    ]);

    await repository.renameDocument(documentId: id, title: 'Signed contract');
    documents = await repository.getDocuments();
    expect(documents.single.title, 'Signed contract');

    final String path = documents.single.filePath;
    await repository.deleteDocument(id);
    expect(await repository.getDocuments(), isEmpty);
    expect(() => storage.readBytes(path), throwsA(isA<FileSystemException>()));
  });

  test('stores PDF page metadata and removes its thumbnail on delete', () async {
    final id = await repository.importDocument(
      title: 'Metadata test',
      bytes: [37, 80, 68, 70],
      extension: 'pdf',
    );

    await repository.updatePdfMetadata(
      documentId: id,
      pageCount: 3,
      thumbnailBytes: [137, 80, 78, 71],
    );

    final document = (await repository.getDocuments()).single;
    expect(document.pageCount, 3);
    expect(document.thumbnailPath, isNotNull);
    expect(await storage.readBytes(document.thumbnailPath!), [
      137,
      80,
      78,
      71,
    ]);

    final thumbnailPath = document.thumbnailPath!;
    await repository.deleteDocument(id);
    expect(
      () => storage.readBytes(thumbnailPath),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('rejects empty document titles', () async {
    expect(
      repository.renameDocument(documentId: 1, title: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });
}
