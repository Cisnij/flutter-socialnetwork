import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Views/Screens/profile.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _controller = FriendController();
  
  // Khởi tạo mảng rỗng để tránh lỗi 'isEmpty' trên biến undefined
  List<dynamic> _listRequests = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Hàm lấy dữ liệu từ API
  Future<void> _fetchData() async {
    try {
      final data = await _controller.incomeRequest();
      if (mounted) {
        setState(() {
          _listRequests = data ?? []; // Chống null
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi tải dữ liệu: $e");
    }
  }

  /// ================= XỬ LÝ CHẤP NHẬN (NHẤN LÀ MẤT LUÔN) =================
  Future<void> _handleAccept(dynamic requestId) async {
    // 1. Thực hiện xóa trên giao diện NGAY LẬP TỨC (Optimistic UI)
    // Người dùng sẽ thấy dòng đó biến mất ngay khi vừa chạm tay vào nút
    setState(() {
      _listRequests.removeWhere((item) => item['id'] == requestId);
    });

    // 2. Gọi API chạy ngầm bên dưới
    try {
      final ok = await _controller.acceptRequest(requestId);
      
      if (!ok && mounted) {
        // Nếu API thất bại, báo lỗi và có thể load lại danh sách để hoàn tác
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn thành công')),
        );
        _fetchData(); 
      }
    } catch (e) {
      if (mounted) _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) // Đang load ban đầu
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: _listRequests.isEmpty 
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 300, 
                        child: Center(child: Text('Không có lời mời nào')),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _listRequests.length,
                    itemBuilder: (context, i) {
                      final request = _listRequests[i];
                      final sender = request['sender'];

                      return ListTile(
                        // Cực kỳ quan trọng: Dùng ID làm Key để Flutter xóa đúng dòng
                        key: ValueKey('request_${request['id']}'), 
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(userId: sender['id']),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: sender['picture'] != null
                                ? NetworkImage(sender['picture'])
                                : null,
                            child: sender['picture'] == null 
                                ? const Icon(Icons.person) 
                                : null,
                          ),
                        ),
                        title: Text(
                          '${sender['first_name']} ${sender['last_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Gửi lúc: ${request['created']}'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _handleAccept(request['id']),
                          child: const Text('Accept'),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}