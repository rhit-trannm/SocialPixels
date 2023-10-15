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
                    height: MediaQuery.of(context).size.width *
                        0.3, // 60% of screen width, adjust as neede
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
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text('Drawer Header'),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.add,
                        color: Colors.white), // Add the "+" icon
                    onPressed:
                        _buildAddCanvasDialog, // Define this method separately
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {
              // Close the drawer
              Navigator.pop(context);
            },
          ),
          // more list tiles or other widgets
        ],
      ),
    );
  }

  void _buildAddCanvasDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildNameEmailDialog(context);
      },
    );
  }

  Widget _buildNameEmailDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    return AlertDialog(
      title: Text('Enter Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Canvas Name',
            ),
          ),
          SizedBox(height: 16.0), // Spacing
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Invite via Email Address',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Submit'),
          onPressed: () async {
            String name = nameController.text;
            String email = emailController.text;
            // Handle the data here, e.g. save it or send it to a server.

            print('Name: $name, Email: $email');
            try {
              await createCanvas(
                  name); // This will create the canvas using the current authenticated user's email.
              Navigator.of(context).pop(); // Close the dialog.
            } catch (error) {
              // Handle the error e.g. by showing an error message to the user
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create canvas: $error')));
            }
            Navigator.of(context).pop(); // Close the dialog.
          },
        ),
      ],
    );
  }
}
