import 'package:flutter/material.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';

class DrawingState {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final Color currentColor;
  final double currentWidth;
  final DrawingTool currentTool;
  final double eraserWidth;

  DrawingState({
    required this.strokes,
    this.currentStroke,
    this.currentColor = Colors.black,
    this.currentWidth = 5.0,
    this.currentTool = DrawingTool.pen, //Default: pen
    this.eraserWidth = 20.0, //default eraser width
  });

  DrawingState copyWith({
    List <Stroke>? strokes,
    Stroke? currentStroke,
    Color? currentColor,
    double? currentWidth,
    DrawingTool? currentTool,
    double? eraserWidth,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke,
      currentColor: currentColor ?? this.currentColor,
      currentWidth: currentWidth ?? this.currentWidth,
      currentTool: currentTool ?? this.currentTool,
      eraserWidth: eraserWidth ?? this.eraserWidth,
    );
  }
}