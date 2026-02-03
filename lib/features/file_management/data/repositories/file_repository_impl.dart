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
    final creator = rootElement.getAttribute('creator') ?? 'unknow';
    final fileVersion = int.tryParse(rootElement.getAttribute('fileversion') ?? '0') ?? 0;
    final title = rootElement.findElements('title').firstOrNull?.innerText ?? '';
    final preview = rootElement.findElements('preview').firstOrNull?.innerText ?? '';
    //final version = rootElement.getAttribute('version') ?? 'unknow';

    final List<domain.Page> pages = [];

    for (final pageElement in rootElement.findElements('page')) {
      final pageWidth = double.tryParse(pageElement.getAttribute('width') ?? '0.0') ?? 0.0;
      final pageHeight = double.tryParse(pageElement.getAttribute('height') ?? '0.0') ?? 0.0;
      final backgroundElement = pageElement.findElements('background').firstOrNull;
      final backgroudColor = _parseColor(backgroundElement?.getAttribute('color') ?? '#FFFFFFFF');
      final backgroundStyle = backgroundElement?.getAttribute('style') ?? 'lined';
      final backgroundType = backgroundElement?.getAttribute('type') ?? 'solid';
      final pdfFile = backgroundElement?.getAttribute('filename');

      final List<Stroke> strokes = [];

      for (final layerElement in pageElement.findElements('layer')) {
        for(final strokeElement in layerElement.findElements('stroke')) {
          final color = _parseColor(strokeElement.getAttribute('color') ?? '#000000FF');
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
        width: pageWidth,
        height: pageHeight,
        backgroundColor: backgroudColor,
        backgroundStyle: backgroundStyle,
      ));
    }

    return XournalDocument(
      pages: pages, 
      version: creator,
      creator: creator,
      fileVersion: fileVersion,
      title: title,
      previewBase64: preview,
    );
  }

  Color _parseColor(String hex) {
    String cleanHex = hex.startsWith('#') ? hex.substring(1) : hex;
    if(cleanHex.length == 6) {
      cleanHex = 'FF' + cleanHex;
    } else if (cleanHex.length != 8) {
      return Colors.black;
    }
    return Color(int.parse(cleanHex, radix: 16));
  }
}