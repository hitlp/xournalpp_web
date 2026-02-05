import 'package:file_picker/file_picker.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';

class OpenXoppFile {
  final FileRepository repository;

  OpenXoppFile(this.repository);

  Future<XournalDocument?> call() async {
    return await repository.openXoppFile();
  }
}