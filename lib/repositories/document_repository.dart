import 'package:drift/drift.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';

class DocumentRepository {
  DocumentRepository({
    required AppDatabase database,
    required FileStorageService fileStorage,
  }) : _database = database,
       _fileStorage = fileStorage;

  final AppDatabase _database;
  final FileStorageService _fileStorage;

  Future<int> importDocument({
    required String title,
    required List<int> bytes,
    required String extension,
    int pageCount = 0,
    String sourceType = 'imported',
  }) async {
    final String relativePath = await _fileStorage.saveBytes(
      folder: StorageFolder.documents,
      bytes: bytes,
      extension: extension,
    );
    final DateTime now = DateTime.now();
    try {
      return await _database
          .into(_database.documents)
          .insert(
            DocumentsCompanion.insert(
              title: title.trim(),
              filePath: relativePath,
              pageCount: Value(pageCount),
              fileSize: Value(bytes.length),
              createdAt: now,
              updatedAt: now,
              sourceType: Value(sourceType),
            ),
          );
    } catch (_) {
      await _fileStorage.deleteFile(relativePath);
      rethrow;
    }
  }


  Future<int> importScannedDocument({
    required String title,
    required List<int> pdfBytes,
    required List<List<int>> pageImageBytes,
  }) async {
    if (pdfBytes.isEmpty || pageImageBytes.isEmpty) {
      throw ArgumentError('A scan must contain a PDF and at least one page.');
    }
    final String pdfPath = await _fileStorage.saveBytes(
      folder: StorageFolder.documents,
      bytes: pdfBytes,
      extension: 'pdf',
    );
    final List<String> imagePaths = [];
    try {
      for (final bytes in pageImageBytes) {
        if (bytes.isEmpty) {
          throw ArgumentError('Scanned page image cannot be empty.');
        }
        imagePaths.add(await _fileStorage.saveBytes(
          folder: StorageFolder.images,
          bytes: bytes,
          extension: 'jpg',
        ));
      }
      return await _database.transaction(() async {
        final DateTime now = DateTime.now();
        final int documentId = await _database.into(_database.documents).insert(
          DocumentsCompanion.insert(
            title: title.trim().isEmpty ? 'Scanned document' : title.trim(),
            filePath: pdfPath,
            pageCount: Value(imagePaths.length),
            fileSize: Value(pdfBytes.length),
            createdAt: now,
            updatedAt: now,
            sourceType: const Value('scanned'),
          ),
        );
        for (var index = 0; index < imagePaths.length; index++) {
          await _database.into(_database.documentPages).insert(
            DocumentPagesCompanion.insert(
              documentId: documentId,
              pageIndex: index,
              sourceImagePath: Value(imagePaths[index]),
            ),
          );
        }
        return documentId;
      });
    } catch (_) {
      await _fileStorage.deleteFile(pdfPath);
      for (final path in imagePaths) {
        await _fileStorage.deleteFile(path);
      }
      rethrow;
    }
  }

  Future<List<DocumentPage>> getDocumentPages(int documentId) {
    return (_database.select(_database.documentPages)
          ..where((row) => row.documentId.equals(documentId))
          ..orderBy([(row) => OrderingTerm.asc(row.pageIndex)]))
        .get();
  }

  Future<void> saveScannedPageEdits({
    required int documentId,
    required List<int> orderedPageIds,
    required Map<int, int> rotations,
    required Map<int, String?> cropData,
    required List<int> deletePageIds,
    required List<int> pdfBytes,
    required List<int> thumbnailBytes,
  }) async {
    if (orderedPageIds.isEmpty || pdfBytes.isEmpty || thumbnailBytes.isEmpty) {
      throw ArgumentError('A saved scan must contain at least one valid page.');
    }
    if (orderedPageIds.toSet().length != orderedPageIds.length) {
      throw ArgumentError('Page order contains duplicate IDs.');
    }

    final document = await (_database.select(_database.documents)
          ..where((row) => row.id.equals(documentId)))
        .getSingleOrNull();
    if (document == null || document.sourceType != 'scanned') {
      throw StateError('Scanned document was not found.');
    }
    final existingPages = await getDocumentPages(documentId);
    final deleteIds = deletePageIds.toSet();
    final expectedIds = existingPages
        .where((page) => !deleteIds.contains(page.id))
        .map((page) => page.id)
        .toSet();
    if (expectedIds.length != orderedPageIds.length ||
        !expectedIds.containsAll(orderedPageIds) ||
        deleteIds.any((id) => !existingPages.any((page) => page.id == id))) {
      throw ArgumentError('The edited page list does not match this document.');
    }

    final pdfPath = await _fileStorage.saveBytes(
      folder: StorageFolder.documents,
      bytes: pdfBytes,
      extension: 'pdf',
    );
    String? thumbnailPath;
    try {
      thumbnailPath = await _fileStorage.saveBytes(
        folder: StorageFolder.thumbnails,
        bytes: thumbnailBytes,
        extension: 'png',
      );
      await _database.transaction(() async {
        for (final page in existingPages) {
          await (_database.update(_database.documentPages)
                ..where((row) => row.id.equals(page.id)))
              .write(DocumentPagesCompanion(pageIndex: Value(-page.id)));
        }

        if (deleteIds.isNotEmpty) {
          await (_database.delete(_database.documentPages)
                ..where((row) => row.id.isIn(deleteIds)))
              .go();
        }

        for (var index = 0; index < orderedPageIds.length; index++) {
          final pageId = orderedPageIds[index];
          final page = existingPages.firstWhere((item) => item.id == pageId);
          await (_database.update(_database.documentPages)
                ..where((row) => row.id.equals(pageId)))
              .write(
            DocumentPagesCompanion(
              pageIndex: Value(index),
              rotation: Value(rotations[pageId] ?? page.rotation),
              cropData: Value(cropData.containsKey(pageId)
                  ? cropData[pageId]
                  : page.cropData),
            ),
          );
        }

        await (_database.update(_database.documents)
              ..where((row) => row.id.equals(documentId)))
            .write(
          DocumentsCompanion(
            filePath: Value(pdfPath),
            thumbnailPath: Value(thumbnailPath),
            pageCount: Value(orderedPageIds.length),
            fileSize: Value(pdfBytes.length),
            updatedAt: Value(DateTime.now()),
          ),
        );
      });
    } catch (_) {
      await _fileStorage.deleteFile(pdfPath);
      if (thumbnailPath != null) {
        await _fileStorage.deleteFile(thumbnailPath);
      }
      rethrow;
    }

    final deletedPaths = existingPages
        .where((page) => deleteIds.contains(page.id))
        .map((page) => page.sourceImagePath)
        .whereType<String>()
        .toSet();
    for (final path in deletedPaths) {
      try {
        await _fileStorage.deleteFile(path);
      } catch (_) {
        // The database no longer references this page; cleanup can be retried.
      }
    }
    try {
      await _fileStorage.deleteFile(document.filePath);
    } catch (_) {
      // The replacement PDF is already committed and remains usable.
    }
    if (document.thumbnailPath != null) {
      try {
        await _fileStorage.deleteFile(document.thumbnailPath!);
      } catch (_) {
        // The replacement thumbnail is already committed.
      }
    }
  }

  Future<void> updateDocumentMetadata({
    required int documentId,
    required int pageCount,
    required List<int> thumbnailBytes,
  }) async {
    if (pageCount < 1) {
      throw ArgumentError.value(pageCount, 'pageCount');
    }
    if (thumbnailBytes.isEmpty) {
      throw ArgumentError('Thumbnail data cannot be empty');
    }

    final Document? existing = await (_database.select(
      _database.documents,
    )..where((row) => row.id.equals(documentId))).getSingleOrNull();
    if (existing == null) {
      throw StateError('Document $documentId does not exist');
    }

    final String thumbnailPath = await _fileStorage.saveBytes(
      folder: StorageFolder.thumbnails,
      bytes: thumbnailBytes,
      extension: 'png',
    );
    try {
      await (_database.update(
        _database.documents,
      )..where((row) => row.id.equals(documentId))).write(
        DocumentsCompanion(
          pageCount: Value(pageCount),
          thumbnailPath: Value(thumbnailPath),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (_) {
      await _fileStorage.deleteFile(thumbnailPath);
      rethrow;
    }

    final String? previousThumbnail = existing.thumbnailPath;
    if (previousThumbnail != null && previousThumbnail != thumbnailPath) {
      await _fileStorage.deleteFile(previousThumbnail);
    }
  }

  Future<List<Document>> getDocuments() {
    return (_database.select(
      _database.documents,
    )..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])).get();
  }

  Future<void> renameDocument({
    required int documentId,
    required String title,
  }) async {
    final String normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 255) {
      throw ArgumentError.value(
        title,
        'title',
        'Title must be 1–255 characters',
      );
    }
    final int updated =
        await (_database.update(
          _database.documents,
        )..where((row) => row.id.equals(documentId))).write(
          DocumentsCompanion(
            title: Value(normalizedTitle),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) {
      throw StateError('Document $documentId does not exist');
    }
  }

  Future<void> deleteDocument(int documentId) async {
    final Document? document = await (_database.select(
      _database.documents,
    )..where((row) => row.id.equals(documentId))).getSingleOrNull();
    if (document == null) return;

    final List<DocumentPage> pages = await (_database.select(
      _database.documentPages,
    )..where((row) => row.documentId.equals(documentId))).get();
    await (_database.delete(
      _database.documents,
    )..where((row) => row.id.equals(documentId))).go();

    final Set<String> storedPaths = {
      document.filePath,
      if (document.thumbnailPath != null) document.thumbnailPath!,
      for (final DocumentPage page in pages)
        if (page.sourceImagePath != null) page.sourceImagePath!,
    };
    for (final String path in storedPaths) {
      await _fileStorage.deleteFile(path);
    }
  }
}
