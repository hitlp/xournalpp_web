import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; 
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart' as domain;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';
import 'package:xournalpp_web/features/file_management/data/datasources/local_file_data_source.dart';

class FileRepositoryImpl implements FileRepository {
  final LocalFileDataSource localDataSource;

  FileRepositoryImpl({required this.localDataSource});

  @override
  Future<XournalDocument> parseXoppFile(List<int> bytes) async {
    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(Uint8List.fromList(bytes));
    final xmlString = utf8.decode(decompressedBytes);
    final document = XmlDocument.parse(xmlString);

    final xournalElements = document.findAllElements('xournal');
    if (xournalElements.isEmpty) throw Exception('Tag <xournal> não encontrada.');
    
    final rootElement = xournalElements.first;
    final version = rootElement.getAttribute('creator') ?? 'unknown';

    final List<domain.Page> pages = [];
    for (final pageElement in rootElement.findElements('page')) {
      final backgroundElement = pageElement.findElements('background').firstOrNull;
      final backgroundType = backgroundElement?.getAttribute('type') ?? 'solid';
      
      final List<Stroke> strokes = [];
      for (final layerElement in pageElement.findElements('layer')) {
        for (final strokeElement in layerElement.findElements('stroke')) {
          final color = _parseColor(strokeElement.getAttribute('color') ?? '000000');
          final width = double.tryParse(strokeElement.getAttribute('width') ?? '1.0') ?? 1.0;
          final pointsList = strokeElement.text.trim().split(RegExp(r'\s+')).map(double.tryParse).whereType<double>().toList();

          final List<Offset> points = [];
          for (int i = 0; i < pointsList.length; i += 2) {
            if (i + 1 < pointsList.length) points.add(Offset(pointsList[i], pointsList[i + 1]));
          }
          if (points.isNotEmpty) strokes.add(Stroke(points: points, color: color, strokeWidth: width));
        }
      }
      pages.add(domain.Page(backgroundType: backgroundType, strokes: strokes));
    }
    return XournalDocument(pages: pages, version: version);
  }

  @override
  Future<XournalDocument> openXoppFile(List<int> bytes) => parseXoppFile(bytes);

  @override
  Future<void> saveXoppFile(XournalDocument document, String path) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" standalone="no"');
    builder.element('xournal', attributes: {'creator': document.version, 'fileversion': '4'}, nest: () {
      for (final page in document.pages) {
        builder.element('page', attributes: {'width': '595.27', 'height': '841.89'}, nest: () {
          builder.element('background', attributes: {'type': page.backgroundType});
          builder.element('layer', nest: () {
            for (final stroke in page.strokes) {
              builder.element('stroke', attributes: {'color': _colorToHex(stroke.color), 'width': stroke.strokeWidth.toString()}, nest: () {
                builder.text(stroke.points.map((p) => '${p.dx} ${p.dy}').join(' '));
              });
            }
          });
        });
      }
    });

    final bytes = utf8.encode(builder.buildDocument().toXmlString());
    final compressed = GZipEncoder().encode(bytes);
    if (compressed == null) throw Exception('Erro na compressão');

    final blob = html.Blob([compressed]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute("download", path)..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Future<Uint8List> exportPdfFile(XournalDocument document) async {
    return await localDataSource.exportToPdf(document);
  }

  Color _parseColor(String hex) {
    String cleanHex = hex.replaceFirst('#', '').toLowerCase();
    if (cleanHex.length == 6) return Color(int.parse('ff$cleanHex', radix: 16));
    if (cleanHex.length == 8) return Color(int.parse('${cleanHex.substring(6, 8)}${cleanHex.substring(0, 6)}', radix: 16));
    return Colors.black;
  }

  String _colorToHex(Color color) => '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}${color.alpha.toRadixString(16).padLeft(2, '0')}';
}
