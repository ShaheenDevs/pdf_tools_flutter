import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/pdf_metadata_service.dart';
import 'package:pdf_tools_flutter/services/pdf_tools_service.dart';
import 'package:stacked/stacked.dart';

class PdfToolsViewModel extends BaseViewModel {
  PdfToolsViewModel({
    DocumentRepository? repository,
    PdfToolsService? pdfToolsService,
    PdfMetadataService? metadataService,
  }) : _repository = repository ?? locator<DocumentRepository>(),
       _pdfToolsService = pdfToolsService ?? PdfToolsService(),
       _metadataService = metadataService ?? PdfMetadataService();

  final DocumentRepository _repository;
  final PdfToolsService _pdfToolsService;
  final PdfMetadataService _metadataService;

  String? errorMessage;
  String? successMessage;
  Uint8List? _splitSourceBytes;
  String _splitSourceTitle = 'Document';
  int splitPageCount = 0;
  String splitRangeText = '';

  bool get hasSplitSource => _splitSourceBytes != null;

  Future<void> mergePdfs() async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true,
      );
      if (picked == null || picked.files.length < 2) {
        if (picked != null) errorMessage = 'Select at least two PDF files.';
        return;
      }
      final files = await Future.wait(picked.files.map(_readPickedFile));
      final merged = await _pdfToolsService.mergePdfs(files);
      final previewReady = await _savePdf(
        title: 'Merged ${DateTime.now().millisecondsSinceEpoch}',
        bytes: merged,
      );
      successMessage = 'Merged PDF saved to your document library.';
      if (!previewReady) errorMessage = 'PDF saved, but its preview is unavailable.';
    });
  }

  Future<void> selectPdfForSplit() async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = await _readPickedFile(file);
      final metadata = await _metadataService.inspect(bytes);
      _splitSourceBytes = Uint8List.fromList(bytes);
      _splitSourceTitle = p.basenameWithoutExtension(file.name);
      splitPageCount = metadata.pageCount;
      splitRangeText = '1-$splitPageCount';
      successMessage = 'Loaded $splitPageCount pages. Enter ranges to export.';
    });
  }

  void updateSplitRangeText(String value) => splitRangeText = value;

  Future<void> splitPdfByRanges(String rangeText) async {
    await _run(() async {
      final source = _splitSourceBytes;
      if (source == null) {
        throw StateError('Choose a PDF before splitting it.');
      }
      final ranges = _parsePageRanges(rangeText, splitPageCount);
      final outputs = await _pdfToolsService.splitPdfByRanges(
        sourceBytes: source,
        pageRanges: ranges,
      );
      for (var index = 0; index < outputs.length; index++) {
        final range = ranges[index];
        final label = range.length == 1
            ? 'page-${range.first + 1}'
            : 'pages-${range.first + 1}-${range.last + 1}';
        final previewReady = await _savePdf(
          title: '${_splitSourceTitle}_$label',
          bytes: outputs[index],
        );
        if (!previewReady) {
          errorMessage = 'A split PDF was saved, but its preview is unavailable.';
        }
      }
      successMessage = 'Created ${outputs.length} split PDF file(s).';
      _splitSourceBytes = null;
      splitPageCount = 0;
      splitRangeText = '';
    });
  }

  Future<void> imagesToPdf() async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final images = await Future.wait(picked.files.map(_readPickedFile));
      final output = await _pdfToolsService.imagesToPdf(images);
      final previewReady = await _savePdf(
        title: 'Images ${DateTime.now().millisecondsSinceEpoch}',
        bytes: output,
      );
      successMessage = 'Image PDF saved to your document library.';
      if (!previewReady) errorMessage = 'PDF saved, but its preview is unavailable.';
    });
  }

  Future<void> compressPdf() async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final source = await _readPickedFile(file);
      final compressed = await _pdfToolsService.compressPdf(source);
      final saved = await _savePdf(
        title: '${p.basenameWithoutExtension(file.name)}_compressed',
        bytes: compressed,
      );
      final difference = source.length - compressed.length;
      final percent = source.isEmpty
          ? 0
          : (difference * 100 / source.length).round();
      successMessage = difference > 0
          ? 'Compressed PDF saved ($percent% smaller).'
          : 'PDF saved. This file was already efficiently compressed.';
      if (!saved) {
        errorMessage = 'PDF saved, but its preview could not be generated.';
      }
    });
  }



  Future<void> signPdf(String certificatePassword) async {
    await _run(() async {
      final pdfPick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (pdfPick == null || pdfPick.files.isEmpty) return;
      final certificatePick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx'],
        allowMultiple: false,
        withData: true,
      );
      if (certificatePick == null || certificatePick.files.isEmpty) return;
      final source = await _readPickedFile(pdfPick.files.single);
      final certificate = await _readPickedFile(certificatePick.files.single);
      final signed = await _pdfToolsService.signPdf(
        sourceBytes: source,
        pkcs12Bytes: certificate,
        certificatePassword: certificatePassword,
        reason: 'Digitally signed',
      );
      final file = pdfPick.files.single;
      final previewReady = await _savePdf(
        title: '${p.basenameWithoutExtension(file.name)}_signed',
        bytes: signed,
      );
      successMessage = 'Digitally signed PDF saved as a separate library document.';
      if (!previewReady) errorMessage = 'PDF saved, but its preview is unavailable.';
    });
  }

  Future<void> watermarkPdf(String watermarkText) async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final source = await _readPickedFile(picked.files.single);
      final output = await _pdfToolsService.addWatermark(
        sourceBytes: source,
        text: watermarkText,
      );
      final previewReady = await _savePdf(
        title: '${p.basenameWithoutExtension(picked.files.single.name)}_watermarked',
        bytes: output,
      );
      successMessage = 'Watermarked PDF saved as a separate library document.';
      if (!previewReady) errorMessage = 'PDF saved, but its preview is unavailable.';
    });
  }

  Future<void> addPageNumbers() async {
    await _run(() async {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final source = await _readPickedFile(file);
      final output = await _pdfToolsService.addPageNumbers(source);
      final previewReady = await _savePdf(
        title: '${p.basenameWithoutExtension(file.name)}_numbered',
        bytes: output,
      );
      successMessage = 'Numbered PDF saved as a separate library document.';
      if (!previewReady) errorMessage = 'PDF saved, but its preview is unavailable.';
    });
  }

  Future<List<int>> _readPickedFile(PlatformFile file) async {
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) {
      throw const FileSystemException('A selected file could not be read.');
    }
    return bytes;
  }

  Future<bool> _savePdf({
    required String title,
    required List<int> bytes,
  }) async {
    if (bytes.isEmpty || !String.fromCharCodes(bytes.take(4)).startsWith('%PDF')) {
      throw const FormatException('The PDF operation returned an invalid file.');
    }
    final id = await _repository.importDocument(
      title: title,
      bytes: bytes,
      extension: 'pdf',
      pageCount: 0,
      sourceType: 'generated_pdf',
    );
    try {
      final metadata = await _metadataService.inspect(bytes);
      await _repository.updateDocumentMetadata(
        documentId: id,
        pageCount: metadata.pageCount,
        thumbnailBytes: metadata.firstPageThumbnail,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  List<List<int>> _parsePageRanges(String value, int pageCount) {
    final groups = value
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (groups.isEmpty) {
      throw const FormatException('Enter at least one page range.');
    }
    return groups.map((group) {
      final match = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(group);
      if (match == null) {
        throw FormatException('Invalid page range: $group');
      }
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2) ?? match.group(1)!);
      if (start < 1 || end < start || end > pageCount) {
        throw FormatException('Page range $group is outside 1–$pageCount.');
      }
      return List<int>.generate(end - start + 1, (index) => start - 1 + index);
    }).toList(growable: false);
  }

  Future<void> _run(Future<void> Function() action) async {
    errorMessage = null;
    successMessage = null;
    setBusy(true);
    try {
      await action();
    } catch (error) {
      errorMessage = error is FormatException || error is ArgumentError
          ? error.toString().replaceFirst('FormatException: ', '')
          : 'PDF operation failed. Check the selected files and available storage.';
    } finally {
      setBusy(false);
    }
  }
}
