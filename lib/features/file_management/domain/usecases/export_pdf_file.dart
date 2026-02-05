import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';

class ExportPdfFile {

  final FileRepository repository;
  ExportPdfFile(this.repository);

  Future<void> call(XournalDocument document, String filename) async {
    return await repository.exportPdfFile(document, filename);  
  }
}