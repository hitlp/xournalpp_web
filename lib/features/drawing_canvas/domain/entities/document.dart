import 'package:xml/xml.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart';

class XournalDocument {
  final List<Page> pages;
  final String version;

  XournalDocument({
    required this.pages,
    required this.version,
  });

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'xournal', 
      attributes: {
        'creator': 'xournalpp 1.2.10',
        'fileversion': version
      },
      nest: () {
        for(final page in pages) {
          builder.xml(page.toXmlElement().toXmlString());
        }
      },
    );
    return builder.buildDocument().rootElement;
  }
}