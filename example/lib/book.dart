
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
