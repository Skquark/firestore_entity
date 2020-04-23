import 'package:cloud_firestore/cloud_firestore.dart';

typedef T FromJson<T>(Map<String, dynamic> json);
typedef Map<String, dynamic> ToJson<T>(T item);

class FirestoreCommon<T> {
  final FromJson<T> fromJson;
  final ToJson<T> toJson;

  FirestoreCommon(this.fromJson, this.toJson);

  T fromSnapshot(DocumentSnapshot snapshot) {
    var data = snapshot.data;
    if (data == null) return null;
    data["id"] = snapshot.documentID;

    var item = fromJson(data);
    return item;
  }

  Map<String, dynamic> toData(T entity) {
    var data = toJson(entity);
    if (data == null) return null;
    data.removeWhere((key, value) => key == "id");

    return data;
  }
}
