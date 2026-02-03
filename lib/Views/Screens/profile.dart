import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/post_item.dart';

class ProfileScreen extends StatefulWidget {
  /// null  → profile của mình
  /// != null → profile user khác
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserController _controller = UserController();
  final  _friendController =FriendController();

  late Future<UserModel> _userFuture;
  late Future<List<PostModel>> _postFuture;

  bool get isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();

    if (isMyProfile) {
      /// ========== PROFILE CỦA MÌNH ==========
      _userFuture = _controller.userInfo();
      _postFuture = _userFuture.then(
        (user) => _controller.userPosts(user.id!),
      );
    } else {
      /// ========== PROFILE USER KHÁC ==========
      _userFuture = _controller.viewPage(widget.userId!);
      _postFuture = _controller.userPosts(widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Profile' : 'User Profile'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await TokenStorage.clear();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture,
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnap.hasError) {
            return Center(
              child: Text('Lỗi tải profile: ${userSnap.error}'),
            );
          }

          final user = userSnap.data!;

          return Column(
            children: [
              const SizedBox(height: 20),

              /// ================= AVATAR =================
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    user.picture != null ? NetworkImage(user.picture!) : null,
                child: user.picture == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),

              const SizedBox(height: 10),

              /// ================= NAME =================
              Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              /// ================= BIO =================
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  user.bio!,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],

              /// ================= ACTION =================
              if (!isMyProfile) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _friendController.sendRequest(user.id!);
                  },
                  child: const Text('Add Friend'),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),

              /// ================= POST LIST =================
              Expanded(
                child: FutureBuilder<List<PostModel>>(
                  future: _postFuture,
                  builder: (_, postSnap) {
                    if (postSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (postSnap.hasError) {
                      return Center(
                        child: Text('Lỗi tải bài viết'),
                      );
                    }

                    final posts = postSnap.data!;
                    if (posts.isEmpty) {
                      return const Center(
                        child: Text('Chưa có bài viết'),
                      );
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (_, i) =>
                          PostItem(post: posts[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
