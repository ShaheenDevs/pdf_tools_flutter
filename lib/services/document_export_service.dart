import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Shares and saves already-generated local documents through Android's
/// platform-provided system interfaces.
class DocumentExportService {
  Future<ShareResult> shareFile({
    required String filePath,
    required String title,
  }) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw const FileSystemException('The document file is unavailable.');
    }
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [XFile(filePath)],
      ),
    );
  }

  Future<String?> saveCopy({
    required String filePath,
    required String suggestedFileName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FileSystemException('The document file is unavailable.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FileSystemException('The document file is empty.');
    }
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save document copy',
      fileName: suggestedFileName,
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: [
        suggestedFileName.split('.').last.toLowerCase(),
      ],
    );
  }
}
