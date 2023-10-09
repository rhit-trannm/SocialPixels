import 'package:flutter/material.dart';
import 'package:namer_app/draw.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showCanvas = false; // this variable will determine what to display
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 24, 18, 43),
      key: _scaffoldKey,
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
                  Container(
                    height: MediaQuery.of(context).size.width * 0.3, // 60% of screen width, adjust as neede
                    width: MediaQuery.of(context).size.width * 0.3,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(
                        'logo.jpg',
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
    _scaffoldKey.currentState?.openDrawer();
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
