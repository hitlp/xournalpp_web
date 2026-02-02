import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/document.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';
import 'package:xournalpp_web/features/drawing_canvas/presentation/bloc/drawing_state.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/open_xopp_file.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/page.dart';
import 'package:xournalpp_web/features/file_management/domain/usecases/save_xopp_file.dart';
import 'package:xournalpp_web/features/file_management/data/repositories/file_repository_impl.dart';

class DrawingCubit extends Cubit<DrawingState> {

  final OpenXoppFile openXoppFile;
  final SaveXoppFile saveXoppFile;

  DrawingCubit() 
    : openXoppFile = OpenXoppFile(FileRepositoryImpl()),
      saveXoppFile = SaveXoppFile(FileRepositoryImpl()),
      super(DrawingState(strokes: []));

  void startDrawing(Offset point) {
    if(state.currentTool == DrawingTool.pen) {
      final newStroke = Stroke(
        points: [point],
        color: state.currentColor,
        strokeWidth: state.currentWidth,
      );
      emit(state.copyWith(currentStroke: newStroke));
    } else if (state.currentTool == DrawingTool.eraser) {
      _eraseAtPoint(point);
    }
  }

  void updateDrawing(Offset point) {
    if (state.currentTool == DrawingTool.pen) {
      if (state.currentStroke == null) return;
      final updatePoints = List<Offset>.from(state.currentStroke!.points)..add(point);
      final updateStroke = Stroke(
        points: updatePoints,
        color: state.currentStroke!.color,
        strokeWidth: state.currentStroke!.strokeWidth,
      );
      emit(state.copyWith(currentStroke: updateStroke));
    } else if (state.currentTool == DrawingTool.eraser) {
      _eraseAtPoint(point);
    }
  }

  void endDrawing(){
    if (state.currentTool == DrawingTool.pen) {
      if(state.currentStroke == null) return;
      final finalStroke = List<Stroke>.from(state.strokes)..add(state.currentStroke!);
      emit(state.copyWith(strokes: finalStroke, currentStroke: null));
    }
  }

  void _eraseAtPoint(Offset point) {
    final newStrokes = <Stroke>[];
    final eraserRect = Rect.fromCircle(
      center: point, 
      radius: state.eraserWidth /2
    );

    for (final stroke in state.strokes) {
      bool intercects = false;
      for (final p in stroke.points) {
        if (eraserRect.contains(p)) {
          intercects = true;
        }
      }
      if(!intercects) {
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
      final document = await openXoppFile.call();

      if(document != null && document.pages.isNotEmpty) {
        emit(state.copyWith(strokes: document.pages.first.strokes, currentStroke: null));
        print('Documento ${document.version} carregado com sucesso com ${document.pages.first.strokes.length} traços!');
      } else if (document != null && document.pages.isEmpty) {
        emit(state.copyWith(strokes: [], currentStroke: null));
        print('Documento ${document.version} carregado, mas sem páginas ou traços.');
      } else {
        print('Nenhum arquivo selecionado ou erro no parsing.');
      }
    } catch (e) {
      print('Erro ao abrir ou processar o arquivo: $e');
    }
  }

  Future<void> saveFile() async {
    try {
      final documentToSave = XournalDocument(
        version: '4',
        pages: [
          Page(
            backgroundType: 'solid',
            strokes: state.strokes,
          ),
        ], 
      );

      const filename = 'new_doc.xopp';
      await saveXoppFile.call(documentToSave, filename);
      print('Documento salvo com sucesso: $filename');
    } catch (e) {
      print('Erro ao salvar o arquivo: $e');
    }
  }
}