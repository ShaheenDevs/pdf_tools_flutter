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
      output: ScanOutput.imagesAndPdf,
    );
    if (result == null) return null;
    return ScannedDocumentResult(
      imagePaths: result.images,
      pdfPath: result.pdf,
    );
  }
}
