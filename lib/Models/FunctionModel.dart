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
