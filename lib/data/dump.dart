import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import './message.dart';
import 'dart:convert';

class T {
  d() async {
    //d = json.decode("source");
    //Firestore.instance.collectionGroup("messages").where("timestamp", isGreaterThan: 100).snapshots().listen(onData)
    final d = Firestore.instance.collectionGroup("path").getDocuments();

    final user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      // signed in
    } else {
      
    }

    final last = await Firestore.instance
        .collection("users")
        .document("userId")
        .collection("update")
        .document("last")
        .get();

    final update = last.data["value"] as int;

    var dc = await Future.wait([d]);
  }
}

class BookList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('books').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Text('Loading...');
          default:
            return new ListView(
              children:
                  snapshot.data.documents.map((DocumentSnapshot document) {
                return new ListTile();
              }).toList(),
            );
        }
      },
    );
  }
}
