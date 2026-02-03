import 'package:flutter/material.dart';
import 'package:my_app/Views/Screens/feed.dart';
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

  // hàm login bây giờ CHỈ gọi controller
  Future<void> login() async {
    await controller.startLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //scaffold là màn hình trắng
      backgroundColor: Colors.deepPurple[200],
      body: Center( // center là đưa tất cả vào giữa
        child: Container( //tạo 1 con hình ô có thể chứa
          width: 300,
          padding: EdgeInsets.all(20), // căn tất cả giữa trên trái phải 20px
          decoration: BoxDecoration( // chỉnh sửa dạng box
            gradient: LinearGradient( // chỉnh dải màu
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // Màu tím xanh hiện đại
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15, // độ mờ
                offset: Offset(0, 10), // độ lệch
              )
            ],
            borderRadius: BorderRadius.circular(20), // tạo bo góc 4 bên cho container
          ),
          child: Form( //tạo dạng form
            key: formKey, //  để chạy validate
            child: Column( // tạo column để có thể chứa các thành phần con, trong form là các children
              mainAxisSize: MainAxisSize.min, // tạo chiều cao tự động vừa đủ tối thiểu để chứa các thằng con
              crossAxisAlignment: CrossAxisAlignment.stretch, // ép các thằng con rộng vừa đủ width của container cha
              children: [
                const Text( // ô Text thằng con 1 của colum
                  "Login",
                  textAlign: TextAlign.center, //căn giữa
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20), // xuống dòng 20px để cách các trường con ra

                TextFormField( //Form để có thể validate
                  controller: controller.username, // lấy dữ liệu từ controller
                  decoration: const InputDecoration( // trang trí ô nhập
                    hintText: "Email",
                    filled: true, //filled là có cho phép tô màu
                    fillColor: Colors.white,
                    border: OutlineInputBorder(), // viền khung nhập
                  ),
                  validator: (value) { // thuộc text form field để lấy dữ liệu và ktra
                    if (value == null || value.isEmpty) { // value là giá trị nhập vào để th textformfield ktra
                      return 'Vui lòng nhập email'; // return này sẽ hiện thị ở dưới ô nhập luôn mà k cần decor
                    }
                    return null; // null là hợp lệ, string là lỗi
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: controller.password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    border: UnderlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Vui lòng nhập mật khẩu";
                    }
                    // if(value.length <6){
                    //   return "Mật khẩu phải có ít nhất 6 kí tự";
                    // }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Login"),
                  onPressed: () {
                    if (formKey.currentState!.validate()) { 
                      // dùng globalkey để ktra toàn bộ form,
                      // logic là nếu tất cả các trường đều hợp lệ thì mới cho phép login
                      login();
                    }
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản ",
                      style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                    ),
                    GestureDetector( // dùng để bắt sự kiện ng dùng như nhấn hay đè
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Register()),
                        ); // chuyển sang trang regis không quay lại
                      },
                      child: Text(
                        "Đăng kí",
                        style: TextStyle(color: Color.fromARGB(255, 250, 0, 0)),
                      ),
                    ),
                  ],
                ),
              ],
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
