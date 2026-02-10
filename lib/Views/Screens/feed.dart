import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/Controllers/FunctionController.dart';
import 'package:my_app/Controllers/PostController.dart';
import 'package:my_app/Controllers/themeController.dart';
import 'package:my_app/Models/FunctionModel.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Views/Screens/post_item.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget { // khai bá statefull vì có dữ liệu thay đổi liên tục
  @override
  State<FeedScreen> createState() => _FeedScreenState(); // hàm của stateful
}

class _FeedScreenState extends State<FeedScreen> {
  final _controller = PostController(); // khai báo controller của post
  final _functionController = FunctionController();
  late Future<List<PostModel>> _feedFuture; // biến late để gán giá trị sau nhưng chắc chắn sẽ gắn, đây là future chứa list
  List<PostModel> _posts = []; // thêm list local để quản lý UI realtime
  bool _initialized = false; 
  // THÊM POST
  final TextEditingController _postController = TextEditingController();
  bool _posting = false;
  List<File> _selectedImages = [];


  // === NOTIFICATION ADD ===
  List<InAppNotification> _notis = [];

      String _formatDate(String? raw) { //parse thời gian
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
  void initState() {
    super.initState();
    _feedFuture = _controller.getFeed(); // khởi tạo object post model và gán từng thằng con trả về từ gọi controller getfeed
    _loadNoti(); //gọi hàm 
  }

  // THÊM POST
  Future<void> _pickImages() async { // hàm chọn ảnh từ thiết bị 
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files != null) {
      setState(() {
        _selectedImages = files.map((e) => File(e.path)).toList();
      });
    }
  }
  void _openCreatePost() { // hàm mở dialog khung chọn ảnh 
  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('Tạo bài viết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _postController, // gọi controller control text
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.file(
                      _selectedImages[i],
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            TextButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Chọn ảnh'),
              onPressed: _pickImages, // nhấn icon sẽ chọn ảnh
            ),
          ],
        ),
        actions: [
          TextButton( // nút hủy hết dữ liệu và đóng 
            onPressed: () {
              _postController.clear();
              _selectedImages.clear();
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton( // nút gọi controller tạo post, 
            onPressed: _posting ? null : _submitPost,
            child: _posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng'),
          ),
        ],
      );
    },
  );
}
Future<void> _submitPost() async { // hàm gọi controller submit 
  final text = _postController.text.trim();
  if (text.isEmpty && _selectedImages.isEmpty) return;

  setState(() => _posting = true); // bật trạng thái đang đăng để disable nút và show loading

  try {
    final post = await _controller.createPost( // gọi troller truyền vào file 
      title: text,
      images: _selectedImages,
    );

    setState(() { // thành công thì load lại trang 
      _posts.insert(0, post); // thêm vào list post mới ở vị trí 0
      _postController.clear(); // xóa hết text và ảnh 
      _selectedImages.clear();
    });

    Navigator.pop(context); // đóng khung
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())), // báo lỗi nếu có res
    );
  } finally {
    setState(() => _posting = false);
  }
}



  // === NOTIFICATION ADD ===
  Future<void> _loadNoti() async {
    try {
      final data = await _functionController.noti(); // gọi controller lấy noti
      setState(() {
        _notis = data; // gán data vào list
      });
    } catch (_) {}
  }
  void _showNoti() {
    showModalBottomSheet( // mở ô bên dưới 
      context: context,
      isScrollControlled: true, // cho phép scroll 
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // chiều cao theo màn hình
          child: _notis.isEmpty
              ? const Center(child: Text('Không có thông báo')) //nếu list rỗng thì hiển thị ko có thông báo
              : ListView.builder( //có thì build ra
                  itemCount: _notis.length,
                  itemBuilder: (context, index) {
                    final noti = _notis[index];
                    return ListTile(
                      leading: Icon(
                        noti.verb == 'reacted' // nếu verb là react thì icon là trái tim 
                            ? Icons.favorite
                            : Icons.add,
                        color: noti.verb == 'reacted' // màu là đỏ nếu là react
                            ? Colors.red
                            : Colors.blue,
                      ),
                      title: Text(noti.displayText),
                      subtitle: Text(
                        _formatDate(noti.created_at ?? ''), // hiển thị thgian 
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: mở post theo post_id
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // thanh bar dài phía trên
        title: Text('Home'),
        actions: [          
         IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark // giá trị khi nhấn sẽ chuyển icon
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              context.read<ThemeController>().toggleTheme(); // nút gọn controller chuyển tối sáng
            },
          ),

          // === NOTIFICATION ADD ===
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none), //icon noti
                onPressed: _showNoti, // bám vào icon sẽ chạy hàm shownoti
              ),
              if (_notis.isNotEmpty) // nếu list rỗng thì không hiển thị gì
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _notis.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreatePost,
          ),
        ],
      ),
      body: FutureBuilder<List<PostModel>>( // widget xây dựng giao diện dựa trên kết quả trả về của future ở đây là postmodel ,nếu nó trả về dữ liệu qua postmodel sẽ load ra
        future: _feedFuture, // theo dõi _feedfuture trên lấy ra trạng thái, nếu có dữ liệu sau khi gán  thì chạy
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) { // trạng thái đang lấy ra thì load
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) { // bắt lỗi khi mà token hết hạn sẽ báo SESSION_EXPIRED, cái này bắt lỗi đó và bắt login lại
            if (snapshot.error.toString().contains('SESSION_EXPIRED')) { // nếu có chứa SESSION_EXPIRED
              WidgetsBinding.instance.addPostFrameCallback((_) { //build xong báo lỗi mới đc redirect, đang build mà redirect sẽ báo lỗi 
                Navigator.pushNamedAndRemoveUntil( // push kh thể quay lại
                  context,
                  '/login',
                  (_) => false,
                );
              });

              return const Center(child: CircularProgressIndicator());
            }

            return const Center(child: Text('Lỗi load feed'));
          }

           if (!_initialized) {
            _posts = List.from(snapshot.data!); // để snapshot gán lại data mỗi khi refresh, vì mặc định khi đc gọi snapshot data vẫn còn cũ
            _initialized = true;
          }

          return RefreshIndicator( // khi vuốt xuống refresh trang sẽ load lại trang
            onRefresh: () async { // gọi lại getfeed bằng async
              final data = await _controller.getFeed();
              setState(() {
                _posts = data;
                _feedFuture = Future.value(data);
              });
              await _loadNoti(); // === NOTIFICATION ADD ===
            },
            child: ListView.builder( // chỉ load ra ảnh hiện thị trên màn hình đỡ tốn ram
              itemCount: _posts.length,
              itemBuilder: (context, index) { 
                final post = _posts[index];
                return PostItem(
                  key: ValueKey(post.id), // gán key cho từng post
                  post: post,
                  onDelete: () {
                    setState(() {
                      _posts.removeWhere((p) => p.id == post.id); // khi nhấn delete, sẽ lấy id của post đó và gọi hàm có sẵn // Nó gắn chặt với thằng con nên chỉ cần gọi deletecall sẽ tự động gọi tới hàm này 
                    });
                  },
                ); // build ảnh bằng cách truyền data nhận được qua file PostItem, nó build từng post 1
              },
            ),
          );
        },
      ),
    );
  }
}
