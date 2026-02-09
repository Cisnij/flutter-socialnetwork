import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/Services/LoginService.dart';
import 'package:my_app/Models/LoginModel.dart';
import 'package:my_app/Services/TokenStorage.dart';
import "package:my_app/Views/Screens/feed.dart";
import 'package:my_app/Views/Screens/home.dart';
import 'package:my_app/Services/FirebaseService.dart';
class LoginController {

    String parseErrorMessage(dynamic data) { // hàm chuyển các response không rõ thành message
    if (data is Map<String, dynamic>) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String) {
          return value;
        }
      }
    }
    return 'Có lỗi xảy ra';
  }

  // View sẽ dùng các Controller này
  final username = TextEditingController(); // láy ra input ng dùng nhập, chỉ dùng khi nhập không dùng khi nhấn react...
  final password = TextEditingController();


  final _service = LoginService(); // goi service
  bool isLoading= false;

  Future<void> startLogin(BuildContext context) async { //dùng build context để chạy navigator, showsnackbar vì nó cần hiểu ngữ cảnh của trang
    final model = LoginModel( //goi model
      username: username.text,
      password: password.text,
    );

    // Controller đưa dữ liệu vào Service để gọi API
    try {
      isLoading =true;
      final response = await _service.sendRequest(model.toJson());
      // 3. Controller nhận Response và báo cho View load lại
      if (response.statusCode == 200 || response.statusCode== 201) {
        _showSnackBar(context, "Thành công!");
        final data= jsonDecode(response.body);
        await TokenStorage.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
        );
        FirebaseService.init(); // khởi tạo firebase
        await TokenStorage.saveId(id: data['user']['pk'].toString());
        isLoading=false;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainScreen()));
      } 
      else {
        final data = jsonDecode(response.body);
        final msg = parseErrorMessage(data);
        _showSnackBar(context, msg);
      }
    } catch (e) {
      _showSnackBar(context, "Lỗi kết nối");
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
