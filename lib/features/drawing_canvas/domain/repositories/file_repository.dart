import 'dart:typed_data';

import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';

abstract class FileRepository {
  
  /// Abre e faz o parse de um arquivo .xopp
  Future<XournalDocument> parseXoppFile(List<int> bytes);

  /// Salva o documento no formato .xopp (Download na Web)
  Future<void> saveXoppFile(XournalDocument document, String path);

  /// Exporta o documento para PDF
  Future<Uint8List> exportPdfFile(XournalDocument document);

  /// Método genérico para abrir arquivo (se exigido pelo open_xopp_file.dart)
  Future<XournalDocument> openXoppFile(List<int> bytes);
}