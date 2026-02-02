import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';

class SaveXoppFile {
  final FileRepository repository;
  SaveXoppFile(this.repository);

  Future<void> call(XournalDocument document, String filename) async {
    await repository.saveXoppFile(document, filename);
  }
}