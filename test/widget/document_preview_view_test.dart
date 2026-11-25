import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf_tools_flutter/ui/views/document_preview/document_preview_view.dart';

void main() {
  late Directory root;
  late File imageFile;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf-preview-test-');
    final img.Image source = img.Image(width: 120, height: 80);
    imageFile = File('${root.path}/preview.png');
    await imageFile.writeAsBytes(Uint8List.fromList(img.encodePng(source)));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  testWidgets('opens a local image in the document preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentPreviewView(
          title: 'Local image',
          filePath: imageFile.path,
          isPdf: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local image'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
