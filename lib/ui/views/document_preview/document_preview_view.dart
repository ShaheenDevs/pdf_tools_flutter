import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_tools_flutter/ui/views/annotation_editor/annotation_editor_view.dart';
import 'package:pdf_tools_flutter/services/document_export_service.dart';

class DocumentPreviewView extends StatefulWidget {
  const DocumentPreviewView({
    required this.title,
    required this.filePath,
    required this.isPdf,
    this.documentId,
    this.pageCount = 1,
    super.key,
  });

  final String title;
  final String filePath;
  final bool isPdf;
  final int? documentId;
  final int pageCount;

  @override
  State<DocumentPreviewView> createState() => _DocumentPreviewViewState();
}

class _DocumentPreviewViewState extends State<DocumentPreviewView> {
  PdfController? _pdfController;
  final DocumentExportService _exportService = DocumentExportService();
  bool _exporting = false;

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

  Future<void> _shareDocument() async {
    setState(() => _exporting = true);
    try {
      final result = await _exportService.shareFile(
        filePath: widget.filePath,
        title: widget.title,
      );
      if (!mounted) return;
      final message = result.status == ShareResultStatus.dismissed
          ? 'Sharing cancelled.'
          : 'Share sheet opened.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share this document.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveDocumentCopy() async {
    setState(() => _exporting = true);
    try {
      final extension = widget.filePath.split('.').last.toLowerCase();
      final safeTitle = widget.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savedPath = await _exportService.saveCopy(
        filePath: widget.filePath,
        suggestedFileName: '$safeTitle.$extension',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savedPath == null
              ? 'Save cancelled.'
              : 'Document copy saved.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this document copy.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Share document',
            onPressed: _exporting ? null : _shareDocument,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Save a copy',
            onPressed: _exporting ? null : _saveDocumentCopy,
            icon: const Icon(Icons.download_outlined),
          ),
          if (widget.isPdf && widget.documentId != null && widget.pageCount > 0)
            IconButton(
              tooltip: 'Annotate PDF',
              icon: const Icon(Icons.draw_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AnnotationEditorView(
                    documentId: widget.documentId!,
                    title: widget.title,
                    filePath: widget.filePath,
                    pageCount: widget.pageCount,
                  ),
                ),
              ),
            ),
        ],
      ),
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
