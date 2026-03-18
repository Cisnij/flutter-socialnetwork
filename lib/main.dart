import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_app/Controllers/themeController.dart';
import 'package:my_app/Services/FirebaseService.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/home.dart';
import 'package:my_app/Views/login.dart';
import 'package:my_app/Views/Screens/feed.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // đảm bảo flutter đã khởi tạo xong

  await Firebase.initializeApp(); // hàm khởi tạo firebase
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {// app đang mở → tự show bằng local notification hoặc snackbar
    print("📩 Foreground message: ${message.notification?.title}");
  });


  runApp(
    ChangeNotifierProvider( // cung cấp theme sáng tối  cho toàn app
      create: (_) => ThemeController(), // khởi tạo controller 
      child: const MyApp(),
    ),
  );

}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>(); // lắng nghe sự thay đổi theme để đổi theo 
    return MaterialApp(
      debugShowCheckedModeBanner: false, // xóa thanh debug bar 

      themeMode: theme.themeMode, // chuyển theme toàn màn hình
      // LIGHT
      theme: ThemeData( // định nghĩa theme
        brightness: Brightness.light, 
      ),
      // DARK
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),

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
