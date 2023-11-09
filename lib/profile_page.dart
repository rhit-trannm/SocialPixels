import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/avatar_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String? _updatedImageUrl;
  String? _imageUrl;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? _user = _authService.getCurrentUser();
    if (_user != null) {
      DocumentSnapshot userData = await _authService.fetchUserData(_user!.uid);
      if (userData.exists && userData.data() is Map) {
        // Cast the data to Map<String, dynamic> explicitly
        Map<String, dynamic> dataMap = userData.data() as Map<String, dynamic>;
        setState(() {
          _imageUrl = dataMap['profileURL'];
          nameController.text = dataMap['displayName'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Edit Profile"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                if (_imageUrl != null) AvatarImage(imageUrl: _imageUrl!),
                const SizedBox(height: 4.0),
                // Your UploadButton logic here...
                // Handle the image upload and URL updating logic here
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Display Name",
                    hintText: "Enter a display name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please add a display name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await _authService.updateUserProfile(
                            nameController.text,
                            _updatedImageUrl,
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text("Save and Close"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
