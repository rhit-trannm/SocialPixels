import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendFriendRequest(String emailToSendRequest) async {
  final firestore = FirebaseFirestore.instance;

  // Get current user's details
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    throw Exception("You're not logged in!");
  }

  // Find the user with the provided email
  print(emailToSendRequest);
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

Future<List<Map<String, dynamic>>> fetchFriends() async {
  List<Map<String, dynamic>> friendList = [];

  // Get current user
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception("User not signed in!");
  }

  // Get user's document from Firestore
  DocumentReference userDocRef =
      FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

// Fetch user's data
  DocumentSnapshot userDoc = await userDocRef.get();
  if (!userDoc.exists) {
    throw Exception("User document doesn't exist!");
  }

// friends' UIDs
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  List<dynamic>? friendsUIDs = userData['friends'];
  if (friendsUIDs == null || friendsUIDs.isEmpty) {
    return friendList; // Return empty list if no friends found
  }

// Fetch details of each friend using their UID
  for (String friendUID in friendsUIDs) {
    DocumentSnapshot friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUID)
        .get();
    if (friendDoc.exists) {
      Map<String, dynamic> friendData =
          friendDoc.data() as Map<String, dynamic>;
      friendList.add({
        'displayName': friendData['displayName'],
        'email': friendData['email'],
      });
    }
  }

  return friendList;
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> acceptFriendRequest(
    String currentUserUID, String requesterUID) async {
  print("HELLO");
  CollectionReference users = _firestore.collection('users');

  // Remove requester's UID from the current user's friendRequests list
  print("done1");
  await users.doc(currentUserUID).update({
    'friendRequests': FieldValue.arrayRemove([requesterUID])
  });
  print("done2");
  // Add requester's UID to the current user's friends list
  await users.doc(currentUserUID).update({
    'friends': FieldValue.arrayUnion([requesterUID])
  });
  print("done3");
  // Add the current user's UID to the requester's friends list
  await users.doc(requesterUID).update({
    'friends': FieldValue.arrayUnion([currentUserUID])
  });
}

Future<void> denyFriendRequest(
    String currentUserUID, String requesterUID) async {
  CollectionReference users = _firestore.collection('users');

  // Transaction for data consistency
  return _firestore.runTransaction((transaction) async {
    // Remove requester's UID from the current user's friendRequests list
    transaction.update(
      users.doc(currentUserUID),
      {
        'friendRequests': FieldValue.arrayRemove([requesterUID])
      },
    );
  });
}
