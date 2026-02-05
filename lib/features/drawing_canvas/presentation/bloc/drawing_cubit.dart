import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_state.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/export_pdf_file.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/open_xopp_file.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/save_xopp_file.dart';

class DrawingCubit extends Cubit<DrawingState> {

  final OpenXoppFile openXoppFile;
  final SaveXoppFile saveXoppFile;
  final ExportPdfFile exportPdfFile;

  DrawingCubit({
    required this.openXoppFile,
    required this.saveXoppFile,
    required this.exportPdfFile,
  }) : super(DrawingState(strokes: []));


  void startDrawing(Offset point) {
    if(state.currentTool == DrawingTool.pen) {
      emit(state.copyWith(
          currentStroke: Stroke(
            points: [point], color: state.currentColor, strokeWidth: state.currentWidth),
        )
      );
    } else if (state.currentTool == DrawingTool.eraser) {
        emit(state.copyWith(
          currentStroke: Stroke(points: [point], color: Colors.transparent, strokeWidth: state.eraserWidth, tool: 'eraser'),
        )
      );
    }
  }

  void updateDrawing(Offset point) {
    if (state.currentStroke == null) return;
    if (state.currentTool == DrawingTool.pen) {
      final newPoints = List<Offset>.from(state.currentStroke!.points)..add(point);
      emit(state.copyWith(currentStroke: state.currentStroke!.copyWith(points: newPoints)));
    } else if (state.currentTool == DrawingTool.eraser) {
      final newPoints = List<Offset>.from(state.currentStroke!.points)..add(point);
      emit(state.copyWith(currentStroke: state.currentStroke!.copyWith(points: newPoints)));
    }
  }

  void endDrawing(){
    if(state.currentStroke != null && state.currentStroke!.points.isNotEmpty) {
      if(state.currentTool == DrawingTool.pen) {
        emit(state.copyWith(
          strokes: List<Stroke>.from(state.strokes)..add(state.currentStroke!),
          currentStroke: null,
        ));
      } else if (state.currentTool == DrawingTool.eraser) {
        emit(state.copyWith(
          currentStroke: null,
        ));
      }
    }
  }

  void _eraseAtPoint(Offset point) {
    final newStrokes = <Stroke>[];
    for (final stroke in state.strokes) {
      bool intersects = false;
      for (final p in stroke.points) {
        if ((p - point).distance <= state.eraserWidth / 2) {
          intersects = true;
          break;
        }
      }
      if (!intersects) {
        newStrokes.add(stroke);
      }
    }
    emit(state.copyWith(strokes: newStrokes));
  }


  void changeColor(Color color) {
    emit(state.copyWith(currentColor: color));
  }

  void changeWidth(double width) {
    emit(state.copyWith(currentWidth: width));
  }

  void changeTool(DrawingTool tool) {
    emit(state.copyWith(currentTool: tool));
  }

  void changeEraserWidth(double width) {
    emit(state.copyWith(eraserWidth: width));
  }

  Future<void> openFile() async {
    try {
      final document = await openXoppFile();
      if (document != null && document.pages.isNotEmpty) {
        emit(state.copyWith(
          currentDocument: document,
          currentPageIndex: 0,
          strokes: document.pages.first.strokes,
          currentStroke: null,
        ));
        print('Documento ${document.creator} carregado com sucesso com ${document.pages.length} páginas!');
      } else if (document != null && document.pages.isEmpty) {
        emit(state.copyWith(
          currentDocument: document,
          currentPageIndex: 0,
          strokes: [],
          currentStroke: null,
        ));
        print('Documento ${document.creator} carregado, mas sem páginas ou traços.');
      } else {
        print('Nenhum arquivo selecionado ou erro no parsing.');
      }
    } catch (e) {
      print('Erro ao abrir ou processar o arquivo: $e');
    }
  }


  Future<void> saveFile() async {
    try {
      final documentToSave = state.currentDocument?.copyWith(
        pages: state.currentDocument!.pages.map((page) {
          if (state.currentDocument!.pages.indexOf(page) == state.currentPageIndex) {
            return page.copyWith(strokes: state.strokes);
          }
          return page;
        }).toList(),
      ) ?? XournalDocument(
        creator: 'xournalpp 1.2.10',
        fileVersion: 4,
        title: 'Meu Documento Xournal++ Web',
        previewBase64: '',
        version: '',
        pages: [
          Page(
            backgroundType: 'solid',
            backgroundColor: Colors.white,
            backgroundStyle: 'lined',
            strokes: state.strokes,
          ),
        ],
      );
 
      const filename = 'meu_documento.xopp';
      await saveXoppFile(documentToSave, filename);
      print('Documento salvo com sucesso: $filename');
    } catch (e) {
      print('Erro ao salvar o arquivo: $e');
    }
  }

  Future<void> exportPdf() async {
    try {
      if (state.currentDocument == null) {
        print('Nenhum documento carregado para exportar para PDF.');
        return;
      }
      final documentToExport = state.currentDocument!.copyWith(
        pages: state.currentDocument!.pages.map((page) {
          if (state.currentDocument!.pages.indexOf(page) == state.currentPageIndex) {
            return page.copyWith(strokes: state.strokes);
          }
          return page;
        }).toList(),
      );
 
      const filename = 'meu_documento.pdf';
      await exportPdfFile(documentToExport, filename);
      print('Documento exportado para PDF com sucesso: $filename');
    } catch (e) {
      print('Erro ao exportar para PDF: $e');
    }
  }

  void goToPage(int pageIndex) {
    if (state.currentDocument == null || pageIndex < 0 || pageIndex >= state.currentDocument!.pages.length) {
      return;
    }
    emit(state.copyWith(
      currentPageIndex: pageIndex,
      strokes: state.currentDocument!.pages[pageIndex].strokes,
      currentStroke: null,
    ));
  }

  void nextPage() {
    if (state.currentDocument == null || state.currentPageIndex >= state.currentDocument!.pages.length - 1) {
      return;
    }
    goToPage(state.currentPageIndex + 1);
  }
  
  void previousPage() {
    if (state.currentDocument == null || state.currentPageIndex <= 0) {
      return;
    }
      goToPage(state.currentPageIndex - 1);
  }
}