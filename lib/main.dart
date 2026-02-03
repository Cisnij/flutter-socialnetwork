import 'package:flutter/material.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/home.dart';
import 'package:my_app/Views/login.dart';
import 'package:my_app/Views/Screens/feed.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: FutureBuilder<bool>( // home dạng future, dùng gọi hàm checkLogin trả ra bool
        future: TokenStorage.checkLogin(), // check access token, lấy ra trạng thái là snapshot để xem có tồn tại k
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { // đang load future
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) { 
            return MainScreen(); // có access thì về trang home
          }

          return const Login(); // không có access thì về login
        },
      ),

      routes: { // route dùng để sau này gọi push chỉ cần gọi tên như là /login mà kh cần khai báo thư viện
        '/login': (context) => const Login(), 
        '/home': (context) => MainScreen(),
      },
    );
  }
}
