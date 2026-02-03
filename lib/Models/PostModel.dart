import 'package:my_app/Models/PhotoModel.dart';
import 'package:my_app/Models/FunctionModel.dart';
import 'package:my_app/Models/UserModel.dart';

class PostModel {
  final int? id;
  final String title;
  final String? createdAt;
  final UserModel? user; // mỗi lần gọi sẽ trả về n object, gán từng object đó vào đối tượng để dễ lấy ra từng đối tượng
  final List<PhotoModel> photos;
  List<ReactionCount> reactions;
  String? userIsReaction;

  PostModel({
    this.id,
    required this.title,
    this.createdAt,
    this.user,
    this.photos = const [],
    this.reactions = const [],
    this.userIsReaction,
  });

  /// dùng khi POST / PUT
  Map<String, dynamic> toJson() => {
        'title': title,
      };

  /// dùng khi GET
  factory PostModel.fromJson(Map<String, dynamic> json) { // tạo thành 1 object mới, refactor thành 1 constructor khác
    return PostModel(
      id: json['post_id'] ?? json['id'],
      title: json['title'] ?? '',
      createdAt: json['created_at'],
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((e) => PhotoModel.fromJson(e))
          .toList(),
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((e) => ReactionCount.fromJson(e))
          .toList(),
      userIsReaction: json['user_is_reaction'],
    );
  }
}
