import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FunctionController.dart';
import 'package:my_app/Models/FunctionModel.dart';
import 'package:my_app/Views/Screens/cache.dart';

class CommentSheet extends StatefulWidget {
  final int postId;

  const CommentSheet({
    super.key,
    required this.postId, // constructor nhận vào id
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final FunctionController _commentController = FunctionController(); // khai báo controller gọi api
  final TextEditingController _textController = TextEditingController();

  List<CommentModel> _comments = []; // khơi tạo list
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments(); // hàm khởi tạo
  }

  /// ===============================================================
  /// LOAD COMMENT THEO POST
  /// ===============================================================
  Future<void> _loadComments() async { 
    try {
      final data = await _commentController.listComment(widget.postId); // gọi hàm list truyền id instance
      setState(() {
        _comments = data; // thêm data vào mảng
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không load được comment')), //lỗi
      );
    } finally {
      setState(() {
        _isLoading = false; // gọi hàm thêm và ngừng quay
      });
    }
  }

  /// ===============================================================
  /// SEND COMMENT
  /// ===============================================================
  Future<void> _sendComment() async { // hàm gọi api create cmt
    final text = _textController.text.trim(); // lấy ra text
    if (text.isEmpty || _isSending) return; // k có text return

    setState(() => _isSending = true); // khởi tạo isSending đc gọi là true

    try {
      final newComment =
          await _commentController.createComment(widget.postId, text); // gọi api create

      setState(() {
        _comments.insert(0, newComment); // giống FB, insert vào đầu lúc vừa comment
        _textController.clear(); // xóa text trong box
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi comment thất bại')),
      );
    } finally {
      setState(() => _isSending = false);// kết thúc khởi tạo gọi false
    }
  }

  /// DELETE COMMENT (CHỈ OWNER)
  Future<void> _deleteComment(int commentId) async { // hàm xóa comment
    final ok = await _commentController.delComment(commentId);

    if (ok) {
      setState(() {
        _comments.removeWhere((c) => c.id == commentId); // catch event xóa
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa comment thất bại')),
      );
    }
  }

  /// FORMAT DATE
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // lấy chiều cao bàn phím 

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset), //thêm padding dưới
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75, // container sẽ co giãn độ cao khi bật/tắt phím
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)), //bo tròn hộp 
        ),
        child: Column( // dạng column
          children: [

            /// ================= HEADER =================
            Padding(
              padding: const EdgeInsets.all(12), //padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // khoảng cách 2 bên, cách ở giữa
                children: [
                  Text(
                    'Comments · ${_comments.length}',  // độ dài của list khi load
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context), // icon close bấm thoát
                  ),
                ],
              ),
            ),

            const Divider(height: 1), 

            /// ================= LIST COMMENT =================
            Expanded( // vùng chiếm hết của column
              child: _isLoading // nếu loading true thì load thanh xoay
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty // load mà k có dữ liệu trong list thì in ra chữ
                      ? const Center(
                          child: Text(
                            'Chưa có comment nào',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder( // build dạng list theo độ dài list
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (_, index) {
                            final c = _comments[index];
                            final u = c.user;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6), //padding
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start, //bắt đầu ngoài cùng đi vào
                                children: [
                                  CircleAvatar( //load ava
                                    radius: 18,
                                    backgroundImage: u?.picture != null
                                        ? NetworkImage(u!.picture!)
                                        : null,
                                    child: u?.picture == null
                                        ? const Icon(Icons.person, size: 18)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [

                                          /// ===== NAME + TIME + ACTION =====
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${u?.firstName ?? ''} ${u?.lastName ?? ''}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    _formatDate(c.createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),

                                                  /// ===== ONLY OWNER SEE ⋮ =====
                                                  if (AppSession.instance
                                                      .isMe(c.user?.id))
                                                    PopupMenuButton<String>( // menu chọn
                                                      padding: EdgeInsets.zero,
                                                      onSelected: (value) { // chọn giá trị
                                                        if (value == 'delete') {
                                                          _deleteComment(
                                                              c.id!);
                                                        }
                                                      },
                                                      itemBuilder: (_) => [
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Text(
                                                            'Xóa',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                        ),
                                                      ],
                                                      icon: const Icon(
                                                        Icons.more_horiz,
                                                        size: 16,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 4),
                                          Text(c.content),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            /// ================= Ô INPUT =================
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField( // dạng text field
                        controller: _textController, // controller kiểm soát ô text này
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendComment(), // nút submit gọi hàm
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận...', //text
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
