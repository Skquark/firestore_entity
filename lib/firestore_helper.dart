
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef T FromJson<T>(Map<String, dynamic> json);
typedef Map<String, dynamic> ToJson<T>(T item);

class FirestoreHelper {
  static final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static final Firestore firestore = Firestore.instance;

  static T fromSnapshot<T>(DocumentSnapshot snapshot, FromJson<T> fromJson) {
    var data = snapshot.data;
    if (data == null) return null;
    data["id"] = snapshot.documentID;

    var item = fromJson(data);
    return item;
  }
}