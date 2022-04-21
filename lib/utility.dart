import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class MyAuth with ChangeNotifier {
  FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;

  MyAuth.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Status get status => _status;

  User? get user => _user;

  bool get isAuthenticated => status == Status.Authenticated;

  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Set<WordPair> _data = <WordPair>{};

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _data = await getFavorites();
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      print(e);
      return false;
    }
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }
  Future<void> uploadNewImage(File file)async {
    await _storage
        .ref('images')
        .child(_user!.uid)
        .putFile(file);
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  Future<void> addPair(String pair, String pair1, String pair2) async {
    if (_status == Status.Authenticated) {
      await _database
          .collection("users")
          .doc(_user!.uid)
          .collection("favorites")
          .doc(pair.toString())
          .set({'first': pair1, 'second': pair2});
    }
    _data = await getFavorites();
    notifyListeners();
  }

  Future<void> removePair(String pair) async {
    if (_status == Status.Authenticated) {
      await _database
          .collection("users")
          .doc(_user!.uid)
          .collection('favorites')
          .doc(pair.toString())
          .delete();
      _data = await getFavorites();
      notifyListeners();
    }

    notifyListeners();
  }
  Future<String>
  getImage() async {
    return await _storage.ref('images').child(_user!.uid).getDownloadURL();
  }


  String? getEmail() {
    return _user!.email;
  }


  Future<Set<WordPair>> getFavorites() async {
    Set<WordPair> s = <WordPair>{};
    await _database
        .collection("users")
        .doc(_user!.uid)
        .collection('favorites')
        .get()
        .then((querySnapshot) {
      for (var result in querySnapshot.docs) {
        String first = result.data().entries.first.value.toString();
        String sec = result.data().entries.last.value.toString();
        s.add(WordPair(first, sec));
      }
    });
    return Future<Set<WordPair>>.value(s);
  }

  Set<WordPair> getData() {
    return _data;
  }
}
