import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Views/Screens/profile.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

// hàm parse thgian thành n giây, phút, giờ, ngày trước
String _formatDate(String? raw) {
  if (raw == null) return ''; // nếu k truyền thgian thì rỗng
  final dt = DateTime.tryParse(raw); // parse dạng thgian raw thành datetime 
  if (dt == null) return '';

  final now = DateTime.now(); // lấy thgian hiện tại 
  final diff = now.difference(dt); // lấy sự khác biệt giữa thgian hiện tại và thời gian truyền vào 

  // nếu khác biệt sao thì trả về vậy 
  if (diff.inSeconds < 10) return 'Vừa xong';
  if (diff.inSeconds < 60) return '${diff.inSeconds} giây trước';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';

  final weeks = (diff.inDays / 7).floor();
  return '$weeks tuần trước';
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _controller = FriendController();
  List<dynamic> _listRequests = [];  // list lưu lời mời 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData(); // tải dữ liệu khi khởi tạo 
  }

  Future<void> _fetchData() async {
    try {
      final data = await _controller.incomeRequest(); // lấy ra lời mời 
      if (mounted) { // đảm bảo setstate chỉ gọi khi widget tồn taij 
        setState(() {
          _listRequests = data ?? []; // gán data vào list 
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Lỗi tải dữ liệu: $e");
    }
  }

  /// ================= XỬ LÝ CHẤP NHẬN =================
  Future<void> _handleAccept(dynamic requestId) async { //truyền id và gọi accept, sau đó thêm vào list 
    setState(() {
      _listRequests.removeWhere((item) => item['id'] == requestId);
    });

    try {
      final ok = await _controller.acceptRequest(requestId);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi chấp nhận lời mời')),
        );
        _fetchData(); 
      }
    } catch (e) {
      if (mounted) _fetchData();
    }
  }

  /// ================= XỬ LÝ TỪ CHỐI =================
  Future<void> _handleCancel(dynamic requestId) async { // truyền id vào để gọi cancel, xóa khỏi list 
    setState(() {
      _listRequests.removeWhere((item) => item['id'] == requestId);
    });

    try {
      // Sử dụng requestId để hủy
      final ok = await _controller.rejectRequest(requestId);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi từ chối lời mời')),
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
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData, // kéo tải lại lời mời kb 
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
                        subtitle: Text('Gửi lúc: ${_formatDate(request['created'])}'),
                        
                        // Sửa phần trailing để chứa 2 nút
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Quan trọng để không chiếm hết chiều ngang
                          children: [
                            // NÚT CHẤP NHẬN
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => _handleAccept(request['id']),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            // NÚT HỦY 
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => _handleCancel(request['id']),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}