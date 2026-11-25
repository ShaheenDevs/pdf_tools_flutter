import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_tools_flutter/services/image_thumbnail_service.dart';

void main() {
  late ImageThumbnailService service;

  setUp(() {
    service = ImageThumbnailService();
  });

  test('creates a bounded PNG thumbnail from an image', () async {
    final img.Image source = img.Image(width: 900, height: 450);
    final Uint8List bytes = Uint8List.fromList(img.encodePng(source));

    final Uint8List thumbnailBytes = await service.createThumbnail(bytes);
    final img.Image? thumbnail = img.decodeImage(thumbnailBytes);

    expect(thumbnail, isNotNull);
    expect(thumbnail!.width, 360);
    expect(thumbnail.height, 180);
  });

  test('rejects empty and invalid image data', () async {
    expect(
      () => service.createThumbnail(<int>[]),
      throwsA(isA<FormatException>()),
    );
    expect(
      service.createThumbnail(<int>[1, 2, 3, 4]),
      throwsA(isA<FormatException>()),
    );
  });
}
