import 'package:flutter/material.dart';
import 'package:my_app/Controllers/PostController.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Views/Screens/post_item.dart';

class FeedScreen extends StatefulWidget { // khai bá statefull vì có dữ liệu thay đổi liên tục
  @override
  State<FeedScreen> createState() => _FeedScreenState(); // hàm của stateful
}

class _FeedScreenState extends State<FeedScreen> {
  final _controller = PostController(); // khai báo controller của post
  late Future<List<PostModel>> _feedFuture; // biến late để gán giá trị sau nhưng chắc chắn sẽ gắn, đây là future chứa list
  List<PostModel> _posts = []; // thêm list local để quản lý UI realtime
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _feedFuture = _controller.getFeed(); // khởi tạo object post model và gán từng thằng con trả về từ gọi controller getfeed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // thanh bar dài phía trên
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none), //icon noti
            onPressed: () {},
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
