import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'stroke',
      attributes: {
        'color': _colorToHex(color),
        'width': strokeWidth.toStringAsFixed(1),
      },
      nest: () {
        final pointsString = points.map((p) => '${p.dx.toStringAsFixed(2)} ${p.dy.toStringAsFixed(2)}').join(' ');
        builder.text(pointsString);
      }
    );
    return builder.buildDocument().rootElement;
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).substring(2).padLeft(6, '0');
  }
}