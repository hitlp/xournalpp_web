import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart' as domain;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository{
  @override
  Future<XournalDocument> parseXoppFile(List<int> bytes) async {
    final gZipDecoder = GZipDecoder();
    final decompressedBytes = gZipDecoder.decodeBytes(Uint8List.fromList(bytes));
    final xmlString = utf8.decode(decompressedBytes);
    final document = XmlDocument.parse(xmlString);
     
    final logLengh = xmlString.length > 500 ? 500 : xmlString.length;
    print('--- Conteúdo XML Descomprimido ---');
    print(xmlString.substring(0, logLengh) + (xmlString.length > 500 ? '...' : ''));
    print('----------------------------------');

    final xournalElements = document.findAllElements('xournal');
    if(xournalElements.isEmpty) {
      throw Exception('Arquivo inválido: Tag <xournal> não encontrada.');
    }

    final rootElement = xournalElements.first;

    final version = rootElement.getAttribute('creator') ??
                    rootElement.getAttribute('fileversion') ??
                    'unknown';

    final List<domain.Page> pages = [];

        // Buscamos as páginas dentro do elemento raiz
    for (final pageElement in rootElement.findElements('page')) {
      final backgroundElement = pageElement.findElements('background').firstOrNull;
      final backgroundType = backgroundElement?.getAttribute('type') ?? 'solid';
      final pdfFile = backgroundElement?.getAttribute('filename');

      final List<Stroke> strokes = [];

      // Percorremos as camadas (layers)
      for (final layerElement in pageElement.findElements('layer')) {
        // Percorremos os traços (strokes)
        for (final strokeElement in layerElement.findElements('stroke')) {
          final colorHex = strokeElement.getAttribute('color') ?? '000000';
          final color = _parseColor(colorHex);
          final width = double.tryParse(strokeElement.getAttribute('width') ?? '1.0') ?? 1.0;
          
          final pointsString = strokeElement.text.trim();
          if (pointsString.isEmpty) continue;

          // O Xournal++ separa os pontos por espaços
          final pointsList = pointsString
              .split(RegExp(r'\s+'))
              .map(double.tryParse)
              .whereType<double>()
              .toList();

          final List<Offset> points = [];
          for (int i = 0; i < pointsList.length; i += 2) {
            if (i + 1 < pointsList.length) {
              points.add(Offset(pointsList[i], pointsList[i + 1]));
            }
          }

          if (points.isNotEmpty) {
            strokes.add(Stroke(
              points: points, 
              color: color, 
              strokeWidth: width
            ));
          }
        }
      }

      pages.add(domain.Page(
        backgroundType: backgroundType,
        pdfFile: pdfFile,
        strokes: strokes,
      ));
    }

    print('Parser concluído: ${pages.length} páginas encontradas');

    return XournalDocument(
      pages: pages, 
      version: version
    );
  }
  
  @override
  Future<void> saveXoppFile(XournalDocument document, String path) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" standalone="no"');
    
    builder.element('xournal', attributes: {
      'creator': document.version,
      'fileversion': '4',
    }, nest: () {
      builder.element('title', nest: 'Xournal++ document - see https://xournalpp.github.io/');
      
      for (final page in document.pages) {
        builder.element('page', attributes: {
          'width': '595.27559100', // Valores padrão A4, ajuste se necessário
          'height': '841.88976400',
        }, nest: () {
          builder.element('background', attributes: {
            'type': page.backgroundType,
            if (page.pdfFile != null) 'filename': page.pdfFile!,
          });
          
          builder.element('layer', nest: () {
            for (final stroke in page.strokes) {
              builder.element('stroke', attributes: {
                'color': _colorToHex(stroke.color),
                'width': stroke.strokeWidth.toString(),
                'tool': 'pen',
              }, nest: () {
                final pointsString = stroke.points
                    .map((p) => '${p.dx} ${p.dy}')
                    .join(' ');
                builder.text(pointsString);
              });
            }
          });
        });
      }
    });

    final xmlDocument = builder.buildDocument();
    final xmlString = xmlDocument.toXmlString(pretty: true);
    
    // Comprime o XML usando GZip para o formato .xopp
    final bytes = utf8.encode(xmlString);
    final gzipEncoder = GZipEncoder();
    final compressedBytes = gzipEncoder.encode(bytes);

    if(compressedBytes == null) {
      throw Exception('Erro ao comprimir o arquivo .xopp');
    }

    final file = File(path);
    await file.writeAsBytes(compressedBytes);    
  }

  Color _parseColor(String hex) {
    
    String cleanHex = hex.replaceFirst('#', '').toLowerCase();

    try {
      if(cleanHex.length == 6) {
        return Color(int.parse('ff$cleanHex',radix: 16));
      }

      if(cleanHex.length == 8) {
        String alpha = cleanHex.substring(6,8);
        String rgb = cleanHex.substring(0,6);
        return Color(int.parse('$alpha$rgb',radix: 16));
      }

      if(cleanHex.length == 3) {
        String r = cleanHex[0];
        String g = cleanHex[1];
        String b = cleanHex[2];
        return Color(int.parse('ff$r$r$g$g$b$b', radix: 16));
      }

      switch(cleanHex) {
        case 'black': return Colors.black;
        case 'blue': return Colors.blue;
        case 'red': return Colors.red;
        case 'green': return Colors.green;
        case 'white': return Colors.white;
        default:
          // Tenta parsear o que vier, se falhar retorna preto
          return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (e) {
      return Colors.black;
    }
  }

  String _colorToHex(Color color) {
    // Converte de volta para o formato RRGGBBAA esperado pelo Xournal++
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    final a = color.alpha.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b$a';
  }
}