import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/document_scanner_service.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';
import 'package:pdf_tools_flutter/services/image_thumbnail_service.dart';
import 'package:pdf_tools_flutter/services/pdf_metadata_service.dart';
import 'package:stacked/stacked.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    DocumentRepository? repository,
    PdfMetadataService? pdfMetadataService,
    ImageThumbnailService? imageThumbnailService,
    FileStorageService? fileStorage,
    DocumentScannerService? scannerService,
    bool loadOnCreate = true,
  }) : _repository = repository ?? locator<DocumentRepository>(),
       _pdfMetadataService = pdfMetadataService ?? PdfMetadataService(),
       _imageThumbnailService =
           imageThumbnailService ?? ImageThumbnailService(),
       _fileStorage = fileStorage ?? locator<FileStorageService>(),
       _scannerService = scannerService ?? DocumentScannerService() {
    if (loadOnCreate) loadDocuments();
  }

  final DocumentRepository _repository;
  final PdfMetadataService _pdfMetadataService;
  final ImageThumbnailService _imageThumbnailService;
  final FileStorageService _fileStorage;
  final DocumentScannerService _scannerService;

  Future<String> absolutePathFor(String relativePath) =>
      _fileStorage.absolutePathFor(relativePath);

  Future<List<int>?> thumbnailBytesFor(String? relativePath) async {
    if (relativePath == null) return null;
    try {
      return await _fileStorage.readBytes(relativePath);
    } catch (_) {
      return null;
    }
  }

  List<Document> documents = [];
  String searchQuery = '';
  String? errorMessage;

  List<Document> get visibleDocuments {
    final String query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return documents;
    return documents.where((document) {
      return document.title.toLowerCase().contains(query) ||
          document.sourceType.toLowerCase().contains(query) ||
          p.extension(document.filePath).toLowerCase().contains(query);
    }).toList();
  }

  void updateSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    setBusy(true);
    errorMessage = null;
    notifyListeners();
    try {
      documents = await _repository.getDocuments();
    } catch (error) {
      errorMessage = 'Could not load documents. Please try again.';
    } finally {
      setBusy(false);
    }
  }

  Future<void> scanDocument() async {
    errorMessage = null;
    notifyListeners();
    try {
      final ScannedDocumentResult? scan =
          await _scannerService.scanDocuments();
      if (scan == null) return;
      final String? pdfPath = scan.pdfPath;
      if (pdfPath == null || scan.imagePaths.isEmpty) {
        throw const FormatException('The scanner returned incomplete output.');
      }
      final List<int> pdfBytes = await File(pdfPath).readAsBytes();
      final List<List<int>> pageBytes = [];
      for (final path in scan.imagePaths) {
        pageBytes.add(await File(path).readAsBytes());
      }
      final int documentId = await _repository.importScannedDocument(
        title: 'Scan ${DateTime.now().toLocal().toString().substring(0, 16)}',
        pdfBytes: pdfBytes,
        pageImageBytes: pageBytes,
      );
      try {
        final thumbnail = await _imageThumbnailService.createThumbnail(
          pageBytes.first,
        );
        await _repository.updateDocumentMetadata(
          documentId: documentId,
          pageCount: pageBytes.length,
          thumbnailBytes: thumbnail,
        );
      } catch (_) {
        // The original PDF and page images remain saved if thumbnailing fails.
      }
      await loadDocuments();
    } catch (error) {
      errorMessage = 'Scan could not be saved. Please try again.';
      notifyListeners();
    }
  }

  Future<void> importDocument() async {
    errorMessage = null;
    notifyListeners();
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      await importPlatformFile(result.files.single);
    } catch (error) {
      errorMessage = 'Import failed. Check the file and available storage.';
      notifyListeners();
    }
  }

  /// Imports a selected picker file; kept separate so the file workflow can be tested.
  Future<void> importPlatformFile(PlatformFile picked) async {
    errorMessage = null;
    notifyListeners();
    try {
      final String extension = p
          .extension(picked.name)
          .replaceFirst('.', '')
          .toLowerCase();
      if (!['pdf', 'jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        throw const FormatException('Unsupported document format.');
      }
      final List<int> bytes =
          picked.bytes ??
          (picked.path != null
              ? await File(picked.path!).readAsBytes()
              : <int>[]);
      if (bytes.isEmpty) {
        throw const FileSystemException('The selected file could not be read.');
      }
      final bool isPdf = extension == 'pdf';
      final String title = p.basenameWithoutExtension(picked.name).trim();
      final int documentId = await _repository.importDocument(
        title: title.isEmpty ? 'Imported document' : title,
        bytes: bytes,
        extension: extension,
        pageCount: isPdf ? 0 : 1,
        sourceType: isPdf ? 'imported_pdf' : 'imported_image',
      );
      String? importWarning;
      try {
        final List<int> thumbnailBytes;
        final int pageCount;
        if (isPdf) {
          final PdfMetadata metadata = await _pdfMetadataService.inspect(bytes);
          thumbnailBytes = metadata.firstPageThumbnail;
          pageCount = metadata.pageCount;
        } else {
          thumbnailBytes = await _imageThumbnailService.createThumbnail(bytes);
          pageCount = 1;
        }
        await _repository.updateDocumentMetadata(
          documentId: documentId,
          pageCount: pageCount,
          thumbnailBytes: thumbnailBytes,
        );
      } catch (error) {
        importWarning =
            'File imported, but its preview could not be generated. The original file is safe.';
      }
      await loadDocuments();
      errorMessage = importWarning;
      notifyListeners();
    } catch (error) {
      errorMessage = 'Import failed. Check the file and available storage.';
      notifyListeners();
    }
  }

  Future<void> renameDocument(int id, String title) async {
    try {
      await _repository.renameDocument(documentId: id, title: title);
      await loadDocuments();
    } catch (error) {
      errorMessage =
          'Could not rename this document. Use a title of 1–255 characters.';
      notifyListeners();
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _repository.deleteDocument(id);
      await loadDocuments();
    } catch (error) {
      errorMessage = 'Could not delete this document. Please try again.';
      notifyListeners();
    }
  }
}
