import 'package:my_app/Models/UserModel.dart';

class ReactModel{ // chuyển sang json
  final String type;
  ReactModel({required this.type});
  Map<String, dynamic> toJson()=>{
    'reaction_type': type
  };
  
}

class ReactionCount { // nhận res đếm count
  final String name;
  final int total;

  ReactionCount({
    required this.name,
    required this.total,
  });

  factory ReactionCount.fromJson(Map<String, dynamic> json) {
    return ReactionCount(
      name: json['settings__name'],
      total: json['total'],
    );
  }
}

class CommentModel {
  final int? id;
  final String content;
  final UserModel? user;
  final String? createdAt;
  
  CommentModel({this.id, required this.content, this.user, this.createdAt});
  
  Map<String, dynamic> toJSon()=>{
    'content': content
  };

  factory CommentModel.fromJson(Map<String, dynamic> json)
  {
    return CommentModel(
      id: json['id'],
      content: json['content'],
      user: json['user'] != null
          ? UserModel.fromJson(json['user']) //parse user json, vì user chứa nhiều trường 
          : null,
      createdAt: json['created_at']
    );
  }
}
class InAppNotification{
  int? id;
  String? actor;
  String? verb;
  int? post_id;
  String? created_at;

  InAppNotification({
    this.id,
    this.actor,
    this.verb,
    this.post_id,
    this.created_at,
  });
  
  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'],
      actor: json['actor'],
      verb: json['verb'],
      post_id: json['post_id'],
      created_at: json['created_at'],
    );
  }
  String get displayText {
    switch (verb) {
      case 'reacted':
        return '$actor đã react bài viết của bạn';
      case 'commented':
        return '$actor đã bình luận bài viết của bạn';
      default:
        return '$actor có hoạt động mới';
    }
  }
}
