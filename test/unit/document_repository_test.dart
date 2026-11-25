import 'dart:io';
import 'package:drift/drift.dart' show OrderingTerm;
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

  test('stores document preview metadata and removes its thumbnail on delete', () async {
    final id = await repository.importDocument(
      title: 'Metadata test',
      bytes: [37, 80, 68, 70],
      extension: 'pdf',
    );

    await repository.updateDocumentMetadata(
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

  test('persists scanned PDF and ordered source page images', () async {
    final id = await repository.importScannedDocument(
      title: 'Scan test',
      pdfBytes: [37, 80, 68, 70],
      pageImageBytes: [
        [255, 216, 255, 1],
        [255, 216, 255, 2],
      ],
    );

    final document = (await repository.getDocuments()).single;
    expect(document.id, id);
    expect(document.sourceType, 'scanned');
    expect(document.pageCount, 2);
    expect(await storage.readBytes(document.filePath), [37, 80, 68, 70]);

    final pages = await (database.select(database.documentPages)
          ..where((row) => row.documentId.equals(id))
          ..orderBy([(row) => OrderingTerm.asc(row.pageIndex)]))
        .get();
    expect(pages.map((page) => page.pageIndex), [0, 1]);
    expect(pages.every((page) => page.sourceImagePath != null), isTrue);
    for (var index = 0; index < pages.length; index++) {
      expect(
        await storage.readBytes(pages[index].sourceImagePath!),
        [255, 216, 255, index + 1],
      );
    }

    final storedPaths = pages.map((page) => page.sourceImagePath!).toList();
    await repository.deleteDocument(id);
    for (final path in storedPaths) {
      expect(
        () => storage.readBytes(path),
        throwsA(isA<FileSystemException>()),
      );
    }
  });

  test('reorders, rotates, crops, and deletes scanned pages atomically', () async {
    final id = await repository.importScannedDocument(
      title: 'Editable scan',
      pdfBytes: [37, 80, 68, 70],
      pageImageBytes: [
        [255, 216, 255, 1],
        [255, 216, 255, 2],
      ],
    );
    final initial = await repository.getDocumentPages(id);
    final firstPath = initial.first.sourceImagePath!;
    final secondPath = initial.last.sourceImagePath!;

    await repository.saveScannedPageEdits(
      documentId: id,
      orderedPageIds: [initial.last.id, initial.first.id],
      rotations: {initial.last.id: 90},
      cropData: {initial.first.id: '{"left":0.1,"top":0,"right":0.1,"bottom":0}'},
      deletePageIds: const [],
      pdfBytes: [37, 80, 68, 70, 1],
      thumbnailBytes: [137, 80, 78, 71],
    );

    var pages = await repository.getDocumentPages(id);
    expect(pages.map((page) => page.id), [initial.last.id, initial.first.id]);
    expect(pages.first.rotation, 90);
    expect(pages.last.cropData, contains('"left":0.1'));
    final document = (await repository.getDocuments()).single;
    expect(await storage.readBytes(document.filePath), [37, 80, 68, 70, 1]);

    await repository.saveScannedPageEdits(
      documentId: id,
      orderedPageIds: [pages.first.id],
      rotations: const {},
      cropData: const {},
      deletePageIds: [pages.last.id],
      pdfBytes: [37, 80, 68, 70, 2],
      thumbnailBytes: [137, 80, 78, 71, 2],
    );
    pages = await repository.getDocumentPages(id);
    expect(pages, hasLength(1));
    expect(pages.single.pageIndex, 0);
    expect(await storage.readBytes(secondPath), [255, 216, 255, 2]);
    expect(
      () => storage.readBytes(firstPath),
      throwsA(isA<FileSystemException>()),
    );
    expect((await repository.getDocuments()).single.pageCount, 1);
  });

  test('stores, lists, and deletes page annotations', () async {
    final documentId = await repository.importDocument(
      title: 'Annotated PDF',
      bytes: [37, 80, 68, 70],
      extension: 'pdf',
      pageCount: 2,
    );
    final inkId = await repository.addAnnotation(
      documentId: documentId,
      pageIndex: 0,
      type: 'ink',
      payload: '{\"points\":[[0.1,0.2],[0.4,0.5]]}',
    );
    await repository.addAnnotation(
      documentId: documentId,
      pageIndex: 1,
      type: 'signature',
      payload: '{\"points\":[[0.2,0.3],[0.5,0.6]]}',
    );
    expect(await repository.getAnnotations(documentId: documentId), hasLength(2));
    expect(await repository.getAnnotations(documentId: documentId, pageIndex: 0), hasLength(1));
    await repository.deleteAnnotation(inkId);
    expect(await repository.getAnnotations(documentId: documentId, pageIndex: 0), isEmpty);
    await repository.deleteDocument(documentId);
    expect(await repository.getAnnotations(documentId: documentId), isEmpty);
  });

  test('rejects empty document titles', () async {
    expect(
      repository.renameDocument(documentId: 1, title: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });
}
