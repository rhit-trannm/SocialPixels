import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

class UCanvas {
  final String id;
  final String name;
  final String ownerId;

  UCanvas({required this.id, required this.name, required this.ownerId});
}


String _generateCanvasId(String email) {
  final random = Random();
  final randomString = String.fromCharCodes(
    List.generate(8, (index) => random.nextInt(33) + 89),
  );

  // Using md5 to hash the email address
  final bytes = utf8.encode(email + randomString); 
  final digest = md5.convert(bytes);

  return digest.toString();
}

Future<void> createCanvas(String canvasName) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final canvasId = _generateCanvasId(user.email!);

  final newCanvas = UCanvas(
    id: canvasId,
    name: canvasName,
    ownerId: user.uid,
  );

  await _firestore.collection('canvases').doc(canvasId).set({
    'name': newCanvas.name,
    'ownerId': newCanvas.ownerId,
  });
}

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
  StreamSubscription? _canvasSubscription;
  @override
  void initState() {
    super.initState();
    _canvasSubscription = FirebaseFirestore.instance
        .collection('canvases')
        .doc('yourCanvasIdHere')
        .collection('lines')
        .snapshots()
        .listen((snapshot) {
      lines = snapshot.docs.map((doc) => Line(
        points: (doc.data()['points'] as List).map((p) => Offset(p['x'], p['y'])).toList(),
        color: Color(int.parse(doc.data()['color'])),
        strokeWidth: doc.data()['strokeWidth'].toDouble(),
      )).toList();
      setState(() {});
    });
  }
  @override
  void dispose() {
    _canvasSubscription?.cancel();
    super.dispose();
  }
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
            final newLine = Line(points: [localPosition]);
            lines.add(newLine);
            _addLineToFirestore(newLine);
          } else {
            currentLine.points.add(localPosition);
            _updateLineInFirestore(currentLine);
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
  final _firestore = FirebaseFirestore.instance;
  void _addLineToFirestore(Line line) {
  final canvasId = 'yourCanvasIdHere';  
  final lineData = {
    'points': line.points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
    'color': line.color.value.toString(),  // Saving color as integer value string.
    'strokeWidth': line.strokeWidth,
  };

  _firestore.collection('canvases').doc(canvasId).collection('lines').add(lineData);
  }
  void _updateLineInFirestore(Line line) {
  final canvasId = 'CanID';
  final lineId = 'LineID';  // unique ID for each line. 

  final lineData = {
    'points': line.points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
    'color': line.color.value.toString(),
    'strokeWidth': line.strokeWidth,
  };

  _firestore.collection('canvases').doc(canvasId).collection('lines').doc(lineId).update(lineData);
  }
}

