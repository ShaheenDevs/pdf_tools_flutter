import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_tools_flutter/services/page_editing_service.dart';
import 'package:pdf_tools_flutter/services/pdf_tools_service.dart';

void main() {
  late PdfToolsService service;
  late Uint8List imageBytes;
  late Uint8List onePagePdf;

  setUp(() async {
    service = PdfToolsService();
    final image = img.Image(width: 80, height: 120);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));
    imageBytes = Uint8List.fromList(img.encodePng(image));
    onePagePdf = await PageEditingService().buildPdf([imageBytes]);
  });

  Future<int> pageCountOf(List<int> bytes) async {
    final engine = Pdf();
    try {
      final document = await engine.open(
        PdfInput(MemorySource(Uint8List.fromList(bytes))),
      );
      final count = document.pageCount;
      await document.dispose();
      return count;
    } finally {
      await engine.dispose();
    }
  }

  test('merges two PDFs and preserves both pages', () async {
    final merged = await service.mergePdfs([onePagePdf, onePagePdf]);
    expect(String.fromCharCodes(merged.take(4)), '%PDF');
    expect(await pageCountOf(merged), 2);
  });

  test('splits selected page ranges into separate valid PDFs', () async {
    final source = await PageEditingService().buildPdf([
      imageBytes,
      imageBytes,
      imageBytes,
    ]);
    final parts = await service.splitPdfByRanges(
      sourceBytes: source,
      pageRanges: [
        [0],
        [1, 2],
      ],
    );

    expect(parts, hasLength(2));
    expect(await pageCountOf(parts[0]), 1);
    expect(await pageCountOf(parts[1]), 2);
  });

  test('converts multiple images to a multi-page PDF', () async {
    final result = await service.imagesToPdf([imageBytes, imageBytes]);
    expect(String.fromCharCodes(result.take(4)), '%PDF');
    expect(await pageCountOf(result), 2);
  });

  test('compresses a valid PDF without increasing its size', () async {
    final result = await service.compressPdf(onePagePdf);
    expect(String.fromCharCodes(result.take(4)), '%PDF');
    expect(result.length, lessThanOrEqualTo(onePagePdf.length));
  });

  test('adds a watermark without changing the page count', () async {
    final result = await service.addWatermark(
      sourceBytes: onePagePdf,
      text: 'CONFIDENTIAL',
    );
    expect(String.fromCharCodes(result.take(4)), '%PDF');
    expect(await pageCountOf(result), 1);
  });

  test('adds distinct page numbers to every page', () async {
    final source = await PageEditingService().buildPdf([
      imageBytes,
      imageBytes,
      imageBytes,
    ]);
    final result = await service.addPageNumbers(source);
    expect(String.fromCharCodes(result.take(4)), '%PDF');
    expect(await pageCountOf(result), 3);
  });

  test('exports normalized markup as an image stamp in a PDF copy', () async {
    final result = await service.exportAnnotatedPdf(
      sourceBytes: onePagePdf,
      annotationsByPage: {
        0: [
          const PdfAnnotationStroke(
            points: [ui.Offset(0.2, 0.3), ui.Offset(0.7, 0.6)],
            color: 0xFF172554,
            type: 'ink',
          ),
          const PdfAnnotationStroke(
            points: [ui.Offset(0.25, 0.7), ui.Offset(0.8, 0.7)],
            color: 0x66FFCC00,
            type: 'highlight',
          ),
        ],
      },
    );

    expect(String.fromCharCodes(result.take(4)), '%PDF');
    expect(await pageCountOf(result), 1);
    expect(await pageCountOf(onePagePdf), 1);
  });

  test('requires at least one markup for annotated export', () async {
    await expectLater(
      service.exportAnnotatedPdf(
        sourceBytes: onePagePdf,
        annotationsByPage: const {},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('requires certificate credentials for digital signing', () async {
    await expectLater(
      service.signPdf(
        sourceBytes: onePagePdf,
        pkcs12Bytes: const [],
        certificatePassword: 'password',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('reports malformed PDF inputs clearly', () async {
    await expectLater(
      service.mergePdfs([
        [1, 2, 3],
        [4, 5, 6],
      ]),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects invalid merge input', () {
    expect(
      () => service.mergePdfs([
        [1, 2, 3],
      ]),
      throwsA(isA<ArgumentError>()),
    );
  });
}
