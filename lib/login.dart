import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:namer_app/draw.dart';
import 'package:namer_app/firebase_options.dart';
import 'package:namer_app/home.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email & password
  Future<User?> signUp(String email, String password, String displayName) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user!.updateDisplayName(displayName);
      return userCredential.user;
    } catch (e) {
      print(e.toString());
      return null;
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
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          ElevatedButton(
            onPressed: () async {
              var user = await _authService.login(_emailController.text, _passwordController.text);
              if (user != null) {
                  Navigator.push(context,MaterialPageRoute(builder: (context) => HomePage()),);
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
            child: Text("Don't have an account? Sign Up"),
          ),
        ],
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
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(labelText: 'Display Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          ElevatedButton(
            onPressed: () async {
              var user = await _authService.signUp(_emailController.text, _passwordController.text, _displayNameController.text);
              if (user != null) {
                  print("Successfully signed up with user id ${user.uid}");
                  Navigator.push(context,MaterialPageRoute(builder: (context) => SignupPage()),);
                } else {
                  print("Failed to sign up");
                }
            },
            child: Text("Sign Up"),
          ),
        ],
      ),
    );
  }
}
