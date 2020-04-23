import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_auth_info.dart';
import 'firestore_common.dart';
import 'firestore_entity.dart';
import 'firestore_helper.dart';

class FirestoreCollection<T> extends FirestoreCommon<T> {
  FromJson<T> _fromJson;
  ToJson<T> _toJson;
  String _path;
  List<T> _lastValue;
  BehaviorSubject<List<T>> _itemsChangesSubscription;
  Query _query;

  FirestoreCollection(
      String collectionPath, FromJson<T> fromJson, ToJson<T> toJson)
      : super(fromJson, toJson) {
    _fromJson = fromJson;
    _toJson = toJson;
    _path = collectionPath;
    init();
  }

  FirestoreCollection.fromQuery(Query query, String collectionPath,
      FromJson<T> fromJson, ToJson<T> toJson)
      : super(fromJson, toJson) {
    _fromJson = fromJson;
    _toJson = toJson;
    _path = collectionPath;
    _query = query;
    init();
  }

  Firestore get firestore => FirestoreCommon.firestoreInstance;

  List<T> get value => _lastValue;

  String get path => _path;

  FirestoreEntity<T> document(String id) {
    var docPath = _path + "/" + id;
    var entity = new FirestoreEntity(docPath, _fromJson, _toJson);
    // entity.get();
    return entity;
  }

  FirestoreCollection<T> where(
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
    var query = _query;

    if (query == null)
      query =
          this.firestore.collection(FirebaseAuthInfo.resolvePath(_path)).where(
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
    else
      query = query.where(
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
    return FirestoreCollection<T>.fromQuery(
        query, _path, (json) => fromJson(json), (item) => toJson(item));
  }

  List<T> _fromSnapshots(QuerySnapshot querySnapshot) {
    return querySnapshot.documents.map((a) => fromSnapshot(a)).toList();
  }

  Future<List<T>> get() async {
    QuerySnapshot snapshots;
    if (_query == null)
      snapshots = await firestore
          .collection(FirebaseAuthInfo.resolvePath(_path))
          .getDocuments();
    else
      snapshots = await _query.getDocuments();

    return _lastValue = _fromSnapshots(snapshots);
  }

  Future<List<FirestoreEntity<T>>> getEntities() async {
    var snapshots = await firestore
        .collection(FirebaseAuthInfo.resolvePath(_path))
        .getDocuments();

    _lastValue = _fromSnapshots(snapshots);

    return snapshots.documents.map((snapshot) =>
        FirestoreEntity<T>.fromExistingEntity(_path + "/" + snapshot.documentID,
            fromSnapshot(snapshot), fromJson, toJson));
  }

  Future<FirestoreEntity<T>> add(T entity) async {
    var data = toData(entity);
    var ref = await firestore
        .collection(FirebaseAuthInfo.resolvePath(_path))
        .add(data);
    data["id"] = ref.documentID;

    return FirestoreEntity<T>.fromExistingEntity(
        _path + "/" + ref.documentID, fromJson(data), fromJson, toJson);
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

    if (FirebaseAuthInfo.hasUserParamInPath(_path))
      FirebaseAuthInfo.onAuthChange().listen((authed) {
        if (authed) {
          // if (documentChanges == null)

          if (_query == null)
            _documentChanges = firestore
                .collection(FirebaseAuthInfo.resolvePath(_path))
                .snapshots()
                .listen((snapshot) async {
              _itemsChangesSubscription
                  .add(_lastValue = _fromSnapshots(snapshot));
            });
          else
            _documentChanges = _query.snapshots().listen((snapshot) async {
              _itemsChangesSubscription
                  .add(_lastValue = _fromSnapshots(snapshot));
            });
        } else {
          _documentChanges?.cancel();
          _itemsChangesSubscription.add(null);
          FirebaseAuthInfo.setAuthState(false);
        }
      });
    else {
      if (_query == null)
        _documentChanges = firestore
            .collection(FirebaseAuthInfo.resolvePath(_path))
            .snapshots()
            .listen((snapshot) async {
          _itemsChangesSubscription.add(_lastValue = _fromSnapshots(snapshot));
        });
      else
        _documentChanges = _query.snapshots().listen((snapshot) async {
          _itemsChangesSubscription.add(_lastValue = _fromSnapshots(snapshot));
        });
    }
    return _itemsChangesSubscription.stream;
  }
}
