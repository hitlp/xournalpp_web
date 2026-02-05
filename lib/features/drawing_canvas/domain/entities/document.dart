import 'package:xml/xml.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart';

class XournalDocument {
  final List<Page> pages;
  final String version;
  final String creator;
  final int fileVersion;
  final String title;
  final String previewBase64;

  XournalDocument({
    required this.pages,
    required this.version,
    this.creator = 'xournalapp 1.2.10',
    this.fileVersion = 4,
    this.title = 'Xournal++ document - see https://xournalpp.github.io/',
    this.previewBase64 = '',
  });

  XournalDocument copyWith({
    List<Page>? pages,
    String? creator,
    int? fileVersion,
    String? title,
    String? previewBase64,
  }) {
    return XournalDocument(
      pages: pages ?? this.pages, 
      creator: creator ?? this.creator,
      fileVersion: fileVersion ?? this.fileVersion,
      title: title ?? this.title,
      previewBase64: previewBase64 ?? this.previewBase64, 
      version: '',
    );
  }

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'xournal', 
      attributes: {
        'creator': creator,
        'fileversion': fileVersion.toString(),
      },
      nest: () {
        builder.element('title', nest: title);
        builder.element('preview', nest: previewBase64);
        for(final page in pages) {
          builder.xml(page.toXmlElement().toXmlString());
        }
      },
    );
    return builder.buildDocument().rootElement;
  }
}