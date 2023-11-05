import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_storage/firebase_ui_storage.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/avatar_image.dart';
import 'package:namer_app/auth_manager.dart';
import 'package:namer_app/user_data_document_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  StreamSubscription? _userDataSubscription;
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _updatedImageUrl;

  @override
  void initState() {
    _userDataSubscription = UserDataDocumentManager.instance.startListening(
      documentId: AuthManager.instance.uid,
      observer: () {
        setState(() {
          nameController.text = UserDataDocumentManager.instance.displayName;
          print("Display name ${UserDataDocumentManager.instance.displayName}");
          print("Image URL ${UserDataDocumentManager.instance.imageUrl}");
        });
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    UserDataDocumentManager.instance.stopListening(_userDataSubscription);
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = UserDataDocumentManager.instance.imageUrl;

    // If a new image has been uploaded use it instead!
    if (_updatedImageUrl != null) {
      imageUrl = _updatedImageUrl!;
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(
                  height: 20.0,
                ),
                AvatarImage(imageUrl: imageUrl),
                const SizedBox(
                  height: 4.0,
                ),
                UploadButton(
                  metadata: SettableMetadata(contentType: "image/jpeg"),
                  extensions: ['jpg', 'png'],
                  mimeTypes: ['image/jpeg', 'image/png'],
                  onError: (e, s) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  ),
                  onUploadComplete: (ref) async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Upload complete"),
                      ),
                    );
                    _updatedImageUrl = await ref.getDownloadURL();
                    setState(() {});
                  },
                  variant: ButtonVariant.outlined,
                ),
                const SizedBox(
                  height: 20.0,
                ),
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
                const SizedBox(
                  height: 20.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Everything is Valid!
                          await UserDataDocumentManager.instance.update(
                              displayName: nameController.text,
                              imageUrl: _updatedImageUrl);
                          Navigator.of(context).pop();
                        } else {
                          // Something is wrong
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   const SnackBar(
                          //     content: Text("Add a display name"),
                          //   ),
                          // );
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
