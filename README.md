# whiteboardkit

A Firestore Wrapper library for binding and mapping documents to dart classes. Enjoy !

## Features
- Maps Firestore's documents to existing dart classes.
- fills up id from document's id.
- Resovles `{userId}` in path to currently signed-in Firebase Auth user's uid e.g `profiles/{userId}`.
- Automatic off/on `.data()` stream subscription when path contains `{userId}` (see usage example below).

## Usage

```dart
import 'package:firestore_entity/firestore_entity.dart';
```

given we have the following classes represent our application's model entities:

```dart
  class Profile {
    String id;
    int points;

    Profile({this.id, this.points});
    factory Profile.fromJson(Map<String, dynamic> json) => Profile(
          id: json['id'] as String,
          points: json['points'] as int,
        );
    Map<String, dynamic> toJson() => <String, dynamic>{
          'id': this.id,
          'points': this.points,
        };
  }
  
  class Book {
    String id;
    String title;

    Book({this.id, this.title});
    factory Book.fromJson(Map<String, dynamic> json) => Book(
          id: json['id'] as String,
          title: json['title'] as String,
        );
    Map<String, dynamic> toJson() => <String, dynamic>{
          'id': this.id,
          'title': this.title,
        };
  }
```

we can create a reference to an existing document in Firestore using `FirestoreEntity` class

```dart
    var profileEntity = FirestoreEntity<Profile>(
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
```

we can use `FirestoreEntity<T>.data()` in `StreamBuilder` like:

```dart

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

```

we can also initiate a collection reference using `FirestoreCollection` class

```dart
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
```
