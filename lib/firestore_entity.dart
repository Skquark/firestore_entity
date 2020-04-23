import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_auth_info.dart';
import 'firestore_common.dart';
import 'firestore_helper.dart';

class FirestoreEntity<T> extends FirestoreCommon<T> {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  T _lastValue;
  String _path;
  BehaviorSubject<T> _itemChangesSubscription;

  FirestoreEntity(String docPath, FromJson<T> fromJson, ToJson<T> toJson)
      : super(fromJson, toJson) {
    _path = docPath;
    init();
  }

  FirestoreEntity.fromExistingEntity(
      String docPath, T item, FromJson<T> fromJson, ToJson<T> toJson)
      : super(fromJson, toJson) {
    _path = docPath;
    _lastValue = item;
    init();
  }

  Firestore get firestore => FirestoreCommon.firestoreInstance;

  T get value => _lastValue;

  String get id => _path?.split("/")?.last;

  String get path => _path;

  Future<T> get() async {
    if (failedRequiredAuth(_path)) return null;
    var snapshot =
        await firestore.document(FirebaseAuthInfo.resolvePath(_path)).get();

    return _lastValue = fromSnapshot(snapshot);
  }

  Future<bool> exists() async {
    if (failedRequiredAuth(_path)) return false;
    var snapshot =
        await firestore.document(FirebaseAuthInfo.resolvePath(_path)).get();

    return snapshot.exists;
  }

  Future<void> set(T entity, {merge = false}) async {
    if (failedRequiredAuth(_path)) return;

    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .setData(toData(entity), merge: merge);
  }

  Future<void> update(T entity) async {
    if (failedRequiredAuth(_path)) return;

    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .updateData(toData(entity));
  }

  Future<void> updateData(Map<String, dynamic> data) async {
    if (failedRequiredAuth(_path)) return;

    await firestore
        .document(FirebaseAuthInfo.resolvePath(_path))
        .updateData(data);
  }

  Future<void> delete() async {
    if (failedRequiredAuth(_path)) return;
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

    if (FirebaseAuthInfo.hasUserParamInPath(_path))
      FirebaseAuthInfo.onAuthChange().listen((authed) {
        if (authed) {
          // if (documentChanges == null)
          _documentChanges = firestore
              .document(FirebaseAuthInfo.resolvePath(_path))
              .snapshots()
              .listen((snapshot) async {
            _itemChangesSubscription.add(_lastValue = fromSnapshot(snapshot));
          });
        } else {
          _documentChanges?.cancel();
          _itemChangesSubscription.add(null);
          FirebaseAuthInfo.setAuthState(false);
        }
      });
    else
      _documentChanges = firestore
          .document(FirebaseAuthInfo.resolvePath(_path))
          .snapshots()
          .listen((snapshot) async {
        _itemChangesSubscription.add(_lastValue = fromSnapshot(snapshot));
      });

    return _itemChangesSubscription.stream;
  }

  void close() {
    _itemChangesSubscription.close();
  }
}
