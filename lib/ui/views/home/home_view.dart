import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_tools_flutter/app/app_theme.dart';
import 'package:pdf_tools_flutter/database/app_database.dart';
import 'package:pdf_tools_flutter/ui/views/document_preview/document_preview_view.dart';
import 'package:pdf_tools_flutter/ui/views/page_editor/page_editor_view.dart';
import 'package:pdf_tools_flutter/ui/views/pdf_tools/pdf_tools_view.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key, this.testViewModel});

  final HomeViewModel? testViewModel;

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF Tools & Scanner',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
            ),
            Text(
              'Your documents, all in one place',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     tooltip: 'Import PDF or image',
        //     onPressed: viewModel.isBusy ? null : viewModel.importDocument,
        //     icon: const Icon(Icons.add_rounded),
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.loadDocuments,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const _WelcomeCard(),
              const SizedBox(height: 26),
              const Text(
                'Quick tools',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _ToolGrid(
                onScan: viewModel.isBusy ? null : viewModel.scanDocument,
                onPdfTools: (tool) => _openPdfTools(context, tool, viewModel),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent documents',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: viewModel.isBusy
                        ? null
                        : viewModel.importDocument,
                    icon: const Icon(Icons.file_open_outlined, size: 18),
                    label: const Text('Import'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: viewModel.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search documents',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: viewModel.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => viewModel.updateSearchQuery(''),
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE9ECF3)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (viewModel.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(viewModel.errorMessage!),
                    ),
                  ),
                ),
              if (viewModel.isBusy && viewModel.documents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (viewModel.documents.isEmpty)
                const _EmptyDocuments()
              else if (viewModel.visibleDocuments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No documents match your search.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              else
                ...viewModel.visibleDocuments.map(
                  (document) => _DocumentTile(
                    document: document,
                    onRename: () =>
                        _renameDocument(context, document, viewModel),
                    onDelete: () =>
                        _confirmDelete(context, document, viewModel),
                    onOpen: () => _openDocument(context, document, viewModel),
                    onEditPages: document.sourceType == 'scanned'
                        ? () => _openPageEditor(context, document, viewModel)
                        : null,
                    thumbnailLoader: () =>
                        viewModel.thumbnailBytesFor(document.thumbnailPath),
                  ),
                ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: viewModel.isBusy ? null : viewModel.importDocument,
      //   icon: const Icon(Icons.file_upload_outlined),
      //   label: const Text('Import file'),
      // ),
    );
  } 

  Future<void> _openPdfTools(
    BuildContext context,
    String initialTool,
    HomeViewModel viewModel,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfToolsView(initialTool: initialTool),
      ),
    );
    if (context.mounted) await viewModel.loadDocuments();
  }

  Future<void> _openDocument(
    BuildContext context,
    Document document,
    HomeViewModel viewModel,
  ) async {
    try {
      final String path = await viewModel.absolutePathFor(document.filePath);
      if (!context.mounted) return;
      final bool isPdf = p.extension(document.filePath).toLowerCase() == '.pdf';
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentPreviewView(
            title: document.title,
            filePath: path,
            isPdf: isPdf,
            documentId: document.id,
            pageCount: document.pageCount,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document.')),
      );
    }
  }

  Future<void> _openPageEditor(
    BuildContext context,
    Document document,
    HomeViewModel viewModel,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PageEditorView(documentId: document.id, title: document.title),
      ),
    );
    if (context.mounted) {
      // Reload the library so updated page counts and thumbnails are visible.
      await viewModel.loadDocuments();
    }
  }

  Future<void> _renameDocument(
    BuildContext context,
    Document document,
    HomeViewModel viewModel,
  ) async {
    final controller = TextEditingController(text: document.title);
    final String? title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Document name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null) await viewModel.renameDocument(document.id, title);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Document document,
    HomeViewModel viewModel,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('“${document.title}” will be removed from this device.'),
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
    if (confirmed == true) await viewModel.deleteDocument(document.id);
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) =>
      testViewModel ?? HomeViewModel();
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF3157D5), Color(0xFF5477E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.document_scanner_outlined, color: Colors.white, size: 32),
          SizedBox(height: 18),
          Text(
            'Go paperless.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Scan, organize and manage your PDFs securely on your device.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({this.onScan, this.onPdfTools});

  final VoidCallback? onScan;
  final ValueChanged<String>? onPdfTools;

  static const List<_ToolItem> _items = [
    _ToolItem('Scan document', Icons.document_scanner_outlined),
    _ToolItem('Merge PDFs', Icons.merge_type_rounded),
    _ToolItem('Split PDF', Icons.call_split_rounded),
    _ToolItem('Images to PDF', Icons.image_outlined),
    _ToolItem('Compress PDF', Icons.compress_rounded),
    // _ToolItem('Annotate PDF', Icons.edit_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final item = _items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: item.label == 'Scan document'
              ? onScan
              : const [
                      'Merge PDFs',
                      'Split PDF',
                      'Images to PDF',
                      'Compress PDF',
                    ].contains(item.label) &&
                    onPdfTools != null
              ? () => onPdfTools!(item.label)
              : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9ECF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: AppTheme.primary, size: 25),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9ECF3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 38, color: Colors.black38),
          SizedBox(height: 12),
          Text(
            'No documents yet',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            'Import a PDF or image to see it in your local library.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatefulWidget {
  const _DocumentTile({
    required this.document,
    required this.onRename,
    required this.onDelete,
    required this.onOpen,
    required this.onEditPages,
    required this.thumbnailLoader,
  });

  final Document document;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onOpen;
  final VoidCallback? onEditPages;
  final Future<List<int>?> Function() thumbnailLoader;

  @override
  State<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<_DocumentTile> {
  late Future<List<int>?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.thumbnailLoader();
  }

  @override
  void didUpdateWidget(covariant _DocumentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.thumbnailPath != widget.document.thumbnailPath) {
      _thumbnailFuture = widget.thumbnailLoader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final bool isPdf = p.extension(document.filePath).toLowerCase() == '.pdf';
    final String size = document.fileSize < 1024 * 1024
        ? '${(document.fileSize / 1024).toStringAsFixed(0)} KB'
        : '${(document.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE9ECF3)),
      ),
      child: ListTile(
        onTap: widget.onOpen,
        leading: FutureBuilder<List<int>?>(
          future: _thumbnailFuture,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null && bytes.isNotEmpty) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  Uint8List.fromList(bytes),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              );
            }
            return CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.10),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                color: AppTheme.primary,
              ),
            );
          },
        ),
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${isPdf ? 'PDF' : 'Image'} • $size${document.pageCount > 0 ? ' • ${document.pageCount} pages' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') widget.onRename();
            if (value == 'delete') widget.onDelete();
            if (value == 'editPages') widget.onEditPages?.call();
          },
          itemBuilder: (context) => [
            if (widget.onEditPages != null)
              const PopupMenuItem(
                value: 'editPages',
                child: Text('Edit pages'),
              ),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
