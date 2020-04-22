
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_auth_info.dart';
import 'firestore_entity.dart';
import 'firestore_helper.dart';

class FirestoreCollection<T> {
  FromJson<T> _fromJson;
  ToJson<T> _toJson;
  String _path;
  List<T> _lastValue;
  BehaviorSubject<List<T>> _itemsChangesSubscription;

  FirestoreCollection(
      String collectionPath, FromJson<T> fromJson, ToJson<T> toJson) {
    _fromJson = fromJson;
    _toJson = toJson;
    _path = collectionPath;
    print("FirestoreCollection: " + _path);
  }

  Firestore get firestore => FirestoreHelper.firestore;
  List<T> get value => _lastValue;

  FirestoreEntity<T> document(String id) {
    var entity = new FirestoreEntity("${_path}/${id}", _fromJson, _toJson);
    // entity.get();
    return entity;
  }

  Query where(
    dynamic field, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic> arrayContainsAny,
    List<dynamic> whereIn,
    bool isNull,
  }) {
    return this.firestore.collection(_path).where(
          field,
          isEqualTo: isEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          arrayContains: arrayContains,
          arrayContainsAny: arrayContainsAny,
          whereIn: whereIn,
          isNull: isNull,
        );
  }

  List<T> _fromSnapshots(QuerySnapshot querySnapshot) {
    return querySnapshot.documents
        .map((a) => FirestoreHelper.fromSnapshot(a, _fromJson))
        .toList();
  }

  Stream<List<T>> data() {
    if (_itemsChangesSubscription != null)
      return _itemsChangesSubscription.stream;
    // if (_stream != null) return _stream;
    // return _stream = _itemChanges();
    return _itemsChanges();
  }

  Stream<List<T>> _itemsChanges() {
    StreamSubscription<QuerySnapshot> _documentChanges;
    _itemsChangesSubscription = new BehaviorSubject<List<T>>(
      onCancel: () => _documentChanges?.cancel(),
    );
    print("cooll: " + _path);

    FirebaseAuthInfo.onAuthChange().listen((authed) {
      if (authed) {
        // if (documentChanges == null)
        _documentChanges = firestore
            .collection(FirebaseAuthInfo.resolvePath(_path))
            .snapshots()
            .listen((snapshot) async {
          print("Document Changed");
          _itemsChangesSubscription.add(_lastValue = _fromSnapshots(snapshot));
        });
      } else {
        _documentChanges?.cancel();
        _itemsChangesSubscription.add(null);
        FirebaseAuthInfo.setAuthState(false);
      }
    });
    return _itemsChangesSubscription.stream;
  }
}