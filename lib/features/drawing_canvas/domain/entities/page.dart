import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';

class Page {
  final String backgroundType;
  final String? pdfFile;
  final List<Stroke> strokes;
  final double width;
  final double height;
  final Color backgroundColor;
  final String backgroundStyle;

  Page({
    required this.backgroundType,
    this.pdfFile,
    required this.strokes,
    this.width = 595.27559, // Padrão A4 em pontos (72 dpi)
    this.height = 841.88976, // Padrão A4 em pontos (72 dpi)
    this.backgroundColor = Colors.white,
    this.backgroundStyle = 'lined'
  });

  Page copyWith({
    String? backgroundType,
    String? pdfFile,
    List<Stroke>? strokes,
    double? width,
    double? height,
    Color? backgroundColor,
    String? backgroundStyle,
  }) {
    return Page(
      backgroundType: backgroundType ?? this.backgroundType, 
      pdfFile: pdfFile ?? this.pdfFile,
      strokes: strokes ?? this.strokes,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
    );
  }

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'page',
      attributes: {
        'width': width.toString(),
        'height': height.toString(),
      },
      nest: () {
        builder.element(
          'background',
          attributes: {
            'type': backgroundType,
            'color': _colorToHex(backgroundColor),
            'style': backgroundStyle,
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

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }
}