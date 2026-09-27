import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

/// Wraps device file access so feature widgets never talk to
/// file_picker / open_filex directly.
class FileService {
  /// Lets the user pick a single PDF from device storage.
  /// Returns null if the user cancelled or the path is unavailable.
  Future<PickedPdf?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (file == null || file.path == null) return null;

    return PickedPdf(fileName: file.name, filePath: file.path!);
  }

  /// Opens a previously-stored PDF path with the device's default
  /// PDF viewer. Returns a human-readable error message on failure,
  /// or null on success.
  Future<String?> openPdf(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      return result.message;
    }
    return null;
  }
}

class PickedPdf {
  const PickedPdf({required this.fileName, required this.filePath});

  final String fileName;
  final String filePath;
}
