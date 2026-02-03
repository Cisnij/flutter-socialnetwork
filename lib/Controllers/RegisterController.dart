import 'package:flutter/material.dart';
import 'package:my_app/Services/RegisterService.dart';
import 'package:my_app/Models/RegisterModel.dart';
import 'dart:convert';
class RegisterController {
  // View sẽ dùng các Controller này
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final birth = TextEditingController();
  final pass1 = TextEditingController();
  final pass2 = TextEditingController();

  final _service = RegisterService(); // goi service

  Future<void> startRegister(BuildContext context) async {
    // 1. Controller lấy dữ liệu từ View và đưa vào Model
    final model = RegisterModel(
      first_name: firstName.text,
      last_name: lastName.text,
      email: email.text,
      phone: phone.text,
      birth: birth.text,
      pass1: pass1.text,
      pass2: pass2.text,
    );

    // 2. Controller đưa dữ liệu vào Service để gọi API
    try {
      final response = await _service.sendRequest(model.toJson());
      if (!context.mounted) return; // không build context sau await
      // 3. Controller nhận Response và báo cho View load lại
      if (response.statusCode == 200) {
        _showSnackBar(context, "Thành công!");
        Navigator.pushReplacementNamed(context, '/login');
      } else {
      final data  = jsonDecode(response.body);
        _showSnackBar(context, data['message']?? 'Thất bại');// lấy lỗi từ response
      }
    } catch (e) {
      _showSnackBar(context, "Lỗi kết nối");
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
