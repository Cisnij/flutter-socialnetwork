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

  // Date format 
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

  void _openCreatePost() { // hàm mở dialog khung chọn ảnh 
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder( // StatefulBuilder tạo setState riêng cho dialog
          builder: (context, setDialogState) { // setDialogState chỉ rebuild bên trong dialog
            return AlertDialog(
              title: const Text('Tạo bài viết'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // co lại vừa đủ không chiếm hết không gian bên trong column
                children: [
                  TextField(
                    controller: _postController, // gọi controller control text
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Bạn đang nghĩ gì?',
                      border: OutlineInputBorder(), // chỉ có viền không có màu trong suốt
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_selectedImages.isNotEmpty) // nếu không đang trạng thái chỉnh ảnh 
                    SizedBox( // giới hạn kích thước th con
                      height: 80, // giới hạn chiều cao 80px
                      width: double.maxFinite, // ← báo cho Flutter biết chiều rộng tối đa, tránh lỗi layout khi ListView nằm trong Column của dialog
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // cuộn ngang thay vì dọc 
                        itemCount: _selectedImages.length,
                        itemBuilder: (_, i) => Padding( // build ra từng ảnh của th con có khoảng cách
                          padding: const EdgeInsets.only(right: 8), //margin
                          child: Image.file( // hiển thị file ảnh cục bộ của i trong n ảnh
                            _selectedImages[i],
                            width: 80, // chiều rộng 80px
                            fit: BoxFit.cover, // lấp đầy , phần thừa bị cắt 
                          ),
                        ),
                      ),
                    ),

                  TextButton.icon( // button chứa text 
                    icon: const Icon(Icons.photo),
                    label: const Text('Chọn ảnh'),
                    onPressed: () async { // inline async để dùng được setDialogState
                      final picker = ImagePicker();
                      final files = await picker.pickMultiImage(imageQuality: 80); // hàm picket lấy nhiều ảnh
                      if (files != null && files.isNotEmpty) {
                        setDialogState(() { // ← phải dùng setDialogState thay vì setState
                          // setState() → rebuild FeedScreen → dialog không thấy
                          // setDialogState() → rebuild dialog → ảnh hiển thị ngay ✅
                          _selectedImages = files.map((e) => File(e.path)).toList(); // đưa vào parse sang list
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton( // nút hủy hết dữ liệu và đóng 
                  onPressed: () {
                    _postController.clear();
                    setDialogState(() => _selectedImages.clear()); // dùng setDialogState để clear ảnh preview
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton( // nút gọi controller tạo post
                  onPressed: _posting ? null : () => _submitPost(setDialogState), // ← truyền setDialogState vào để dialog biết trạng thái loading
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
      },
    );
  }

  Future<void> _submitPost(StateSetter setDialogState) async { // hàm gọi controller submit, nhận setDialogState để cập nhật dialog
    final text = _postController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    // cập nhật cả 2 để dialog biết đang loading, tránh nhấn nhiều lần gây conflict
    setDialogState(() => _posting = true);
    setState(() => _posting = true);

    try {
      final post = await _controller.createPost( // gọi troller truyền vào file 
        title: text,
        images: _selectedImages,
      );

      setState(() { // thành công tạo bài post mới thì load lại trang 
        _posts.insert(0, post); // thêm vào list post mới ở vị trí 0
        _postController.clear(); // xóa hết text và ảnh 
        _selectedImages.clear();
      });

      if (mounted) Navigator.pop(context); // check mounted trước khi pop tránh lỗi khi widget đã bị dispose

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())), // báo lỗi nếu có res
        );
      }
    } finally {
      if (mounted) {
        setDialogState(() => _posting = false); // tắt loading ở dialog
        setState(() => _posting = false); // tắt loading ở feedscreen
      }
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
                        noti.type == 'reacted' // nếu verb là react thì icon là trái tim 
                            ? Icons.favorite
                            : Icons.add,
                        color: noti.type == 'reacted' // màu là đỏ nếu là react
                            ? Colors.red
                            : Colors.blue,
                      ),
                      title: Text(noti.displayText),
                      subtitle: Text(
                        _formatDate(noti.createdAt ?? ''), // hiển thị thgian 
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