import 'package:file_picker/file_picker.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';

class OpenXoppFile {
  final FileRepository repository;

  OpenXoppFile(this.repository);

  Future<XournalDocument?> call() async {
    FilePickerResult? result= await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xopp'],
      withData: true,
    );

    if(result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if(bytes == null) return null;
      return repository.parseXoppFile(bytes);
    }
    return null;
  }
}