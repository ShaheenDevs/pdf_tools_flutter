import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class DocumentPreviewView extends StatefulWidget {
  const DocumentPreviewView({
    required this.title,
    required this.filePath,
    required this.isPdf,
    super.key,
  });

  final String title;
  final String filePath;
  final bool isPdf;

  @override
  State<DocumentPreviewView> createState() => _DocumentPreviewViewState();
}

class _DocumentPreviewViewState extends State<DocumentPreviewView> {
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.filePath),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.isPdf
          ? PdfView(
              controller: _pdfController!,
              builders: PdfViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not open this PDF: $error'),
                  ),
                ),
              ),
            )
          : Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(widget.filePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not open this image.'),
                  ),
                ),
              ),
            ),
    );
  }
}
