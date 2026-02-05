import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String tool;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.tool = "pen",
  });

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    String? tool,
  }) {
    return Stroke(
      points: points ?? this.points, 
      color: color ?? this.color, 
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
    );
  }

  XmlElement toXmlElement() {
    final builder = XmlBuilder();
    builder.element(
      'stroke',
      attributes: {
        'tool': tool,
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
    return '#${color.value.toRadixString(16).padLeft(8,'0')}';
  }
}