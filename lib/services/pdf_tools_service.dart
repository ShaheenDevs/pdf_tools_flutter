import 'dart:typed_data';

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
