import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Views/Screens/profile.dart';

class FriendSuggestScreen extends StatefulWidget {
  const FriendSuggestScreen({super.key});

  @override
  State<FriendSuggestScreen> createState() => _FriendSuggestScreenState();
}

class _FriendSuggestScreenState extends State<FriendSuggestScreen> {
  final UserController _controller = UserController();
  final FriendController _friendController = FriendController(); // gọi controller

  List<UserModel> _users = [];
  bool _loading = false;

  /// ================= SEARCH =================
  Future<void> _search(String name) async { // hàm check có truyền k và gọi controller
    if (name.isEmpty) {
      setState(() => _users = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _controller.searchUser(name);
      setState(() => _users = result);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết bạn'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// ================= SEARCH BOX =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _search, // mỗi lần thay đổi là gọi hàm search và gọi api
              decoration: InputDecoration(
                hintText: 'Tìm bạn theo tên...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// ================= RESULT =================
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Không có kết quả'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final user = _users[i];

                          return ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfileScreen(userId: user.id),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundImage: user.picture != null
                                    ? NetworkImage(user.picture!)
                                    : null,
                                child: user.picture == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            title: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                 await _friendController.sendRequest(user.id!);
                              },
                              child: const Text('Kết bạn'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
