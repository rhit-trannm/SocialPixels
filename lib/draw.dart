import 'package:flutter/material.dart';
class Line {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Line({required this.points, this.color = Colors.black, this.strokeWidth = 5.0});
}

class DrawingPainter extends CustomPainter {
  final List<Line> lines;

  DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      if (line.points.isEmpty) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.strokeWidth
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < line.points.length - 1; i++) {
        if (line.points[i] != null && line.points[i + 1] != null)
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DrawingCanvas extends StatefulWidget {
  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Line> lines = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final currentLine = (lines.isNotEmpty && lines.last.points.isNotEmpty)
              ? lines.last
              : null;

          if (currentLine == null) {
            lines.add(Line(points: [localPosition]));
          } else {
            currentLine.points.add(localPosition);
          }
        });
      },
      onPanEnd: (details) {
        lines.add(Line(points: []));
      },
      child: CustomPaint(
        painter: DrawingPainter(lines: lines),
        child: Container(),
      ),
    );
  }
}
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Draw on Canvas')),
        body: DrawingCanvas(),
      ),
    );
  }
}
