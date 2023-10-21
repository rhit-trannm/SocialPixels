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
  String id;
  String name;
  String ownerId;

  UCanvas({required this.id, required this.name, required this.ownerId});
}

class Line {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Line(
      {required this.points,
      this.color = Colors.black,
      this.strokeWidth = 5.0});
}

String _generateCanvasId(String email) {
  final random = Random();
  final randomString = String.fromCharCodes(
    List.generate(8, (index) => random.nextInt(33) + 89),
  );

  // hash email address
  final bytes = utf8.encode(email + randomString);
  final digest = md5.convert(bytes);

  return digest.toString();
}

Future<List<UCanvas>> fetchCanvases() async {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final canvasQuerySnapshot = await _firestore
      .collection('canvases')
      .where('ownerId', isEqualTo: user.uid)
      .get();

  return canvasQuerySnapshot.docs.map((doc) {
    final canvas = UCanvas(
      id: doc.id,
      name: doc.data()['name'],
      ownerId: doc.data()['ownerId'],
    );

    print('Canvas Name: ${canvas.name}');

    return canvas;
  }).toList();
}

Future<String> createCanvas(String canvasName) async {
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
  return canvasId;
}

class DrawingCanvas extends StatefulWidget {
  final String canvasID;
  DrawingCanvas({Key? key, required this.canvasID}) : super(key: key);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Line> lines = [];
  late UCanvas currentCanvas;
  late StreamSubscription<QuerySnapshot> _canvasSubscription;
  final int threshold = 6;
  int totalPoints = 1;
  @override
  void initState() {
    super.initState();
    currentCanvas = UCanvas(id: widget.canvasID, name: '', ownerId: '');
    _canvasSubscription = FirebaseFirestore.instance
        .collection('canvases')
        .doc(currentCanvas.id)
        .collection('lines')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      lines = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Line(
          points: List.from(data['points'])
              .map((point) => Offset(point['x'], point['y']))
              .toList(),
          color: Color(int.parse(data['color'])),
          strokeWidth: data['strokeWidth'].toDouble(),
        );
      }).toList();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _canvasSubscription.cancel();
    super.dispose();
  }

  void _addLineToFirestore(Line line, String canvasID) async {
    final canvasId = canvasID;
    final lineData = {
      'points':
          line.points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
      'color': line.color.value.toString(),
      'strokeWidth': line.strokeWidth,
      'timestamp': FieldValue.serverTimestamp(), //timestamp
    };
    try {
      await _firestore
          .collection('canvases')
          .doc(canvasId)
          .collection('lines')
          .add(lineData);
    } catch (e) {
      print('Error adding line to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) {
        // When the user starts drawing, add a new empty line
        lines.add(Line(points: []));
      },
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        if (totalPoints % threshold == 0) {
          lines.last.points.add(localPosition);
          totalPoints = 1;
        } else {
          totalPoints++;
        }
        // Only add the point to the last line, since it's initialized in onPanDown
        // lines.last.points.add(localPosition);
        setState(() {});
      },
      onPanEnd: (details) {
        _addLineToFirestore(lines.last, currentCanvas.id);
      },
      child: CustomPaint(
        painter: DrawingPainter(lines: lines),
        child: Container(),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Line> lines;

  DrawingPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      print(line.points.length);
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
