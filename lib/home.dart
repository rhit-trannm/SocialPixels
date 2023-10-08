import 'package:flutter/material.dart';
import 'package:namer_app/draw.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showCanvas = false; // this variable will determine what to display

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: <Widget>[
          if (!_showCanvas)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 0.5,
                      child: Image.asset(
                        'logo.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showCanvas = true;
                      });
                    },
                    child: Text('Switch to Canvas'),
                  ),
                ],
              ),
            ),
          if (_showCanvas) Expanded(child: DrawingCanvas()),
        ],
      ),
    );
  }

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  // build the drawer (left panel).
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Drawer Header'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
            },
          ),
          //  more list tiles or other widgets
        ],
      ),
    );
  }
}
