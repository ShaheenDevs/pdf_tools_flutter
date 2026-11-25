import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Creates bounded PNG previews without blocking Flutter's UI isolate.
class ImageThumbnailService {
  Future<Uint8List> createThumbnail(List<int> sourceBytes) {
    if (sourceBytes.isEmpty) {
      throw const FormatException('The image file is empty.');
    }
    return compute(_createThumbnail, Uint8List.fromList(sourceBytes));
  }
}

Uint8List _createThumbnail(Uint8List sourceBytes) {
  // Bound compressed input before decoding; reject excessive dimensions immediately after.\n  if (sourceBytes.length > 30 * 1024 * 1024) {\n    throw const FormatException('The selected image is too large to preview.');\n  }\n  final img.Image? decoded = img.decodeImage(sourceBytes);
  if (decoded == null || decoded.width < 1 || decoded.height < 1 ||\n      decoded.width * decoded.height > 40 * 1000 * 1000) {
    throw const FormatException('The selected image could not be decoded.');
  }

  final int longestSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final double scale = 360 / longestSide;
  final int width = (decoded.width * scale).round().clamp(1, 360).toInt();
  final int height = (decoded.height * scale).round().clamp(1, 360);
  final img.Image thumbnail = img.copyResize(
    decoded,
    width: width,
    height: height,
  );
  return Uint8List.fromList(img.encodePng(thumbnail));
}
