import 'package:flutter/material.dart';
import 'package:my_app/Controllers/RegisterController.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>(); // validate all form validate trước khi gọi api
  final controller = RegisterController(); //gọi controller

  bool _hidePass1 = true; // đặt ẩn mật khẩu bằng true
  bool _hidePass2 = true;

  @override
  Widget build(BuildContext context) { // hàm này dùng gọi mỗi khi cần build lại giao diện
    final size = MediaQuery.of(context).size; // lấy ra kích thước size của màn hình điện thoại đó

    return Scaffold(
      body: Container( // contain bên ngoài
        width: size.width, // giá trị size full màn theo đt
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // có thể scroll khi bàn phím bật lên
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card( //card chưas form
              elevation: 20, // đổ bóng
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // màn hình bo góc
              ),
              child: Padding(
                padding: const EdgeInsets.all(24), // đặt left right top bottom là 24 px
                child: Form( // trong card chứa form
                  key: _formKey, // chạy validate
                  child: Column( // dạng hàng để chứa các phần tử con theo hàng
                    mainAxisSize: MainAxisSize.min, // hộp co giãn chỉ đủ chứa đủ các phần tử con
                    children: [
                      const Icon(Icons.person_add_alt_1,
                          size: 60, color: Color(0xFF6A11CB)),
                      const SizedBox(height: 10), // xuống dòng
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _input(
                        label: "First name",
                        icon: Icons.person,
                        controller: controller.firstName,
                        validator: (v) => // v là value
                            v!.isEmpty ? "Enter first name" : null, // v khác is empy thì enterfirstname else null
                      ),

                      _input(
                        label: "Last name",
                        icon: Icons.person_outline,
                        controller: controller.lastName,
                        validator: (v) =>
                            v!.isEmpty ? "Enter last name" : null,
                      ),

                      _input(
                        label: "Email",
                        icon: Icons.email,
                        controller: controller.email,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) =>
                            v!.isEmpty ? "Enter email" : null,
                      ),

                      _input(
                        label: "Phone",
                        icon: Icons.phone,
                        controller: controller.phone,
                        keyboard: TextInputType.phone,
                        validator: (v) =>
                            v!.isEmpty ? "Enter phone number" : null,
                      ),

                      _input(
                        label: "Date of birth",
                        icon: Icons.cake,
                        controller: controller.birth,
                        readOnly: true, // không cho nhập tay
                        onTap: () => controller.pickBirthDate(context), // mở DatePicker
                      ),

                      _input(
                        label: "Password",
                        icon: Icons.lock,
                        controller: controller.pass1,
                        obscure: _hidePass1,
                        suffix: IconButton(
                          icon: Icon(_hidePass1 // if hidepass =true thì hiện else thì ẩn
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePass1 = !_hidePass1), // build lại widget này nếu nhấn xem mật khẩu
                        ),
                        validator: (v) =>
                            v!.isEmpty ? "Enter password" : null,
                      ),

                      _input(
                        label: "Confirm password",
                        icon: Icons.lock_outline,
                        controller: controller.pass2,
                        obscure: _hidePass2,
                        suffix: IconButton(
                          icon: Icon(_hidePass2
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePass2 = !_hidePass2),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return "Confirm password";
                          if (v != controller.pass1.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      SizedBox( // tạo box
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton( // nút bấm
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder( //bo tròn
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero, // không thụt padding nữa
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) { // dùng validate tất cả thằng cần validate, đúng hết mới start regis
                              controller.startRegister(context);
                            }
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6A11CB),
                                  Color(0xFF2575FC)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'), //chuyển hướng login nếu nhấn login
                        child: const Text("Already have an account? Login"),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({ // hàm tái sử dụng nhanh gọn
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    bool readOnly = false,          // không cho nhập tay (dùng cho DatePicker)
    VoidCallback? onTap,            // callback khi tap vào field
    TextInputType keyboard = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        readOnly: readOnly,          // không cho nhập tay
        onTap: onTap,                // mở DatePicker khi tap
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { // hàm loại bỏ
    controller.firstName.dispose();
    controller.lastName.dispose();
    controller.email.dispose();
    controller.phone.dispose();
    controller.birth.dispose();
    controller.pass1.dispose();
    controller.pass2.dispose();
    super.dispose();
  }
}