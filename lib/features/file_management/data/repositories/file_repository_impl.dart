import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart' as domain;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';
import 'dart:html' as html;

class FileRepositoryImpl implements FileRepository{

  @override
  Future<void> saveXoppFile(XournalDocument document, String filename) async {
    final XmlElement = document.toXmlElement();
    final xmlString = XmlElement.toXmlString(pretty: true);

    final xmlBytes = utf8.encode(xmlString);
    final encoder = GZipEncoder();
    final compressedBytes = encoder.encode(xmlBytes);
    if (compressedBytes == null) {
      throw Exception('Falha ao compactar XOPP');
    }

    final blob = html.Blob(
      [Uint8List.fromList(compressedBytes)], 
      'application/x-xournalpp'
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
  
  @override
  Future<XournalDocument> parseXoppFile(List<int> bytes) async {
    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(Uint8List.fromList(bytes));
    final xmlString = utf8.decode(decompressedBytes);
    final document = XmlDocument.parse(xmlString);

    final logLength = xmlString.length > 500 ? 500 : xmlString.length;
    print('--- Conteúdo XML Descomprimido ---');
    print(xmlString.substring(0, logLength) + (xmlString.length > 500 ? '...' : ''));
    print('----------------------------------');

    final rootElement = document.findElements('xournal').first;
    final version = rootElement.getAttribute('version') ?? 'unknow';

    final List<domain.Page> pages = [];

    for (final pageElement in rootElement.findElements('page')) {
      final backgroundElement = pageElement.findElements('background').firstOrNull;
      final backgroundType = backgroundElement?.getAttribute('type') ?? 'solid';
      final pdfFile = backgroundElement?.getAttribute('filename');

      final List<Stroke> strokes = [];

      for (final layerElement in pageElement.findElements('layer')) {
        for(final strokeElement in layerElement.findElements('stroke')) {
          final color = _parseColor(strokeElement.getAttribute('color') ?? '000000');
          final width = double.tryParse(strokeElement.getAttribute('width') ?? '1.0') ?? 1.0;
          final pointsString = strokeElement.text.trim();
          final pointsList = pointsString.split(RegExp(r'\s+')).map(double.tryParse).whereType<double>().toList();

          final List<Offset> points = [];
          for (int i=0; i<pointsList.length; i +=2) {
            if (i+1 < pointsList.length) {
              points.add(Offset(pointsList[i], pointsList[i+1]));
            }
          }

          strokes.add(Stroke(points: points, color: color, strokeWidth: width));
        }
      }

      pages.add(domain.Page(
        backgroundType: backgroundType,
        pdfFile: pdfFile,
        strokes: strokes,
      ));
    }

    return XournalDocument(
      pages: pages, 
      version: version
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if(hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}