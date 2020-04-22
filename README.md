# whiteboardkit

A Firestore Wrapper library for binding and mapping documents to class entities. Enjoy !

![Package demo](screenshot.gif)

## Usage

import whiteboardkit.dart

```dart
import 'package:firestore_entity/firestore_entity.dart';
```

given we have the following class

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
```

we can create a entity reference to point to an existing document with `FirestoreEntity` class

```dart
  GestureWhiteboardController controller;

  @override
  void initState() {
    controller = new GestureWhiteboardController();
    controller.onChange().listen((draw){
      //do something with it
    });
    super.initState();
  }
```

place your Whiteboard inside a constrained widget ie. container,Expanded etc

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
            Expanded(
              child: Whiteboard(
                controller: controller,
              ),
            ),
          ],
        ),
      ),
    );
  }
```
