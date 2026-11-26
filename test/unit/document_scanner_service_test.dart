import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/services/document_scanner_service.dart';

void main() {
  test('removes scanner temporary PDF and page images', () async {
    final directory = await Directory.systemTemp.createTemp('scanner-cleanup-');
    try {
      final pdf = await File(
        '${directory.path}/scan.pdf',
      ).writeAsBytes([37, 80, 68, 70]);
      final page = await File(
        '${directory.path}/page.jpg',
      ).writeAsBytes([255, 216, 255]);
      final service = DocumentScannerService();

      await service.cleanupTemporaryFiles(
        ScannedDocumentResult(imagePaths: [page.path], pdfPath: pdf.path),
      );

      expect(await pdf.exists(), isFalse);
      expect(await page.exists(), isFalse);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('ignores missing scanner temporary files', () async {
    final service = DocumentScannerService();
    await expectLater(
      service.cleanupTemporaryFiles(
        const ScannedDocumentResult(
          imagePaths: ['/path/that/does/not/exist/page.jpg'],
          pdfPath: '/path/that/does/not/exist/scan.pdf',
        ),
      ),
      completes,
    );
  });
}
