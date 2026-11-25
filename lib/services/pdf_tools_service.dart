import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

/// Offline PDF operations backed by the native Rust PDF engine.
class PdfToolsService {
  Future<Uint8List> mergePdfs(List<List<int>> pdfBytes) async {
    if (pdfBytes.length < 2 || pdfBytes.any((bytes) => bytes.isEmpty)) {
      throw ArgumentError('Select at least two non-empty PDF files.');
    }

    final pdf = Pdf();
    final output = MemorySink();
    try {
      final inputs = pdfBytes
          .map((bytes) => PdfInput(MemorySource(Uint8List.fromList(bytes))))
          .toList(growable: false);
      await _runPdf(() => pdf.merge(inputs, output));
      return output.takeBytes();
    } finally {
      await pdf.dispose();
    }
  }

  /// Creates one output PDF for each requested inclusive, zero-based page range.
  Future<List<Uint8List>> splitPdfByRanges({
    required List<int> sourceBytes,
    required List<List<int>> pageRanges,
  }) async {
    if (sourceBytes.isEmpty || pageRanges.isEmpty) {
      throw ArgumentError('A source PDF and at least one page range are required.');
    }

    final pdf = Pdf();
    try {
      final outputs = <Uint8List>[];
      for (final range in pageRanges) {
        if (range.isEmpty || range.toSet().length != range.length) {
          throw ArgumentError('Each page range must contain unique page indexes.');
        }
        final sink = MemorySink();
        final input = PdfInput(MemorySource(Uint8List.fromList(sourceBytes)));
        await _runPdf(
          () => pdf.editOnce(input, sink).keepPages(PdfPages.list(range)),
        );
        final bytes = sink.takeBytes();
        if (bytes.isEmpty) {
          throw const FormatException('The split PDF could not be generated.');
        }
        outputs.add(bytes);
      }
      return outputs;
    } finally {
      await pdf.dispose();
    }
  }

  Future<Uint8List> imagesToPdf(List<List<int>> imageBytes) async {
    if (imageBytes.isEmpty || imageBytes.any((bytes) => bytes.isEmpty)) {
      throw ArgumentError('Select at least one valid image.');
    }

    final pdf = Pdf();
    final output = MemorySink();
    try {
      final images = imageBytes
          .map((bytes) => MemorySource(Uint8List.fromList(bytes)))
          .toList(growable: false);
      await _runPdf(() => pdf.imagesToPdf(images, output));
      return output.takeBytes();
    } finally {
      await pdf.dispose();
    }
  }

  Future<Uint8List> compressPdf(List<int> sourceBytes) async {
    if (sourceBytes.isEmpty) {
      throw ArgumentError('The source PDF is empty.');
    }

    final pdf = Pdf();
    final output = MemorySink();
    try {
      await _runPdf(
        () => pdf.compress(
          PdfInput(MemorySource(Uint8List.fromList(sourceBytes))),
          output,
        ),
      );
      final compressed = output.takeBytes();
      if (compressed.isEmpty) {
        throw const FormatException('The compressed PDF is empty.');
      }
      return compressed;
    } finally {
      await pdf.dispose();
    }
  }


  Future<Uint8List> addWatermark({
    required List<int> sourceBytes,
    required String text,
  }) async {
    final normalized = text.trim();
    if (sourceBytes.isEmpty || normalized.isEmpty || normalized.length > 80) {
      throw ArgumentError('Enter watermark text up to 80 characters.');
    }
    final pdf = Pdf();
    final output = MemorySink();
    try {
      await _runPdf(() => pdf.rewrite(
        PdfInput(MemorySource(Uint8List.fromList(sourceBytes))),
        output,
        (editor) async {
          await editor.addWatermark(
            normalized,
            style: PdfWatermarkStyle(
              fontSize: 34,
              opacity: 0.22,
              rotation: -35,
            ),
            position: const PdfWatermarkPosition.center(),
            layer: PdfWatermarkLayer.foreground,
          );
        },
      ));
      return output.takeBytes();
    } finally {
      await pdf.dispose();
    }
  }

  Future<Uint8List> addPageNumbers(List<int> sourceBytes) async {
    if (sourceBytes.isEmpty) {
      throw ArgumentError('The source PDF is empty.');
    }
    final pdf = Pdf();
    final output = MemorySink();
    try {
      await _runPdf(() => pdf.rewrite(
        PdfInput(MemorySource(Uint8List.fromList(sourceBytes))),
        output,
        (editor) async {
          final count = await editor.pageCount();
          for (var page = 0; page < count; page++) {
            await editor.addWatermark(
              'Page ${page + 1} of $count',
              pages: PdfPages.single(page),
              style: const PdfWatermarkStyle(
                fontSize: 9,
                opacity: 0.85,
                rotation: 0,
              ),
              position: const PdfWatermarkPosition.corner(
                PdfCorner.bottomRight,
                marginX: 28,
                marginY: 20,
              ),
              layer: PdfWatermarkLayer.foreground,
            );
          }
        },
      ));
      return output.takeBytes();
    } finally {
      await pdf.dispose();
    }
  }


  Future<Uint8List> signPdf({
    required List<int> sourceBytes,
    required List<int> pkcs12Bytes,
    required String certificatePassword,
    String? reason,
    String? location,
  }) async {
    if (sourceBytes.isEmpty || pkcs12Bytes.isEmpty ||
        certificatePassword.isEmpty) {
      throw ArgumentError('A PDF, PKCS#12 certificate, and certificate password are required.');
    }
    final pdf = Pdf();
    final output = MemorySink();
    try {
      await _runPdf(() => pdf.sign(
        PdfInput(MemorySource(Uint8List.fromList(sourceBytes))),
        output,
        credentials: PdfSigningCredentials.pkcs12(
          Uint8List.fromList(pkcs12Bytes),
          certificatePassword,
        ),
        reason: reason,
        location: location,
      ));
      final signed = output.takeBytes();
      if (signed.isEmpty) {
        throw const FormatException('The signed PDF is empty.');
      }
      return signed;
    } finally {
      await pdf.dispose();
    }
  }

  /// Embeds saved normalized markup strokes into a separate PDF copy as
  /// transparent page-sized image stamps. The source PDF is never modified.
  Future<Uint8List> exportAnnotatedPdf({
    required List<int> sourceBytes,
    required Map<int, List<PdfAnnotationStroke>> annotationsByPage,
  }) async {
    if (sourceBytes.isEmpty) {
      throw ArgumentError('The source PDF is empty.');
    }
    if (annotationsByPage.isEmpty ||
        annotationsByPage.values.every((strokes) => strokes.isEmpty)) {
      throw ArgumentError('Add at least one markup before exporting.');
    }

    final pdf = Pdf();
    final output = MemorySink();
    try {
      await _runPdf(() => pdf.rewrite(
        PdfInput(MemorySource(Uint8List.fromList(sourceBytes))),
        output,
        (editor) async {
          final pageInfo = await editor.pageInfo();
          for (final entry in annotationsByPage.entries) {
            final pageIndex = entry.key;
            if (pageIndex < 0 || pageIndex >= pageInfo.length) {
              throw ArgumentError('Markup refers to a page outside this PDF.');
            }
            if (entry.value.isEmpty) continue;
            final info = pageInfo[pageIndex];
            final overlayBytes = await _renderMarkupOverlay(
              entry.value,
              widthPoints: info.effectiveWidth,
              heightPoints: info.effectiveHeight,
            );
            await editor.addImageStamp(
              MemorySource(overlayBytes),
              bounds: PdfRect(
                x: 0,
                y: 0,
                width: info.effectiveWidth,
                height: info.effectiveHeight,
              ),
              pages: PdfPages.single(pageIndex),
            );
          }
        },
      ));
      final result = output.takeBytes();
      if (result.isEmpty) {
        throw const FormatException('The annotated PDF could not be generated.');
      }
      return result;
    } finally {
      await pdf.dispose();
    }
  }

  Future<Uint8List> _renderMarkupOverlay(
    List<PdfAnnotationStroke> strokes, {
    required double widthPoints,
    required double heightPoints,
  }) async {
    if (widthPoints <= 0 || heightPoints <= 0) {
      throw const FormatException('The PDF page has invalid dimensions.');
    }
    const pixelsPerPoint = 2.0;
    final width = (widthPoints * pixelsPerPoint).round().clamp(1, 2400);
    final height = (heightPoints * pixelsPerPoint).round().clamp(1, 3200);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(width.toDouble(), height.toDouble());

    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = ui.Paint()
        ..color = Color(stroke.color)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = (stroke.type == 'highlight' ? 18.0 : 3.0) / 350.0;
      final path = ui.Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const FormatException('Could not encode the markup overlay.');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  Future<T> _runPdf<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PdfPasswordRequired {
      throw const FormatException(
        'This PDF is password-protected. Choose an unlocked copy.',
      );
    } on PdfCorrupted {
      throw const FormatException(
        'A selected PDF is damaged or is not a valid PDF file.',
      );
    } on PdfError catch (error) {
      throw FormatException('PDF operation failed: ${error.message}');
    }
  }
}

/// One saved pen, highlight, or freehand-signature stroke in page coordinates.
class PdfAnnotationStroke {
  const PdfAnnotationStroke({
    required this.points,
    required this.color,
    required this.type,
  });

  /// Points normalized to the visible page bounds (0.0–1.0).
  final List<ui.Offset> points;
  final int color;
  final String type;
}
