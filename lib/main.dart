import 'package:flutter/material.dart';
import 'package:namer_app/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:namer_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Define routes if multiple pages
      routes: {
        '/login': (context) => LoginSignupPage(), // login page
        // Add other routes if needed
        // '/home': (context) => HomePage(),
      },
      initialRoute: '/login', // Set the route to the login page
    );
  }
}
