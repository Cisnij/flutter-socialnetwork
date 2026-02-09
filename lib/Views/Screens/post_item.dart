import 'package:flutter/material.dart';
import 'package:my_app/Controllers/PostController.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Controllers/FunctionController.dart';
import 'package:my_app/Views/Screens/cache.dart';
import 'package:my_app/Views/Screens/comment.dart';
import 'package:my_app/Views/Screens/profile.dart';

class PostItem extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onDelete; // thêm callback để xóa post khỏi UI cha

  /// Gọi controller xử lý like tim...
  final FunctionController _functionController = FunctionController();
  final PostController _postController = PostController();

  PostItem({ //truyền dữ liệu từ home vào
    super.key,
    required this.post,
    this.onDelete,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late PostModel post;

  @override
  void initState() {
    super.initState();
    post = widget.post; // giữ reference để update realtime, widget để lấy ra instance, vì có nhiều post nên phải lấy đúng post đó
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = post.user; // lấy ra user tạo post

    /// Safety check – tránh crash UI
    if (user == null) return const SizedBox();

    /// Tổng reaction (like + love + ...)
    final int totalReactions = post.reactions.fold(
      0,
      (sum, r) => sum + r.total, // lặp từ 0 và cộng vào tới hết
    );
    String _formatDate(String? raw) {
      if (raw == null) return '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return '';

      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 10) {
        return 'Vừa xong';
      }

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds} giây trước';
      }

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} phút trước';
      }

      if (diff.inHours < 24) {
        return '${diff.inHours} giờ trước';
      }

      if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      }

      final weeks = (diff.inDays / 7).floor();
      return '$weeks tuần trước';
    }


    return Card( // dạng card cho post
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // khoảng cách margin card
      elevation: 1.5, // đổ bóng
      shape: RoundedRectangleBorder( // bo góc card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // padding trong card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // căn trái
          children: [

            /// ================= USER HEADER =================
            Row(
              children: [

                /// ---------- AVATAR ----------
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: user.id),
                      ),
                    );
                  },
                  child: CircleAvatar( // ảnh bo tròn
                    radius: 22,
                    backgroundImage: user.picture != null
                        ? NetworkImage(user.picture!) // lấy ra url và load ra ảnh nếu khác null
                        : null,
                    child: user.picture == null
                        ? const Icon(Icons.person) // null thì để icon default
                        : null,
                  ),
                ),

                const SizedBox(width: 10),

                /// ---------- NAME + TIME ----------
                Expanded( // phần mở rộng bên trong row
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // căn trái
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

               /// ---------- MORE ICON ----------          
                if(AppSession.instance.isMe(post.user?.id))                                      
                IconButton(
                  icon: Icon(Icons.more_horiz), //icon 3 chấm setting
                  onPressed: () {
                    _showPostActions(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 10), // xuống dòng

            /// ================= POST TEXT =================
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),

            /// ================= POST IMAGE =================
            if (post.photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  /// CLICK IMAGE → PHÓNG TO
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: EdgeInsets.zero,
                      child: InteractiveViewer( // zoom ảnh
                        child: Image.network(
                          post.photos.first.photo,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    post.photos.first.photo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            /// ================= REACTION COUNT =================
            if (totalReactions > 0) // reaction >0 mới hiện
              Text(
                '$totalReactions reactions',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

            const Divider(height: 20),

            /// ================= ACTION BAR =================
            Row( // cột chứa like tim comment
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                /// ---------- LIKE ----------
                _actionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  label: 'Like',
                  active: post.userIsReaction == 'like',
                  onTap: () async {
                    await _react(context, 'like'); // gọi lại hàm call api mỗi lần nhấn
                  },
                ),

                /// ---------- LOVE ----------
                _actionButton(
                  icon: Icons.favorite_border,
                  label: 'Love',
                  active: post.userIsReaction == 'love',
                  activeColor: Colors.red,
                  onTap: () async {
                    await _react(context, 'love'); // gọi lại hàm call api mỗi lần nhấn
                  },
                ),

                /// ---------- COMMENT ----------
                _actionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  onTap: () {
                    showModalBottomSheet( // tạo khung modal dưới lên 
                      context: context,
                      isScrollControlled: true, // có thể scroll 
                      backgroundColor: Colors.transparent, //background
                      builder: (_) => CommentSheet( postId: post.id!),  // build giao diện load ra cmt bên trong
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Xóa bài viết',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _deletePost(context); // goij hàm xóa
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      await widget._postController.delPost(post.id!);
      widget.onDelete?.call(); // gọi lại xóa post khỏi list trong thằng feed cha và load lại, nếu không null sẽ chạy, null thì k chạy.// Logic là ấn xóa, gọi api xóa, gọi ondelete.call() tới th cha, th cha lấy id post và xóa ui 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bài viết')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa bài viết thất bại ')),
      );
    }
  }

  /// ===============================================================
  /// GỌI API REACT – UPDATE REALTIME
  /// ===============================================================
  Future<void> _react(BuildContext context, String type) async { // hàm bát đồng bộ, build context để show snackbar 
    try {
      final reactionCounts =
          await widget._functionController.reactPost( // gọi controller để gọi api và nhận dữ liệu gán cho reaction count
        post.id!,
        type,
      );

      setState(() {
        post.reactions = reactionCounts; // lấy ra dữ liệu và gán vào post hiện tại

        /// toggle trạng thái user
        if (post.userIsReaction == type) { // nếu có user thả react thì gán k thì thôi
          post.userIsReaction = null;
        } else {
          post.userIsReaction = type;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar( // thanh thông báo nhận resonpse
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  /// ===============================================================
  /// ACTION BUTTON (LIKE / LOVE / COMMENT)
  /// ===============================================================
  Widget _actionButton({ // hàm build button để dùng chug
    required IconData icon, // yêu cầu icon truyền vào
    required String label, // ycau label
    bool active = false,
    Color activeColor = Colors.blue, // màu khi kích hoạt
    required VoidCallback onTap, // ontap chuyển màu
  }) {
    final color = active ? activeColor : Colors.grey;

    return InkWell( // widget tạo hiệu ứng chạm,bắt sự kiện tap
      borderRadius: BorderRadius.circular(6),
      onTap: onTap, // bắt sự kiện ontap
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
