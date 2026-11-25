import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

class PdfMetadata {
  const PdfMetadata({
    required this.pageCount,
    required this.firstPageThumbnail,
  });

  final int pageCount;
  final Uint8List firstPageThumbnail;
}

class PdfMetadataService {
  Future<PdfMetadata> inspect(List<int> sourceBytes) async {
    if (sourceBytes.isEmpty) {
      throw const FormatException('The PDF file is empty.');
    }

    PdfDocument? document;
    PdfPage? firstPage;
    try {
      document = await PdfDocument.openData(Uint8List.fromList(sourceBytes));
      if (document.pagesCount < 1) {
        throw const FormatException('The PDF has no pages.');
      }

      firstPage = await document.getPage(1);
      final double targetWidth = 360;
      final double targetHeight =
          (firstPage.height * targetWidth / firstPage.width).clamp(1.0, 1200.0).toDouble();
      final PdfPageImage? rendered = await firstPage.render(
        width: targetWidth,
        height: targetHeight,
        format: PdfPageImageFormat.png,
        quality: 82,
      );
      if (rendered == null || rendered.bytes.isEmpty) {
        throw const FormatException('Could not render the first PDF page.');
      }

      return PdfMetadata(
        pageCount: document.pagesCount,
        firstPageThumbnail: rendered.bytes,
      );
    } finally {
      if (firstPage != null && !firstPage.isClosed) {
        await firstPage.close();
      }
      if (document != null && !document.isClosed) {
        await document.close();
      }
    }
  }
}
