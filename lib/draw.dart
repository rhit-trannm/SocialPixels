import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final _firestore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

class UCanvas {
  String id;
  String name;
  String ownerId;

  UCanvas({required this.id, required this.name, required this.ownerId});
}

class Line {
  List<Offset> points;
  Color color;
  double strokeWidth;
  String? firestoreDocId; // Add this line

  Line({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 5.0,
    this.firestoreDocId, // Initialize this field
  });
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
      .collection('users')
      .doc(user.uid)
      .collection('canvases')
      .get();

  return canvasQuerySnapshot.docs.map((doc) {
    final canvas = UCanvas(
      id: doc.id,
      name: doc.data()['name'],
      ownerId: doc.data()['ownerId'],
    );

    return canvas;
  }).toList();
}

Future<void> deleteCanvas(String canvasId) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Delete the canvas from Firestore
  await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('canvases')
      .doc(canvasId)
      .delete();
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

  await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('canvases')
      .doc(canvasId)
      .set({
    'name': newCanvas.name,
    'ownerId': newCanvas.ownerId,
  });
  return canvasId;
}

class DrawingCanvas extends StatefulWidget {
  final String canvasID;
  final String uid;
  DrawingCanvas({Key? key, required this.canvasID, required this.uid})
      : super(key: key);

  @override
  _DrawingCanvasState createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Line> lines = [];
  late UCanvas currentCanvas;
  bool isEraserActive = false;
  late StreamSubscription<QuerySnapshot> _canvasSubscription;
  final int threshold = 10;
  int totalPoints = 1;
  Color currentColor = Colors.black;
  @override
  void initState() {
    super.initState();
    print("Opening canvas belong to" +
        widget.uid +
        "current uid: " +
        FirebaseAuth.instance.currentUser!.uid);
    currentCanvas = UCanvas(id: widget.canvasID, name: '', ownerId: widget.uid);
    _canvasSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('canvases')
        .doc(widget.canvasID)
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
          firestoreDocId: data['firestoreDocId'].toString(),
        );
      }).toList();
      setState(() {});
    });
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: HueRingPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                setState(() {
                  currentColor = color;
                });
              },
              enableAlpha: false,
              displayThumbColor: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      'timestamp': FieldValue.serverTimestamp(),
      //timestamp
    };
    try {
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('canvases')
          .doc(canvasId)
          .collection('lines')
          .add(lineData);
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('canvases')
          .doc(canvasId)
          .collection('lines')
          .doc(docRef.id)
          .update({'firestoreDocId': docRef.id});
      line.firestoreDocId = docRef.id; // Store the document ID
    } catch (e) {
      print('Error adding line to Firestore: $e');
    }
  }

  void _eraseLinesAtPosition(Offset position) {
    const eraseRadius = 10.0; // Adjust as needed for the eraser size

    setState(() {
      List<Line> linesToRemove = [];
      lines.removeWhere((line) {
        for (final point in line.points) {
          if ((point - position).distance <= eraseRadius) {
            linesToRemove.add(line);
            return true;
          }
        }
        return false;
      });
      print("GET HERE");
      // Delete lines from Firestore
      for (var line in linesToRemove) {
        print("GET HERE2: " + linesToRemove.length.toString());
        print("GET HERE3: " + line.firestoreDocId.toString()!);
        if (line.firestoreDocId != null) {
          print("Line: " + line.firestoreDocId!);
          _firestore
              .collection('users')
              .doc(widget.uid)
              .collection('canvases')
              .doc(currentCanvas.id)
              .collection('lines')
              .doc(line.firestoreDocId)
              .delete();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GestureDetector(
        onPanDown: (details) {
          // When the user starts drawing, add a new empty line with the current color
          if (!isEraserActive) {
            lines.add(Line(points: [], color: currentColor));
          }
        },
        onPanUpdate: (details) {
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);

          if (isEraserActive) {
            _eraseLinesAtPosition(localPosition);
          } else {
            if (totalPoints % threshold == 0) {
              lines.last.points.add(localPosition);
              totalPoints = 1;
            } else {
              totalPoints++;
            }
            setState(() {});
          }
        },
        onPanEnd: (details) {
          if (!isEraserActive) {
            _addLineToFirestore(lines.last, currentCanvas.id);
          }
        },
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: CustomPaint(
            painter: DrawingPainter(lines: lines),
            child: Container(),
          ),
        ),
      ),
      Positioned(
        right: 10,
        bottom: 10,
        child: FloatingActionButton(
          backgroundColor: currentColor,
          onPressed: _openColorPicker,
          child: Icon(Icons.color_lens, color: Colors.white),
        ),
      ),
      Positioned(
        right: 10,
        bottom:
            80, // This positions the erase button below the color picker button
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              isEraserActive = !isEraserActive;
            });
          },
          child: Icon(isEraserActive ? Icons.delete : Icons.brush),
          backgroundColor: isEraserActive ? Colors.grey : Colors.blue,
        ),
      ),
    ]);
  }
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

Future<List<UCanvas>> fetchFriendCanvases(String friendUID) async {
  final canvasQuerySnapshot = await _firestore
      .collection('users')
      .doc(friendUID)
      .collection('canvases')
      .get();

  return canvasQuerySnapshot.docs.map((doc) {
    final canvas = UCanvas(
      id: doc.id,
      name: doc.data()['name'],
      ownerId: doc.data()['ownerId'],
    );
    return canvas;
  }).toList();
}
