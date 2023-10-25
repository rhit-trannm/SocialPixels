import 'package:flutter/material.dart';
import 'package:namer_app/draw.dart';
import 'package:namer_app/friend.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home Page'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _openDrawer(),
        ),
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(54, 38, 87, 1),
              Color.fromRGBO(54, 39, 82, 1),
              Color.fromRGBO(51, 36, 77, 1),
              Color.fromRGBO(47, 35, 75, 1),
              Color.fromRGBO(38, 27, 61, 1),
              Color.fromRGBO(38, 28, 65, 1),
            ],
          ),
        ),
        child: _canvasID != null
            ? a = DrawingCanvas(
                key: ValueKey(_canvasID),
                canvasID: _canvasID!,
                uid: FirebaseAuth.instance.currentUser!
                    .uid) // If _canvasID is set, create a new DrawingCanvas widget
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
                            child: Image.asset('logo.png'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      ],
    );
  }

  void _toggleDrawer(int index) {
    setState(() {
      _currentDrawerIndex = index;
    });
  }

  final currentUserUID = FirebaseAuth.instance.currentUser?.uid;

  Widget _buildDrawer1() {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.add, color: Colors.white),
                                onPressed: _buildAddFriendDialog,
                              ),
                              IconButton(
                                icon: Icon(Icons.mail_outline,
                                    color: Colors.white),
                                onPressed: _showFriendRequestsDialog,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchFriends(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No friends added');
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (BuildContext context, int index) {
                            final friend = snapshot.data![index];
                            return ExpansionTile(
                              title: Text(friend['displayName']),
                              subtitle: Text(friend['email']),
                              children: <Widget>[
                                FutureBuilder<List<UCanvas>>(
                                  future: fetchFriendCanvases(friend['uid']),
                                  builder: (context, canvasSnapshot) {
                                    if (canvasSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (canvasSnapshot.hasError) {
                                      return Text(
                                          'Error: ${canvasSnapshot.error}');
                                    } else if (!canvasSnapshot.hasData ||
                                        canvasSnapshot.data!.isEmpty) {
                                      return Text('No canvases available');
                                    } else {
                                      return ListView.builder(
                                        itemCount: canvasSnapshot.data!.length,
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (BuildContext context,
                                            int canvasIndex) {
                                          final canvas =
                                              canvasSnapshot.data![canvasIndex];
                                          return ListTile(
                                              title: Text(canvas.name),
                                              onTap: () {
                                                setState(() {
                                                  _canvasID = null;
                                                });
                                                setState(() {
                                                  _canvasID = canvas.id;
                                                  a = DrawingCanvas(
                                                      canvasID: _canvasID!,
                                                      uid: friend['uid']);
                                                  print(_canvasID);
                                                });
                                                Navigator.of(context).pop();
                                              });
                                        },
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  )
                ],
              ),
            ),
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
                  icon: Icon(Icons.account_circle),
                  onPressed: () {
                    _toggleDrawer(1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFriendRequestsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Friend Requests"),
          content: Container(
            width: double.maxFinite,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchFriendRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No friend requests available');
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      final request = snapshot.data![index];
                      return ListTile(
                        leading: Icon(Icons.person),
                        title: Text(request['displayName']),
                        subtitle: Text(request['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                print(request.toString());
                                await acceptFriendRequest(
                                    FirebaseAuth.instance.currentUser!.uid,
                                    request['uid']);
                                setState(() {});
                                Navigator.of(context).pop();
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                print("HELLO2");
                                await denyFriendRequest(
                                    FirebaseAuth.instance.currentUser!.uid,
                                    request['uid']);
                                setState(() {});
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
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
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('No canvases available');
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics:
                              NeverScrollableScrollPhysics(), // Important! This will keep inner ListView from interfering with the outer SingleChildScrollView.
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
                                  a = DrawingCanvas(
                                    canvasID: _canvasID!,
                                    uid: FirebaseAuth.instance.currentUser!.uid,
                                  );
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
            ),
          ),
          Row(
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

  void _buildAddFriendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddFriendDialog(context);
      },
    );
  }

  Widget _AddFriendDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    return AlertDialog(
      title: Text('Enter Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'User email',
            ),
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
            String email = emailController.text;
            try {
              await sendFriendRequest(email);
              Navigator.of(context).pop(); // Close the dialog.
            } catch (error) {
              print(error);
            }
          },
        ),
      ],
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
              genCanvasId = await createCanvas(name);
              setState(() {
                _canvasID = null;
              });
              setState(() {
                _canvasID = genCanvasId;
                a = DrawingCanvas(
                    canvasID: _canvasID!,
                    uid: FirebaseAuth.instance.currentUser!.uid);
                print(_canvasID);
              });
              Navigator.of(context).pop();
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
