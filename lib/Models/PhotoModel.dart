class PhotoModel { // object lấy ra đối tượng photo
  final int? id;
  final String photo;

  PhotoModel({
    this.id,
    required this.photo,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'],
      photo: json['photo'],
    );
  }
}
