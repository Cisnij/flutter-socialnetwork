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


          final posts = snapshot.data!; // ko lỗi thì lấy ra data
          return RefreshIndicator( // khi vuốt xuống refresh trang sẽ load lại trang
            onRefresh: () async { // gọi lại getfeed bằng async
              setState(() {
                _feedFuture = _controller.getFeed();
              });
            },
            child: ListView.builder( // chỉ load ra ảnh hiện thị trên màn hình đỡ tốn ram
              itemCount: posts.length,
              itemBuilder: (context, index) { 
                return PostItem(post: posts[index]); // build ảnh bằng cách truyền data nhận được qua file PostItem, nó build từng post 1
              },
            ),
          );
        },
      ),
    );
  }
}
