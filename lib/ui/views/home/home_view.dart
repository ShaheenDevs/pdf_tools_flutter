import 'package:flutter/material.dart';
import 'package:pdf_tools_flutter/app/app_theme.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({super.key});

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
        actions: const [
          IconButton(
            tooltip: 'Settings will be available in a later milestone',
            onPressed: null,
            icon: Icon(Icons.settings_outlined),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: const [
            _WelcomeCard(),
            SizedBox(height: 26),
            Text(
              'Quick tools',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            _ToolGrid(),
            SizedBox(height: 28),
            Text(
              'Recent documents',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            _EmptyDocuments(),
          ],
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
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
  const _ToolGrid();

  static const List<_ToolItem> _items = [
    _ToolItem('Scan document', Icons.document_scanner_outlined),
    _ToolItem('Merge PDFs', Icons.merge_type_rounded),
    _ToolItem('Split PDF', Icons.call_split_rounded),
    _ToolItem('Images to PDF', Icons.image_outlined),
    _ToolItem('Compress PDF', Icons.compress_rounded),
    _ToolItem('Annotate PDF', Icons.edit_note_rounded),
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
        return Container(
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
            'Your scanned and imported PDFs will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
