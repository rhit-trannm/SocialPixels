import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/draw.dart';
import 'package:namer_app/firebase_options.dart';
import 'package:namer_app/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email & password
  Future<User?> signUp(
      String email, String password, String displayName) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.updateDisplayName(displayName);

      // Create a new user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'uuid': userCredential.user!.uid,
        'friends': [], // an empty list of friends to begin with
        'profileURL': 'gs://socialpixels-dca76.appspot.com/download.png'
      });
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('canvases')
          .add({});
      //Firestore creates an empty entry into canvases that bugs the load up homescreen.
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .collection('canvases')
          .get();
      for (QueryDocumentSnapshot documentSnapshot in querySnapshot.docs) {
        await documentSnapshot.reference.delete();
      }
      return userCredential.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> updateUserProfile(String displayName, String? imageUrl) async {
    User? currentUser = getCurrentUser();
    if (currentUser != null) {
      await currentUser.updateDisplayName(displayName);
      await _firestore.collection('users').doc(currentUser.uid).update({
        'displayName': displayName,
        if (imageUrl != null) 'profileURL': imageUrl,
      });
    }
  }

  // Login with email & password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Fetch user data from Firestore
  Future<DocumentSnapshot> fetchUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.3;

    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        backgroundColor: Color.fromRGBO(69, 49, 109, 1),
      ),
      backgroundColor:
          Color.fromRGBO(38, 28, 63, 1), // Set the background color
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: width, // Set width to 80% of screen width
                  child: TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: Color.fromRGBO(99, 89, 133, 1),
                      filled: true,
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: width, // Set width to 80% of screen width
                  child: TextField(
                    controller: _passwordController,
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      fillColor: Color.fromRGBO(99, 89, 133, 1),
                      filled: true,
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Color.fromRGBO(69, 49, 109, 1)),
                  onPressed: () async {
                    var user =
                        await _authService.login(_emailController.text, _passwordController.text);
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    } else {
                      print("Failed to sign up");
                    }
                  },
                  child: Text("Login"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Color.fromRGBO(160, 139, 201, 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _authService = AuthService();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.3;

    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      backgroundColor:
          Color.fromRGBO(38, 28, 63, 1), // Set the background color
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: width, // Set width to 80% of screen width
                  child: TextField(
                    controller: _displayNameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: Color.fromRGBO(99, 89, 133, 1),
                      filled: true,
                      labelText: 'Display Name',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: width, // Set width to 80% of screen width
                  child: TextField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: Color.fromRGBO(99, 89, 133, 1),
                      filled: true,
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: width, // Set width to 80% of screen width
                  child: TextField(
                    controller: _passwordController,
                    style: TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      fillColor: Color.fromRGBO(99, 89, 133, 1),
                      filled: true,
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    var user = await _authService.signUp(_emailController.text,
                        _passwordController.text, _displayNameController.text);
                    if (user != null) {
                      print("Successfully signed up with user id ${user.uid}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    } else {
                      print("Failed to sign up");
                    }
                  },
                  child: Text("Sign Up"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
