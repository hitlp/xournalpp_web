import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';

abstract class LocalFileDataSource {
  Future<Uint8List> exportToPdf(XournalDocument document);
}

class LocalFileDataSourceImp implements LocalFileDataSource {
  @override
  Future<Uint8List> exportToPdf(XournalDocument document) async {
    final pdf = pw.Document();

    for (final page in document.pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.CustomPaint(
                size: const PdfPoint(595.27559100, 841.88976400),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  for (final stroke in page.strokes) {
                    if (stroke.points.isEmpty) continue;

                    // Configura a cor e largura do traço
                    canvas
                      ..setStrokeColor(PdfColor.fromInt(stroke.color.value))
                      ..setLineWidth(stroke.strokeWidth)
                      ..setLineCap(PdfLineCap.round)
                      ..setLineJoin(PdfLineJoin.round);

                    // Desenha o caminho (path)
                    final firstPoint = stroke.points.first;
                    canvas.moveTo(firstPoint.dx, size.y - firstPoint.dy);

                    for (int i = 1; i < stroke.points.length; i++) {
                      final point = stroke.points[i];
                      canvas.lineTo(point.dx, size.y - point.dy);
                    }

                    canvas.strokePath();
                  }
                },
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
