import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:stacked/stacked.dart';

import 'page_editor_viewmodel.dart';

class PageEditorView extends StackedView<PageEditorViewModel> {
  const PageEditorView({
    required this.documentId,
    required this.title,
    super.key,
  });

  final int documentId;
  final String title;

  @override
  Widget builder(
    BuildContext context,
    PageEditorViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit pages'),
        actions: [
          if (viewModel.isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${viewModel.pages.length} pages'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: viewModel.isBusy && viewModel.pages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.pages.isEmpty
                  ? const Center(child: Text('No editable scan pages found.'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: viewModel.pages.length,
                      onReorder: viewModel.isBusy
                          ? (_, __) {}
                          : viewModel.reorderPage,
                      buildDefaultDragHandles: false,
                      itemBuilder: (context, index) {
                        final page = viewModel.pages[index];
                        return _PageCard(
                          key: ValueKey(page.id),
                          index: index,
                          page: page,
                          enabled: !viewModel.isBusy,
                          previewLoader: () => viewModel.previewBytes(page),
                          onRotate: () => viewModel.rotatePage(page),
                          onCrop: () => _cropPage(context, viewModel, page),
                          onDelete: () => _deletePage(context, viewModel, page),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropPage(
    BuildContext context,
    PageEditorViewModel viewModel,
    DocumentPage page,
  ) async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) => _CropDialog(initial: _readCrop(page.cropData)),
    );
    if (result == null) return;
    await viewModel.cropPage(
      page,
      left: result['left']!,
      top: result['top']!,
      right: result['right']!,
      bottom: result['bottom']!,
    );
  }

  Map<String, double> _readCrop(String? value) {
    if (value == null) {
      return {'left': 0, 'top': 0, 'right': 0, 'bottom': 0};
    }
    try {
      final values = Map<String, dynamic>.from(jsonDecode(value) as Map);
      return {
        'left': (values['left'] as num).toDouble(),
        'top': (values['top'] as num).toDouble(),
        'right': (values['right'] as num).toDouble(),
        'bottom': (values['bottom'] as num).toDouble(),
      };
    } catch (_) {
      return {'left': 0, 'top': 0, 'right': 0, 'bottom': 0};
    }
  }

  Future<void> _deletePage(
    BuildContext context,
    PageEditorViewModel viewModel,
    DocumentPage page,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete page?'),
        content: Text(
          'Page ${page.pageIndex + 1} will be removed from this scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await viewModel.deletePage(page);
  }

  @override
  PageEditorViewModel viewModelBuilder(BuildContext context) =>
      PageEditorViewModel(documentId: documentId);
}

class _PageCard extends StatefulWidget {
  const _PageCard({
    required super.key,
    required this.index,
    required this.page,
    required this.enabled,
    required this.previewLoader,
    required this.onRotate,
    required this.onCrop,
    required this.onDelete,
  });

  final int index;
  final DocumentPage page;
  final bool enabled;
  final Future<Uint8List?> Function() previewLoader;
  final VoidCallback onRotate;
  final VoidCallback onCrop;
  final VoidCallback onDelete;

  @override
  State<_PageCard> createState() => _PageCardState();
}

class _PageCardState extends State<_PageCard> {
  late Future<Uint8List?> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = widget.previewLoader();
  }

  @override
  void didUpdateWidget(covariant _PageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPage = oldWidget.page;
    final newPage = widget.page;
    if (oldPage.id != newPage.id ||
        oldPage.sourceImagePath != newPage.sourceImagePath ||
        oldPage.rotation != newPage.rotation ||
        oldPage.cropData != newPage.cropData) {
      _previewFuture = widget.previewLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            FutureBuilder<Uint8List?>(
              future: _previewFuture,
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                return Container(
                  width: 72,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: bytes == null
                      ? const Icon(Icons.image_not_supported_outlined)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            bytes,
                            width: 72,
                            height: 92,
                            fit: BoxFit.contain,
                          ),
                        ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${widget.index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rotation: ${widget.page.rotation}°',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Rotate 90 degrees',
              onPressed: widget.enabled ? widget.onRotate : null,
              icon: const Icon(Icons.rotate_right),
            ),
            IconButton(
              tooltip: 'Adjust crop',
              onPressed: widget.enabled ? widget.onCrop : null,
              icon: const Icon(Icons.crop),
            ),
            IconButton(
              tooltip: 'Delete page',
              onPressed: widget.enabled ? widget.onDelete : null,
              icon: const Icon(Icons.delete_outline),
            ),
            ReorderableDragStartListener(
              index: widget.index,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropDialog extends StatefulWidget {
  const _CropDialog({required this.initial});

  final Map<String, double> initial;

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  late final Map<String, double> _values = Map.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust crop margins'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final side in ['left', 'top', 'right', 'bottom'])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${side[0].toUpperCase()}${side.substring(1)} margin  ${(_values[side]! * 100).round()}%',
                  ),
                  Slider(
                    value: _values[side]!,
                    min: 0,
                    max: 0.4,
                    divisions: 40,
                    onChanged: (value) => setState(() => _values[side] = value),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => setState(() {
            _values.updateAll((key, value) => 0);
          }),
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _values),
          child: const Text('Apply crop'),
        ),
      ],
    );
  }
}
