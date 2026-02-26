class UserModel {
  final int? id;

  String? firstName;
  String? lastName;
  String? bio; // ? là có thể null
  String? picture;
  String? phoneNumber;
  DateTime? dateOfBirth;

  UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    this.bio,
    this.picture,
    this.phoneNumber,
    this.dateOfBirth,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) { //nhận về và gán vào object
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      bio: json['bio'],
      picture: json['picture'],
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth']) // khác null thì chuyển sang dạng date time
          : null,
    );
  }

  Map<String, dynamic> toJson() { //chuyển sang Json
    return {
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,// chuyển thành ngày tháng năm
    };
  }
}
