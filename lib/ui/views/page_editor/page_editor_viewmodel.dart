import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';
import 'package:pdf_tools_flutter/services/page_editing_service.dart';
import 'package:stacked/stacked.dart';

class PageEditorViewModel extends BaseViewModel {
  PageEditorViewModel({
    required this.documentId,
    DocumentRepository? repository,
    FileStorageService? fileStorage,
    PageEditingService? editingService,
    bool loadOnCreate = true,
  }) : _repository = repository ?? locator<DocumentRepository>(),
       _fileStorage = fileStorage ?? locator<FileStorageService>(),
       _editingService = editingService ?? PageEditingService() {
    if (loadOnCreate) loadPages();
  }

  final int documentId;
  final DocumentRepository _repository;
  final FileStorageService _fileStorage;
  final PageEditingService _editingService;

  List<DocumentPage> pages = [];
  String? errorMessage;

  Future<void> loadPages() async {
    setBusy(true);
    errorMessage = null;
    try {
      pages = await _repository.getDocumentPages(documentId);
    } catch (_) {
      errorMessage = 'Could not load scanned pages.';
    } finally {
      setBusy(false);
    }
  }

  Future<Uint8List?> previewBytes(DocumentPage page) async {
    final path = page.sourceImagePath;
    if (path == null) return null;
    try {
      final bytes = await _fileStorage.readBytes(path);
      return _editingService.renderPage(
        sourceBytes: bytes,
        rotation: page.rotation,
        cropData: page.cropData,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> rotatePage(DocumentPage page) async {
    await _save(pages, rotations: {page.id: (page.rotation + 90) % 360});
  }

  Future<void> cropPage(
    DocumentPage page, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) async {
    final crop = jsonEncode({
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    });
    await _save(pages, cropData: {page.id: crop});
  }

  Future<void> reorderPage(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= pages.length) return;
    if (newIndex > oldIndex) newIndex--;
    if (newIndex < 0 || newIndex >= pages.length || newIndex == oldIndex) {
      return;
    }
    final reordered = List<DocumentPage>.of(pages);
    final page = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, page);
    await _save(reordered);
  }

  Future<void> deletePage(DocumentPage page) async {
    if (pages.length <= 1) {
      errorMessage = 'A scanned document must keep at least one page.';
      notifyListeners();
      return;
    }
    final remaining = pages.where((item) => item.id != page.id).toList();
    await _save(remaining, deletePageIds: [page.id]);
  }

  Future<void> _save(
    List<DocumentPage> orderedPages, {
    Map<int, int> rotations = const {},
    Map<int, String?> cropData = const {},
    List<int> deletePageIds = const [],
  }) async {
    setBusy(true);
    errorMessage = null;
    notifyListeners();
    try {
      final renderedPages = <Uint8List>[];
      for (final page in orderedPages) {
        final path = page.sourceImagePath;
        if (path == null) {
          throw StateError('A scanned page is missing its source image.');
        }
        final source = await _fileStorage.readBytes(path);
        renderedPages.add(
          _editingService.renderPage(
            sourceBytes: source,
            rotation: rotations[page.id] ?? page.rotation,
            cropData: cropData.containsKey(page.id)
                ? cropData[page.id]
                : page.cropData,
          ),
        );
      }

      final pdfBytes = await _editingService.buildPdf(renderedPages);
      final firstPage = orderedPages.first;
      final firstSource = await _fileStorage.readBytes(
        firstPage.sourceImagePath!,
      );
      final thumbnail = _editingService.renderPagePng(
        sourceBytes: firstSource,
        rotation: rotations[firstPage.id] ?? firstPage.rotation,
        cropData: cropData.containsKey(firstPage.id)
            ? cropData[firstPage.id]
            : firstPage.cropData,
      );

      await _repository.saveScannedPageEdits(
        documentId: documentId,
        orderedPageIds: orderedPages.map((page) => page.id).toList(),
        rotations: rotations,
        cropData: cropData,
        deletePageIds: deletePageIds,
        pdfBytes: pdfBytes,
        thumbnailBytes: thumbnail,
      );
      pages = await _repository.getDocumentPages(documentId);
    } catch (error) {
      errorMessage = 'Could not save page changes. Your previous PDF is safe.';
    } finally {
      setBusy(false);
    }
  }
}
