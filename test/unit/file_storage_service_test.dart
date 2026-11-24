import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools_flutter/services/file_storage_service.dart';

void main() {
  late Directory root;
  late FileStorageService storage;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf-tools-test-');
    storage = FileStorageService(rootDirectory: root);
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('writes, reads, and deletes a relative file', () async {
    final path = await storage.saveBytes(
      folder: StorageFolder.documents, bytes: [1, 2, 3], extension: '.pdf',
    );
    expect(path.startsWith('documents'), isTrue);
    expect(await storage.readBytes(path), [1, 2, 3]);
    await storage.deleteFile(path);
    expect(storage.readBytes(path), throwsA(isA<FileSystemException>()));
  });

  test('rejects path traversal and unsafe extensions', () async {
    expect(() => storage.readBytes('../outside.txt'), throwsA(isA<ArgumentError>()));
    expect(() => storage.saveBytes(
      folder: StorageFolder.images, bytes: [1], extension: '../pdf',
    ), throwsA(isA<ArgumentError>()));
  });
}
