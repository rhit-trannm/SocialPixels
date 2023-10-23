import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendFriendRequest(String emailToSendRequest) async {
  // Assuming you've initialized Firebase
  final firestore = FirebaseFirestore.instance;

  // Get the current user's details
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    throw Exception("You're not logged in!");
  }

  // Find the user with the provided email
  final querySnapshot = await firestore
      .collection('users')
      .where('email', isEqualTo: emailToSendRequest)
      .get();

  if (querySnapshot.docs.isEmpty) {
    throw Exception("User not found!");
  }

  final friendDoc = querySnapshot.docs.first;

  // Send friend request
  await firestore
      .collection('users')
      .doc(friendDoc.id)
      .collection('friendRequests')
      .doc(currentUser.uid)
      .set({
    'displayName': currentUser.displayName,
    'email': currentUser.email,
    'sentAt': Timestamp.now(),
  });

  // Here you can also integrate Firebase Cloud Messaging to send a notification
}
Future<List<Map<String, dynamic>>> fetchFriendRequests() async {
  final firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    throw Exception("You're not logged in!");
  }

  final querySnapshot = await firestore
      .collection('users')
      .doc(currentUser.uid)
      .collection('friendRequests')
      .get();

  return querySnapshot.docs.map((doc) => doc.data()).toList();
}
