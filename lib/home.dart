import 'package:flutter/material.dart';
import 'package:namer_app/draw.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentDrawerIndex = 0;
  String? _canvasID;
  late DrawingCanvas a;
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
      body: _canvasID != null
          ? a = DrawingCanvas(
              key: ValueKey(_canvasID),
              canvasID:
                  _canvasID!) // If _canvasID is set, create a new DrawingCanvas widget
          : Stack(
              // Else, show original content
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.width * 0.3,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.asset('logo.jpg'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // build the drawer (left panel).
  Widget _buildDrawer() {
    List<Widget> drawers = [
      _buildDrawer1(),
      _buildDrawer2(),
      _buildDrawer3(),
    ];

    return Stack(
      children: <Widget>[
        Offstage(
          offstage: _currentDrawerIndex != 0,
          child: drawers[0],
        ),
        Offstage(
          offstage: _currentDrawerIndex != 1,
          child: drawers[1],
        ),
        Offstage(
          offstage: _currentDrawerIndex != 2,
          child: drawers[2],
        ),
      ],
    );
  }

  void _toggleDrawer(int index) {
    setState(() {
      _currentDrawerIndex = index;
    });
  }

  Widget _buildDrawer1() {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
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
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: _buildAddCanvasDialog,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Item 1'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              // Add more items for Drawer 1
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    _toggleDrawer(0);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    _toggleDrawer(1);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    _toggleDrawer(2);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer2() {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green,
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
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: _buildAddCanvasDialog,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text('Item 1'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              // Add more items for Drawer 2
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    _toggleDrawer(0);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    _toggleDrawer(1);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    _toggleDrawer(2);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer3() {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.red,
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
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: _buildAddCanvasDialog,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<UCanvas>>(
                future: fetchCanvases(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // loading indicator.
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // If there's an error fetching data, you can display an error message.
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    // If there are no canvases, you can display a message.
                    return Text('No canvases available');
                  } else {
                    // If data is available, create a list of ListTile widgets.
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        final canvas = snapshot.data![index];
                        return ListTile(
                          title: Text(canvas.name),
                          onTap: () {
                            setState(() {
                              _canvasID = null;
                            });
                            setState(() {
                              _canvasID = canvas.id;
                              a = DrawingCanvas(canvasID: _canvasID!);
                              print(_canvasID);
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    _toggleDrawer(0);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    _toggleDrawer(1);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    _toggleDrawer(2);
                  },
                ),
              ],
            ),
          ),
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
            late String genCanvasId;
            print('Name: $name, Email: $email');
            try {
              genCanvasId = await createCanvas(
                  name); // This will create the canvas using the current authenticated user's email.
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return DrawingCanvas(canvasID: genCanvasId);
                  },
                ),
              );
              // setState(() {
              //   Navigator.of(context).pop(); // Close the dialog.
              // });
            } catch (error) {
              // Handle the error e.g. by showing an error message to the user
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create canvas: $error')));
            }
            // Navigator.of(context).pop(); // Close the dialog.
          },
        ),
      ],
    );
  }
}
