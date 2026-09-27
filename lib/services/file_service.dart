import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class FileService {
  Future<PickedPdf?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (file == null || file.path == null) return null;
    return PickedPdf(fileName: file.name, filePath: file.path!);
  }

  Future<String?> openPdf(String path) async {
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done ? null : result.message;
  }
}

class PickedPdf {
  const PickedPdf({required this.fileName, required this.filePath});
  final String fileName;
  final String filePath;
}
