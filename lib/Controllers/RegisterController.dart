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

  // Mở DatePicker cho ô ngày sinh
  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Định dạng YYYY-MM-DD để gửi lên API
      birth.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

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
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(context, "Đăng ký thành công!, Vui lòng xác thực email");
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(context, _parseErrorMessage(data));
      }
    } catch (e) {
      _showSnackBar(context, "Lỗi kết nối");
    }
  }

  // Xử lý message từ response, kể cả khi lỗi trả về dạng array
  String _parseErrorMessage(Map<String, dynamic> data) {
    if (data.containsKey('message')) {
      return data['message'];
    }

    // Gom tất cả lỗi từ các field thành 1 chuỗi
    final errors = <String>[];
    data.forEach((field, value) {
      if (value is List) {
        errors.add(value.first.toString()); // lấy lỗi đầu tiên của mỗi field
      } else if (value is String) {
        errors.add(value);
      }
    });

    return errors.isNotEmpty ? errors.join('\n') : 'Đăng ký thất bại';
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}