import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_tools_flutter/services/page_editing_service.dart';

void main() {
  late PageEditingService service;
  late Uint8List sourceBytes;

  setUp(() {
    service = PageEditingService();
    final image = img.Image(width: 120, height: 180);
    img.fill(image, color: img.ColorRgb8(245, 245, 245));
    sourceBytes = Uint8List.fromList(img.encodePng(image));
  });

  test('renders rotated and cropped pages with expected dimensions', () {
    final rotated = img.decodeImage(
      service.renderPage(sourceBytes: sourceBytes, rotation: 90),
    )!;
    expect(rotated.width, 180);
    expect(rotated.height, 120);

    final cropped = img.decodeImage(
      service.renderPage(
        sourceBytes: sourceBytes,
        rotation: 0,
        cropData: '{"left":0.1,"top":0.1,"right":0.1,"bottom":0.1}',
      ),
    )!;
    expect(cropped.width, 96);
    expect(cropped.height, 144);
  });

  test('builds a multi-page PDF from edited images', () async {
    final page = service.renderPage(
      sourceBytes: sourceBytes,
      rotation: 0,
    );
    final pdf = await service.buildPdf([page, page]);
    expect(pdf.length, greaterThan(100));
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('rejects invalid source image data', () {
    expect(
      () => service.renderPage(sourceBytes: [1, 2, 3], rotation: 0),
      throwsA(isA<FormatException>()),
    );
  });
}
