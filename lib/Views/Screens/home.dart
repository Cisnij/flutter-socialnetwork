import 'package:flutter/material.dart';
import 'package:my_app/Views/Screens/addfriend.dart';
import 'package:my_app/Views/Screens/profile.dart';
import 'package:my_app/Views/Screens/incomefriend.dart';
import 'feed.dart';

class MainScreen extends StatefulWidget { // thanh navigationbar
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [  // list các screen
    FeedScreen(),           // feed
    FriendSuggestScreen(),  // Kết bạn
    RequestsScreen(), // Lời mời
    ProfileScreen(),  // Cá nhân 
  ];

  @override
  Widget build(BuildContext context) {
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
        items: const [
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
        ],
      ),
    );
  }
}
