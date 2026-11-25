import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum StorageFolder { documents, images, thumbnails, temporary }

class FileStorageService {
  FileStorageService({Directory? rootDirectory})
    : _providedRoot = rootDirectory;
  final Directory? _providedRoot;
  final Random _random = Random.secure();

  Future<Directory> get _root async {
    final Directory root =
        _providedRoot ??
        Directory(
          p.join((await getApplicationSupportDirectory()).path, 'pdf_tools'),
        );
    await root.create(recursive: true);
    return root;
  }

  Future<String> saveBytes({
    required StorageFolder folder,
    required List<int> bytes,
    required String extension,
  }) async {
    final String ext = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
    if (!RegExp(r'^[a-z0-9]{1,10}$').hasMatch(ext)) {
      throw ArgumentError.value(extension, 'extension', 'Invalid extension');
    }
    final String relative = p.join(
      folder.name,
      '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}.$ext',
    );
    final File destination = await _resolve(relative);
    await destination.parent.create(recursive: true);
    final File pending = File('${destination.path}.pending');
    try {
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(destination.path);
    } catch (_) {
      if (await pending.exists()) await pending.delete();
      rethrow;
    }
    return relative;
  }

  Future<List<int>> readBytes(String relativePath) async {
    final File file = await _resolve(relativePath);
    if (!await file.exists())
      throw FileSystemException('Stored file does not exist', file.path);
    return file.readAsBytes();
  }

  Future<void> deleteFile(String relativePath) async {
    final File file = await _resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  Future<File> _resolve(String relativePath) async {
    if (p.isAbsolute(relativePath))
      throw ArgumentError.value(relativePath, 'relativePath');
    final String normalized = p.normalize(relativePath);
    if (normalized == '.' ||
        normalized == '..' ||
        normalized.startsWith('..${p.separator}')) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    final String root = p.normalize((await _root).absolute.path);
    final String candidate = p.normalize(p.join(root, normalized));
    if (!p.isWithin(root, candidate))
      throw ArgumentError.value(relativePath, 'relativePath');
    return File(candidate);
  }
}
