import 'package:flutter/material.dart';
import 'package:my_app/Controllers/LoginController.dart'; // import controller để gọi logic

class ResetPassScreen extends StatefulWidget {
  const ResetPassScreen({super.key});

  @override
  State<ResetPassScreen> createState() => _ResetPassScreenState();
}

class _ResetPassScreenState extends State<ResetPassScreen> {
  final _emailController = TextEditingController(); // theo dõi ô nhập email
  final _formKey = GlobalKey<FormState>(); // dùng để validate form
  final _controller = ResetPassController(); // khởi tạo controller xử lý logic
  bool _isLoading = false; // trạng thái loading khi đang gọi API

  @override
  void dispose() {
    _emailController.dispose(); // giải phóng bộ nhớ khi thoát màn hình
    super.dispose();
  }

  // Hiển thị SnackBar thông báo kết quả (xanh = thành công, đỏ = thất bại)
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error, // icon tương ứng
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)), // nội dung thông báo
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red, // màu theo kết quả
        behavior: SnackBarBehavior.floating, // nổi lên thay vì dính đáy
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Hàm xử lý khi nhấn nút Gửi email
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return; // kiểm tra form trước

    setState(() => _isLoading = true); // bật loading

    // Gọi controller xử lý, nhận về kết quả
    final result = await _controller.handleResetPassword(_emailController.text.trim());

    setState(() => _isLoading = false); // tắt loading

    _showSnackBar(result['message'], result['success']); // hiển thị thông báo

    if (result['success']) {
      // Nếu thành công, đợi 2 giây rồi quay về màn Login
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền gradient giống màn Login cho đồng bộ giao diện
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], // tím → xanh
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // tránh overflow khi bàn phím hiện
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // hiệu ứng kính mờ glassmorphism
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey, // gắn key để validate
                child: Column(
                  mainAxisSize: MainAxisSize.min, // vừa đủ với nội dung
                  crossAxisAlignment: CrossAxisAlignment.stretch, // kéo full ngang
                  children: [
                    // Nút back về màn Login
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context), // quay lại
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Icon đại diện màn hình
                    const Icon(Icons.lock_reset_rounded, size: 60, color: Colors.white),
                    const SizedBox(height: 10),

                    // Tiêu đề
                    const Text(
                      "Quên mật khẩu",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mô tả hướng dẫn
                    const Text(
                      "Nhập email của bạn, chúng tôi sẽ gửi link đặt lại mật khẩu.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 30),

                    // Ô nhập email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress, // bàn phím email
                      style: const TextStyle(color: Colors.white), // màu chữ nhập
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                        // Kiểm tra định dạng email hợp lệ
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nút gửi email
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // nền trắng
                        foregroundColor: const Color(0xFF6A11CB), // chữ tím
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _isLoading ? null : _handleSubmit, // disable khi đang loading
                      child: _isLoading
                          ? const SizedBox( // hiện loading spinner khi đang gọi API
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF6A11CB),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "GỬI EMAIL",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
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
}