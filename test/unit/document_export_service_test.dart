import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/services/document_export_service.dart';

void main() {
  late DocumentExportService service;

  setUp(() => service = DocumentExportService());

  test(
    'sharing a missing document fails before opening the share sheet',
    () async {
      await expectLater(
        service.shareFile(filePath: '/missing/document.pdf', title: 'Document'),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'saving a missing document fails before opening the save picker',
    () async {
      await expectLater(
        service.saveCopy(
          filePath: '/missing/document.pdf',
          suggestedFileName: 'document.pdf',
        ),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}
