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


  Future<void> updatePdfMetadata({
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
