import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import 'firestore_helper.dart';

class FirebaseAuthInfo {
  static final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static String userId = "";

  static bool _isAuthed = false;
  static bool _isAuthedInited = false;
  static final _onAuthChange = BehaviorSubject<bool>();
  static Stream<bool> onAuthChange() {
    return _onAuthChange.stream;
  }

  static Future<void> close() async {
    _onAuthChange.close();
  }

  static void setAuthState(bool authed) async {
    var auth = await firebaseAuth.currentUser();
    userId = auth?.uid ?? "";
    if (_isAuthed != (auth != null && authed) || !_isAuthedInited) {
      _onAuthChange.sink.add(_isAuthed = (auth != null && authed));
      _isAuthedInited = true;
    }
  }

  static String resolvePath(String path) => path.replaceAll("{userId}", userId);

  static bool hasUserParamInPath(String path) => path.contains("{userId}");

  static bool initialized = false;
  static init() {
    if (initialized) return;
    firebaseAuth.onAuthStateChanged.listen((auth) async {
      print("onAuthStateChanged");

      setAuthState(auth != null);
    });
  }
}
