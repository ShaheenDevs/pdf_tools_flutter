import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pdf_tools_flutter/app/app.locator.dart';
import 'package:pdf_tools_flutter/database/app_database.dart' as db;
import 'package:pdf_tools_flutter/repositories/document_repository.dart';
import 'package:pdf_tools_flutter/services/document_export_service.dart';
import 'package:pdf_tools_flutter/services/pdf_metadata_service.dart';
import 'package:pdf_tools_flutter/services/pdf_tools_service.dart';

enum MarkupTool { pen, highlight, signature }

class AnnotationEditorView extends StatefulWidget {
  const AnnotationEditorView({
    required this.documentId,
    required this.title,
    required this.filePath,
    required this.pageCount,
    super.key,
  });

  final int documentId;
  final String title;
  final String filePath;
  final int pageCount;

  @override
  State<AnnotationEditorView> createState() => _AnnotationEditorViewState();
}

class _AnnotationEditorViewState extends State<AnnotationEditorView> {
  final DocumentRepository _repository = locator<DocumentRepository>();
  final PdfToolsService _pdfToolsService = PdfToolsService();
  final PdfMetadataService _metadataService = PdfMetadataService();
  final DocumentExportService _exportService = DocumentExportService();
  final List<Offset> _currentStroke = [];
  PdfDocument? _document;
  Uint8List? _pageImage;
  List<_SavedStroke> _savedStrokes = [];
  MarkupTool _tool = MarkupTool.pen;
  Color _inkColor = const Color(0xFF1E3A8A);
  double _strokeWidth = 3;
  static const List<Color> _palette = [Color(0xFF1E3A8A), Color(0xFFEF4444), Color(0xFF059669), Color(0xFFFBBF24), Color(0xFF111827)];
  int _page = 1;
  double _pageAspectRatio = 0.707;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _openDocument();
  }

  @override
  void dispose() {
    final document = _document;
    if (document != null && !document.isClosed) {
      unawaited(document.close());
    }
    super.dispose();
  }

  Future<void> _openDocument() async {
    try {
      final document = await PdfDocument.openFile(widget.filePath);
      if (!mounted) {
        await document.close();
        return;
      }
      _document = document;
      await _loadPage();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Could not open this PDF for annotation.';
        });
      }
    }
  }

  Future<void> _loadPage() async {
    final document = _document;
    if (document == null) return;
    setState(() {
      _loading = true;
      _pageImage = null;
      _currentStroke.clear();
    });
    PdfPage? page;
    try {
      page = await document.getPage(_page);
      final ratio = page.width / page.height;
      const width = 1400.0;
      final height = (width / ratio).roundToDouble();
      final rendered = await page.render(
        width: width,
        height: height,
        format: PdfPageImageFormat.png,
        quality: 95,
      );
      if (rendered == null || rendered.bytes.isEmpty) {
        throw const FormatException('Could not render the selected PDF page.');
      }
      final rows = await _repository.getAnnotations(
        documentId: widget.documentId,
        pageIndex: _page - 1,
      );
      if (!mounted) return;
      setState(() {
        _pageAspectRatio = ratio;
        _pageImage = rendered.bytes;
        _savedStrokes = rows.map(_SavedStroke.fromRow).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message = 'Could not load this page or its saved markups.';
        });
      }
    } finally {
      if (page != null && !page.isClosed) await page.close();
    }
  }

  Future<void> _changePage(int delta) async {
    final next = (_page + delta).clamp(1, widget.pageCount).toInt();
    if (next == _page) return;
    setState(() {
      _page = next;
      _message = null;
    });
    await _loadPage();
  }

  void _startStroke(DragStartDetails details, Size size) {
    setState(() {
      _currentStroke
        ..clear()
        ..add(_normalize(details.localPosition, size));
    });
  }

  void _extendStroke(DragUpdateDetails details, Size size) {
    setState(() => _currentStroke.add(_normalize(details.localPosition, size)));
  }

  Offset _normalize(Offset point, Size size) => Offset(
    (point.dx / size.width).clamp(0.0, 1.0).toDouble(),
    (point.dy / size.height).clamp(0.0, 1.0).toDouble(),
  );

  Future<void> _saveStroke() async {
    if (_currentStroke.length < 2) {
      setState(() => _currentStroke.clear());
      return;
    }
    setState(() => _saving = true);
    try {
      final type = switch (_tool) {
        MarkupTool.pen => 'ink',
        MarkupTool.highlight => 'highlight',
        MarkupTool.signature => 'signature',
      };
      final color = _tool == MarkupTool.highlight ? 0x66FFCC00 : _inkColor.toARGB32();
      final payload = jsonEncode({
        'color': color,
        'width': _strokeWidth,
        'points': _currentStroke
            .map((point) => [point.dx, point.dy])
            .toList(growable: false),
      });
      await _repository.addAnnotation(
        documentId: widget.documentId,
        pageIndex: _page - 1,
        type: type,
        payload: payload,
      );
      await _loadPage();
      if (mounted) setState(() => _message = 'Markup saved on this device.');
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not save this markup. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportAnnotatedCopy() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final rows = await _repository.getAnnotations(
        documentId: widget.documentId,
      );
      final grouped = <int, List<PdfAnnotationStroke>>{};
      for (final row in rows) {
        final payload = jsonDecode(row.payload) as Map<String, dynamic>;
        final rawPoints = payload['points'] as List?;
        if (rawPoints == null || rawPoints.length < 2) continue;
        final points = rawPoints
            .map((point) {
              final pair = point as List;
              if (pair.length != 2) {
                throw const FormatException('A saved markup point is invalid.');
              }
              final x = (pair[0] as num).toDouble();
              final y = (pair[1] as num).toDouble();
              if (!x.isFinite ||
                  !y.isFinite ||
                  x < 0 ||
                  x > 1 ||
                  y < 0 ||
                  y > 1) {
                throw const FormatException(
                  'A saved markup point is outside the page.',
                );
              }
              return Offset(x, y);
            })
            .toList(growable: false);
        grouped
            .putIfAbsent(row.pageIndex, () => [])
            .add(
              PdfAnnotationStroke(
                points: points,
                color: payload['color'] as int? ?? 0xFF172554,
                type: row.type,
              ),
            );
      }
      final sourceBytes = await File(widget.filePath).readAsBytes();
      final annotated = await _pdfToolsService.exportAnnotatedPdf(
        sourceBytes: sourceBytes,
        annotationsByPage: grouped,
      );
      final metadata = await _metadataService.inspect(annotated);
      final newId = await _repository.importDocument(
        title: '${widget.title}_annotated',
        bytes: annotated,
        extension: 'pdf',
        pageCount: metadata.pageCount,
        sourceType: 'annotated_export',
      );
      await _repository.updateDocumentMetadata(
        documentId: newId,
        pageCount: metadata.pageCount,
        thumbnailBytes: metadata.firstPageThumbnail,
      );
      if (mounted) {
        setState(
          () => _message = 'Annotated PDF copy saved to your document library.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is ArgumentError || error is FormatException
              ? error.toString().replaceFirst('FormatException: ', '')
              : 'Could not export the annotated PDF. Your original document is safe.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearPageMarkups() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear page markups?'),
        content: const Text('This removes saved annotations from this page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      final rows = await _repository.getAnnotations(
        documentId: widget.documentId,
        pageIndex: _page - 1,
      );
      for (final row in rows) {
        await _repository.deleteAnnotation(row.id);
      }
      await _loadPage();
      if (mounted) setState(() => _message = 'Page markups cleared.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not clear page markups.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Annotate: ${widget.title}'),
        actions: [
          IconButton(tooltip: 'Share PDF', onPressed: _saving || _loading ? null : _shareDocument, icon: const Icon(Icons.share_outlined)),
          IconButton(tooltip: 'Save a copy', onPressed: _saving || _loading ? null : _saveDocumentCopy, icon: const Icon(Icons.file_download_outlined)),
          IconButton(
            tooltip: 'Export annotated copy',
            onPressed: _saving || _loading ? null : _exportAnnotatedCopy,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: _page > 1 && !_loading
                      ? () => _changePage(-1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    'Page $_page of ${widget.pageCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: _page < widget.pageCount && !_loading
                      ? () => _changePage(1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _toolChoice(MarkupTool.pen, 'Pen', Icons.edit),
                const SizedBox(width: 8),
                _toolChoice(MarkupTool.highlight, 'Highlight', Icons.wb_sunny_outlined),
                const SizedBox(width: 8),
                _toolChoice(MarkupTool.signature, 'Signature', Icons.gesture),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Text('Color:', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(width: 8),
              ..._palette.map((color) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _inkColor = color),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(color: _inkColor == color ? Theme.of(context).colorScheme.primary : Colors.white, width: _inkColor == color ? 3 : 1),
                    ),
                    child: _inkColor == color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                ),
              )),
              const Spacer(),
              Text('Stroke:', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(width: 6),
              DropdownButton<double>(
                value: _strokeWidth,
                underline: const SizedBox.shrink(),
                items: const [2.0, 3.0, 5.0, 8.0].map((v) => DropdownMenuItem(value: v, child: Text('\${v.toInt()}'))).toList(),
                onChanged: (v) { if (v != null) setState(() => _strokeWidth = v); },
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight * _pageAspectRatio,
                );
                final height = width / _pageAspectRatio;
                final size = Size(width, height);
                return Center(
                  child: _pageImage == null
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: width,
                          height: height,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_pageImage!, fit: BoxFit.fill),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) =>
                                    _startStroke(details, size),
                                onPanUpdate: (details) =>
                                    _extendStroke(details, size),
                                onPanEnd: (_) => _saveStroke(),
                                child: CustomPaint(
                                  painter: _MarkupPainter(
                                    strokes: _savedStrokes,
                                    current: _currentStroke,
                                    currentTool: _tool,
                                  ),
                                  size: size,
                                ),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
          ),
          if (_loading || _saving) const LinearProgressIndicator(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving || _loading ? null : _clearPageMarkups,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear page'),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving || _loading ? null : _saveStroke,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save markup'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      await _exportService.shareFile(filePath: widget.filePath, title: widget.title);
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not share this PDF.');
    }
  }

  Future<void> _saveDocumentCopy() async {
    try {
      final saved = await _exportService.saveCopy(
        filePath: widget.filePath,
        suggestedFileName: widget.title.toLowerCase().endsWith('.pdf') ? widget.title : '\${widget.title}.pdf',
      );
      if (mounted && saved != null) setState(() => _message = 'PDF copy saved.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Could not save a PDF copy.');
    }
  }

  Widget _toolChoice(MarkupTool tool, String label, IconData icon) {
    return ChoiceChip(
      selected: _tool == tool,
      onSelected: (_) => setState(() => _tool = tool),
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SavedStroke {
  const _SavedStroke({
    required this.points,
    required this.color,
    required this.type,
  });

  final List<Offset> points;
  final int color;
  final String type;

  factory _SavedStroke.fromRow(db.Annotation row) {
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    final points = (payload['points'] as List)
        .map(
          (point) => Offset(
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    return _SavedStroke(
      points: points,
      color: payload['color'] as int? ?? 0xFF172554,
      type: row.type,
    );
  }
}

class _MarkupPainter extends CustomPainter {
  const _MarkupPainter({
    required this.strokes,
    required this.current,
    required this.currentTool,
  });

  final List<_SavedStroke> strokes;
  final List<Offset> current;
  final MarkupTool currentTool;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _draw(canvas, size, stroke.points, stroke.color, stroke.type);
    }
    final type = switch (currentTool) {
      MarkupTool.pen => 'ink',
      MarkupTool.highlight => 'highlight',
      MarkupTool.signature => 'signature',
    };
    _draw(
      canvas,
      size,
      current,
      currentTool == MarkupTool.highlight ? 0x66FFCC00 : 0xFF172554,
      type,
    );
  }

  void _draw(
    Canvas canvas,
    Size size,
    List<Offset> points,
    int color,
    String type,
  ) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Color(color)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = type == 'highlight' ? 18 : 3;
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkupPainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.current != current ||
      oldDelegate.currentTool != currentTool;
}
