import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class ScannedDocumentResult {
  const ScannedDocumentResult({
    required this.imagePaths,
    required this.pdfPath,
  });

  final List<String> imagePaths;
  final String? pdfPath;
}

class DocumentScannerService {
  Future<ScannedDocumentResult?> scanDocuments() async {
    final result = await CunningDocumentScanner.scanDocuments(
      scannerSource: ScannerSource.cameraAndGallery,
      output: ScanOutput.imagesAndPdf,
    );
    if (result == null) return null;
    return ScannedDocumentResult(
      imagePaths: result.images,
      pdfPath: result.pdf,
    );
  }

  /// Removes scanner-plugin temporary outputs after the app has copied them
  /// into its own managed storage. Cleanup is best-effort and never masks the
  /// result of the import workflow.
  Future<void> cleanupTemporaryFiles(ScannedDocumentResult result) async {
    final paths = <String>{
      ...result.imagePaths,
      if (result.pdfPath != null) result.pdfPath!,
    };
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Temporary cache cleanup must not invalidate an already saved scan.
      }
    }
  }
}
