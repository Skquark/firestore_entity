import 'package:json_annotation/json_annotation.dart';

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
