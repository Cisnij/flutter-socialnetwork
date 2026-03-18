import 'package:flutter/material.dart';
import 'package:my_app/Views/Screens/feed.dart';
import 'package:my_app/Views/Screens/forgot-pass.dart';
import "package:my_app/Views/register.dart";
import 'package:my_app/Controllers/LoginController.dart';


//logic là chạy giao diện, sau khi ng dùng nhập dữ liệu sẽ dùng globalkey kiểm tra tất cả form,
//nếu tất cả ok thì gọi hàm login() , hàm login se gọi
//controller để lấy dữ liệu và post đi, dữ liệu được lấy thông qua thằng controller luôn, models dùng để chuyển sang json còn service thì gọi api, controller thì gọi model và service

class Login extends StatefulWidget { //Stateful chứa được dữ liệu để lưu username password fetch đi
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final formKey = GlobalKey<FormState>(); //GlobalKey<FormState>(); dùng để validate form, kiểm soát form từ bên ngoài

  // Controller để xử lý logic (lấy dữ liệu + gọi API)
  final controller = LoginController();

  // Biến trạng thái để ẩn/hiện mật khẩu (Thêm mới)
  bool _isObscure = true;

  // hàm login bây giờ CHỈ gọi controller
  Future<void> login() async {
    await controller.startLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //scaffold là màn hình trắng
      // Dùng SingleChildScrollView để khi hiện bàn phím không bị lỗi "overflow"
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient( // chỉnh dải màu nền toàn màn hình
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Giúp cuộn màn hình khi bàn phím hiện lên
            child: Container(
              width: 320, // Tăng nhẹ chiều rộng cho cân đối
              padding: const EdgeInsets.all(25), // căn tất cả giữa trên trái phải 25px
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // tạo hiệu ứng kính mờ (glassmorphism)
                borderRadius: BorderRadius.circular(30), // tạo bo góc 4 bên cho container
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: const [
                  BoxShadow( //shadow
                    color: Colors.black12, // shadow đen
                    blurRadius: 20, // độ mờ bo
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Form(
                key: formKey, //  để chạy validate
                child: Column( // dạng hàng dọc
                  mainAxisSize: MainAxisSize.min, // kéo dài chỉ vừa các thằng con
                  crossAxisAlignment: CrossAxisAlignment.stretch, // kéo rộng chỉ vừa các th con
                  children: [
                    const Icon(Icons.lock_person_rounded, size: 60, color: Colors.white), // Thêm icon cho sinh động
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome Back", // text hiện đầu container
                      textAlign: TextAlign.center, // vào giữa
                      style: TextStyle(
                        color: Colors.white, //trắng
                        fontSize: 26, // độ to chữ
                        fontWeight: FontWeight.w900, // độ đậm
                        letterSpacing: 1.2, // khoảng cách chữ
                      ),
                    ),
                    const SizedBox(height: 30),

                    TextFormField(
                      controller: controller.username,
                      style: const TextStyle(color: Colors.white), // Màu chữ khi nhập
                      decoration: InputDecoration( // ô input
                        hintText: "Email", // text hiện lên
                        hintStyle: const TextStyle(color: Colors.white70), // màu
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        filled: true, // cho phép chỉnh màu
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // hướng
                        border: OutlineInputBorder( // bo tròn
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder( // bo tròn
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), //độ mờ
                        ),
                      ),
                      validator: (value) { //validate
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: controller.password, //controller theo dõi và điều khiển ô input pass
                      obscureText: _isObscure, // hàm theo dõi nếu true thì hiện false thì k hiện
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration( // hàm nhạp
                        hintText: "Password", // hiển thị chữ hiển thị
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70), //icon
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1), // độ mờ màu
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // chỉnh hướng
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15), // bo tròn
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder( // bo tròn ô input
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)), // độ mờ
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off : Icons.visibility, // thay phiên chuyển màn khi nhấn icon
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure; // set true thành false nếu nhấn và ngc lại
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) { // check value inpute
                          return "Vui lòng nhập mật khẩu";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Nút quên mật khẩu nằm góc phải, dưới ô password
                    Align(
                      alignment: Alignment.centerRight, // đẩy sang phải
                      child: GestureDetector( // phát hiện cử chỉ nhấn
                        onTap: () {
                          Navigator.push( // chuyển sang màn hình reset password
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPassScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(
                            color: Colors.white70, // màu trắng mờ cho hòa với nền
                            fontSize: 13,
                            decoration: TextDecoration.underline, // gạch chân
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton( // nút bấm
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Nền trắng chữ màu tím cho nổi bật
                        foregroundColor: const Color(0xFF6A11CB),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15), // bo tròn
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) { // hàm validate dựa vào controller, nếu tất cả các trường ok thì chạy
                          login();
                        }
                      },
                      child: const Text( //text giữ ô
                        "LOGIN",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // độ đậm
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row( // row hàng ngang
                      mainAxisAlignment: MainAxisAlignment.center, // sắp xếp ở giữa
                      children: [
                        const Text(
                          "Chưa có tài khoản? ",
                          style: TextStyle(color: Colors.white70), // màu chữ trắng
                        ),
                        GestureDetector(  // phát hiện cử chỉ
                          onTap: () {
                            Navigator.push( //nhấn sẽ chuyển sang register
                              context,
                              MaterialPageRoute(builder: (context) => const Register()),
                            );
                          },
                          child: const Text(
                            "Đăng ký ngay", // text
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold, // chữ đậm
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override // giải phóng bộ nhớ khi qua màn khác hoặc outapp tránh tràn ram
  void dispose() { // được gọi tự động
    controller.username.dispose();
    controller.password.dispose();
    super.dispose();
  }
}