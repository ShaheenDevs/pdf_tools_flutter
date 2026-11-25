import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/pdf_metadata_service.dart';
import 'package:stacked/stacked.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    DocumentRepository? repository,
    PdfMetadataService? pdfMetadataService,
  }) : _repository = repository ?? locator<DocumentRepository>(),
       _pdfMetadataService = pdfMetadataService ?? PdfMetadataService() {
    loadDocuments();
  }

  final DocumentRepository _repository;
  final PdfMetadataService _pdfMetadataService;
  List<Document> documents = [];
  String? errorMessage;

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

      final PlatformFile picked = result.files.single;
      final String extension = p.extension(picked.name).replaceFirst('.', '').toLowerCase();
      final List<int> bytes = picked.bytes ??
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
      if (isPdf) {
        try {
          final PdfMetadata metadata = await _pdfMetadataService.inspect(bytes);
          await _repository.updatePdfMetadata(
            documentId: documentId,
            pageCount: metadata.pageCount,
            thumbnailBytes: metadata.firstPageThumbnail,
          );
        } catch (error) {
          errorMessage =
              'PDF imported, but its preview could not be generated. The original file is safe.';
        }
      }
      await loadDocuments();
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
      errorMessage = 'Could not rename this document. Use a title of 1–255 characters.';
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
