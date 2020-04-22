import 'dart:async';

import 'package:firestore_entity/firestore_collection.dart';
import 'package:flutter/material.dart';
import 'package:firestore_entity/firestore_entity.dart';

import 'book.dart';
import 'profile.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirestoreEntity<Profile> profileEntity;

  @override
  void initState() async {
    super.initState();

    profileEntity = FirestoreEntity<Profile>(
      "profiles/{userId}",
      (json) => Profile.fromJson(json),
      (item) => item.toJson(),
    );

    // get document's id
    String profileId = profileEntity.id;

    // get document's path
    String profilePath = profileEntity.path;

    // get document
    Profile profile = await profileEntity.get();

    // update document
    await profileEntity.update(profile);

    // update specific fields in a document
    await profileEntity.updateData({"points": 200});

    // set document
    await profileEntity.set(profile);

    // delete document
    await profileEntity.delete();

    // is document exists
    bool exists = await profileEntity.exists();

    // stream changes (triggerd once subscribed with latest value)
    StreamSubscription<Profile> subscription =
        profileEntity.data().listen((profile) {
      print(profile.id);
    });
    subscription.cancel();

    // latest stored offline value
    Profile profileOffline = profileEntity.value;

    //collection: path can also have {userId} variable e.g. "users/{userId}/myBooks"
    var booksCol = FirestoreCollection<Book>(
      "books",// or "users/{userId}/myBooks"
      (json) => Book.fromJson(json),
      (item) => item.toJson(),
    ).where("points", isGreaterThan: 200);

    // get collection's path
    String booksPath = booksCol.path;

    // get all documents
    List<Book> books = await booksCol.get();

    // get all documents wrapped in FirestoreEntity class
    List<FirestoreEntity<Book>> booksEntities = await booksCol.getEntities();
    booksEntities[0].updateData({"new": true});

    // add new document then get it's id
    FirestoreEntity<Book> bookEntity =
        await booksCol.add(new Book(title: "book 1"));
    var book1_Id = bookEntity.id; // new

    // stream changes (triggerd once subscribed with latest value)
    booksCol.data().listen((books) {
      print(books.length);
    });

    // latest stored offline value
    List<Book> booksOffline = booksCol.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder(
              stream: profileEntity.data(),
              builder: (context, AsyncSnapshot<Profile> snapshot) {
                return Text(
                    "my points: " + snapshot.data?.points?.toString() ?? "0");
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
