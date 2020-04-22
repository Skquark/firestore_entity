import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_auth_info.dart';
import 'firestore_helper.dart';

class FirestoreEntity<T> {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  // Stream<T> stream;

  T _lastValue;
  FromJson<T> _fromJson;
  ToJson<T> _toJson;
  String _path;
  BehaviorSubject<T> _itemChangesSubscription;
  // Stream<T> _stream;

  FirestoreEntity(String docPath, FromJson<T> fromJson, ToJson<T> toJson) {
    _fromJson = fromJson;
    _toJson = toJson;
    _path = docPath;
    // stream = _itemChanges()
    //   ..listen((item) {
    //     _lastValue = item;
    //   });
  }

  Firestore get firestore => FirestoreHelper.firestore;

  T get value => _lastValue;

  Map<String, dynamic> _toData(T entity) {
    var data = _toJson(entity);
    if (data == null) return null;
    data.removeWhere((key, value) => key == "id");

    return data;
  }

  Future<T> get() async {
    var snapshot =
        await firestore.document(FirebaseAuthInfo.resolvePath(_path)).get();

    return _lastValue = FirestoreHelper.fromSnapshot(snapshot, _fromJson);
  }

  Future<bool> exists() async {
    var snapshot =
        await firestore.document(FirebaseAuthInfo.resolvePath(_path)).get();

    return snapshot.exists;
  }

  Future<void> set(T entity, {merge = false}) async {
    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .setData(_toData(entity), merge: merge);
  }

  Future<void> update(T entity) async {
    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .updateData(_toData(entity));
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .updateData(data);
  }

  Future<void> delete() async {
    await firestore.document(FirebaseAuthInfo.resolvePath(_path)).delete();
  }

  Stream<T> data() {
    if (_itemChangesSubscription != null)
      return _itemChangesSubscription.stream;
    // return _stream = _itemChanges();
    return _itemChanges();
  }

  Stream<T> _itemChanges() {
    StreamSubscription<DocumentSnapshot> _documentChanges;
    _itemChangesSubscription = new BehaviorSubject<T>(
      onCancel: () => _documentChanges?.cancel(),
    );

    FirebaseAuthInfo.onAuthChange().listen((authed) {
      if (authed) {
        // if (documentChanges == null)
        _documentChanges = firestore
            .document(FirebaseAuthInfo.resolvePath(_path))
            .snapshots()
            .listen((snapshot) async {
          print("Document Changed");
          _itemChangesSubscription.add(
              _lastValue = FirestoreHelper.fromSnapshot(snapshot, _fromJson));
        });
      } else {
        _documentChanges?.cancel();
        _itemChangesSubscription.add(null);
        FirebaseAuthInfo.setAuthState(false);
      }
    });
    return _itemChangesSubscription.stream;
  }

  void close() {
    _itemChangesSubscription.close();
  }
}
