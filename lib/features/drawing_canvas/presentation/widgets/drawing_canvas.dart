import 'package:flutter/material.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/drawing_tool.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';

class DrawingCanvas extends StatelessWidget {

  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final DrawingTool currentTool;
  final double eraserWidth;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.currentStroke,
    this.currentTool = DrawingTool.pen,
    this.eraserWidth = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DrawingPainter(
        strokes: strokes, 
        currentStroke: currentStroke,
        currentTool: currentTool,
        eraserWidth: eraserWidth,
      ),
      child: Container(),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final DrawingTool currentTool;
  final double eraserWidth;

  DrawingPainter({
    required this.strokes, 
    this.currentStroke,
    required this.currentTool,
    required this.eraserWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStrokes(canvas, strokes);

    if(currentStroke != null) {
      _drawStrokes(canvas, [currentStroke!]);
    }
  }

  void _drawStrokes(Canvas canvas, List<Stroke> strokesToDraw) {
    for (final stroke in strokesToDraw) {
      final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

      for(int i = 0; i < stroke.points.length -1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i=1], paint);
      }
    }

    if(currentStroke != null && currentTool == DrawingTool.pen) {
      final paint = Paint()
        ..color = currentStroke!.color
        ..strokeWidth = currentStroke!.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      for (int i = 0; i < currentStroke!.points.length - 1; i++) {
        canvas.drawLine(currentStroke!.points[i], currentStroke!.points[i + 1], paint);
      }
    }

    if (currentTool == DrawingTool.eraser && currentStroke != null && currentStroke!.points.isNotEmpty) {
      final lastPoint = currentStroke!.points.last;
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
 
      canvas.drawCircle(lastPoint, eraserWidth / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || 
      oldDelegate.currentStroke != currentStroke ||
      oldDelegate.currentTool != currentTool ||
      oldDelegate.eraserWidth != eraserWidth;
  }
}