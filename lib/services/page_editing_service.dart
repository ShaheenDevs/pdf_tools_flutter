import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PageEditingService {
  Uint8List renderPage({
    required List<int> sourceBytes,
    required int rotation,
    String? cropData,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('The scanned page image is invalid.');
    }
    if (decoded.width * decoded.height > 40000000) {
      throw const FormatException('The scanned page is too large to edit.');
    }

    var page = decoded;
    if (cropData != null && cropData.isNotEmpty) {
      final crop = Map<String, dynamic>.from(jsonDecode(cropData) as Map);
      final left = (crop['left'] as num).toDouble().clamp(0.0, 0.45);
      final top = (crop['top'] as num).toDouble().clamp(0.0, 0.45);
      final right = (crop['right'] as num).toDouble().clamp(0.0, 0.45);
      final bottom = (crop['bottom'] as num).toDouble().clamp(0.0, 0.45);
      final x = (decoded.width * left).round();
      final y = (decoded.height * top).round();
      final width = (decoded.width * (1 - left - right)).round();
      final height = (decoded.height * (1 - top - bottom)).round();
      if (width < 16 || height < 16) {
        throw const FormatException('The crop area is too small.');
      }
      page = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: width,
        height: height,
      );
    }

    final normalizedRotation = ((rotation % 360) + 360) % 360;
    if (normalizedRotation != 0) {
      page = img.copyRotate(page, angle: normalizedRotation);
    }
    return Uint8List.fromList(img.encodeJpg(page, quality: 92));
  }

  Uint8List renderPagePng({
    required List<int> sourceBytes,
    required int rotation,
    String? cropData,
  }) {
    final jpeg = renderPage(
      sourceBytes: sourceBytes,
      rotation: rotation,
      cropData: cropData,
    );
    final decoded = img.decodeImage(jpeg);
    if (decoded == null) {
      throw const FormatException('The edited page could not be rendered.');
    }
    return Uint8List.fromList(img.encodePng(decoded));
  }

  Future<Uint8List> buildPdf(List<Uint8List> pageImages) async {
    if (pageImages.isEmpty) {
      throw ArgumentError('At least one page is required.');
    }
    final document = pw.Document();
    for (final bytes in pageImages) {
      final image = pw.MemoryImage(bytes);
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return document.save();
  }
}
