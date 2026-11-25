import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'pdf_tools_viewmodel.dart';

class PdfToolsView extends StackedView<PdfToolsViewModel> {
  const PdfToolsView({this.initialTool, super.key});

  final String? initialTool;

  @override
  Widget builder(
    BuildContext context,
    PdfToolsViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(initialTool ?? 'PDF tools')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Work with files on this device. Generated PDFs are saved in your document library.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (viewModel.errorMessage != null)
              _StatusMessage(
                message: viewModel.errorMessage!,
                isError: true,
              ),
            if (viewModel.successMessage != null)
              _StatusMessage(message: viewModel.successMessage!),
            _ToolCard(
              icon: Icons.merge_type_rounded,
              title: 'Merge PDFs',
              description: 'Combine two or more PDF files in the selected order.',
              buttonLabel: 'Choose PDFs',
              busy: viewModel.isBusy,
              onPressed: viewModel.mergePdfs,
            ),
            _ToolCard(
              icon: Icons.call_split_rounded,
              title: 'Split PDF',
              description: 'Export one or more page ranges as separate PDF files.',
              buttonLabel: viewModel.hasSplitSource ? 'Choose another PDF' : 'Choose PDF',
              busy: viewModel.isBusy,
              onPressed: viewModel.selectPdfForSplit,
            ),
            if (viewModel.hasSplitSource) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected PDF: ${viewModel.splitPageCount} pages',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey(viewModel.splitPageCount),
                        initialValue: viewModel.splitRangeText,
                        onChanged: viewModel.updateSplitRangeText,
                        decoration: const InputDecoration(
                          labelText: 'Page ranges',
                          hintText: 'Example: 1-3; 4-6; 8',
                          helperText: 'Use semicolons to create separate output files.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: viewModel.isBusy
                            ? null
                            : () => viewModel.splitPdfByRanges(viewModel.splitRangeText),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Create split PDFs'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            _ToolCard(
              icon: Icons.image_outlined,
              title: 'Images to PDF',
              description: 'Turn multiple JPG or PNG images into one PDF.',
              buttonLabel: 'Choose images',
              busy: viewModel.isBusy,
              onPressed: viewModel.imagesToPdf,
            ),
            _ToolCard(
              icon: Icons.verified_user_outlined,
              title: 'Digital signature',
              description: 'Sign with a PKCS#12 / PFX certificate stored on your device.',
              buttonLabel: 'Choose certificate',
              busy: viewModel.isBusy,
              onPressed: () => _requestCertificatePassword(context, viewModel),
            ),
            _ToolCard(
              icon: Icons.branding_watermark_outlined,
              title: 'Add watermark',
              description: 'Add custom translucent text to every page and save a copy.',
              buttonLabel: 'Choose PDF',
              busy: viewModel.isBusy,
              onPressed: () => _requestWatermark(context, viewModel),
            ),
            _ToolCard(
              icon: Icons.format_list_numbered_rounded,
              title: 'Add page numbers',
              description: 'Place page numbers at the bottom-right of each page.',
              buttonLabel: 'Choose PDF',
              busy: viewModel.isBusy,
              onPressed: viewModel.addPageNumbers,
            ),
            _ToolCard(
              icon: Icons.library_add_check_outlined,
              title: 'Batch compress PDFs',
              description: 'Compress several PDFs independently; one failed file will not stop the rest.',
              buttonLabel: 'Choose multiple PDFs',
              busy: viewModel.isBusy,
              onPressed: viewModel.batchCompressPdfs,
            ),
            _ToolCard(
              icon: Icons.compress_rounded,
              title: 'Compress PDF',
              description: 'Optimize a PDF locally and save a separate compressed copy.',
              buttonLabel: 'Choose PDF',
              busy: viewModel.isBusy,
              onPressed: viewModel.compressPdf,
            ),
            if (viewModel.isBusy && viewModel.batchTotal > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: viewModel.batchTotal == 0
                    ? null
                    : viewModel.batchCompleted / viewModel.batchTotal,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Processed ${viewModel.batchCompleted} of ${viewModel.batchTotal}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: viewModel.cancelBatch,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop after current file'),
                  ),
                ],
              ),
            ] else if (viewModel.isBusy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }



  Future<void> _requestCertificatePassword(
    BuildContext context,
    PdfToolsViewModel viewModel,
  ) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Certificate password'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'PKCS#12 / PFX password',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password != null && password.isNotEmpty) {
      await viewModel.signPdf(password);
    }
  }

  Future<void> _requestWatermark(
    BuildContext context,
    PdfToolsViewModel viewModel,
  ) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Watermark text'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'e.g. CONFIDENTIAL',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null && text.trim().isNotEmpty) {
      await viewModel.watermarkPdf(text);
    }
  }

  @override
  PdfToolsViewModel viewModelBuilder(BuildContext context) =>
      PdfToolsViewModel();
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: busy ? null : onPressed,
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
