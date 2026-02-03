//chuyển sang json
class LoginModel{
  final String username, password;
  LoginModel({required this.username, required this.password}); 

  Map<String, dynamic> toJson()=>{ // hàm custome chuyển thành json
    'email':username,
    'password':password,
  };
}
