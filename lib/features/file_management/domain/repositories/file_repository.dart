import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';

abstract class FileRepository {
  Future<XournalDocument> openXoppFile(List<int> bytes);
  Future<void> saveXoppFile(XournalDocument document, String filename);
  Future<void> exportPdfFile(XournalDocument document, String filename);
}