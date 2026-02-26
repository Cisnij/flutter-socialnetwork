import 'package:flutter/material.dart';
import 'package:my_app/Services/FirebaseService.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/addfriend.dart';
import 'package:my_app/Views/Screens/profile.dart';
import 'package:my_app/Views/Screens/incomefriend.dart';
import 'package:my_app/Views/Screens/chat-detail.dart';
import 'feed.dart';
import 'package:my_app/Views/Screens/cache.dart';

class MainScreen extends StatefulWidget { // thanh navigationbar
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState(); 
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _sessionReady = false; // xử lý trạng thái session
  late final List<Widget> _screens; // khai báo list screen

  
  @override
  void initState() {
    super.initState();
    _initSession(); // khởi tạo lưu cache
  }
  

  Future<void> _initSession() async {
    await AppSession.instance.init();
    if (mounted) { // nếu đã có widget 
      setState(() {
        _sessionReady = true; //
        _screens = [
          FeedScreen(),
          FriendSuggestScreen(),
          RequestsScreen(),
          ProfileScreen(),
          ChatTabScreen(),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!_sessionReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: IndexedStack( // giữ state các screen
        index: _currentIndex, // nhận vào index hiện tại nhận vào
        children: _screens, // từ cái index load ra cái screen đó tương ứng
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) { // tap vào đâu sẽ load tương ứng screen đó
          setState(() {
            _currentIndex = index; // đặt index khi click và đặt thành current
          });
        },
        type: BottomNavigationBarType.fixed, // cố định khi scroll
        items: const [ // các item và icon tương ứng
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}
