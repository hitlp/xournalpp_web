import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';

abstract class FileRepository {
  Future<XournalDocument> parseXoppFile(List<int> bytes);
  Future<void> saveXoppFile(XournalDocument document, String filename);
}