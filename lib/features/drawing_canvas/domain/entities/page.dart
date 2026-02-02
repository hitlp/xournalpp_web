import 'package:xml/xml.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';

class Page {
  final String backgroundType;
  final String? pdfFile;
  final List<Stroke> strokes;

  Page({
    required this.backgroundType,
    this.pdfFile,
    required this.strokes,
  });

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'page',
      nest: () {
        builder.element(
          'background',
          attributes: {
            'type': backgroundType,
            if (pdfFile != null) 'filename': pdfFile!,
          },
        );
        builder.element(
          'layer',
          nest: () {
            for(final stroke in strokes) {
              builder.xml(stroke.toXmlElement().toXmlString());
            }
          },
        );
      },
    );
    return builder.buildDocument().rootElement;
  }
}