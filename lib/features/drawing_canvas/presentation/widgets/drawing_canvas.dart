import 'package:flutter/material.dart';
import 'package:xournalpp_web/features/drawing_canvas/domain/entities/stroke.dart';

class DrawingCanvas extends StatelessWidget {

  final List<Stroke> strokes;
  final Stroke? currentStroke;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    this.currentStroke,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DrawingPainter(strokes: strokes, currentStroke: currentStroke),
      child: Container(),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingPainter({required this.strokes, this.currentStroke});

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

      final path = Path();
      if(stroke.points.isNotEmpty) {
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

        for(int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke;
  }
}