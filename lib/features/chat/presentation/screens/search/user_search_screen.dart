import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:travel_on_final/features/chat/presentation/widgets/user_detail_widget.dart';

class UserSearchScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  UserSearchScreen({required this.chatId, required this.otherUserId});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<UserModel> _searchResults = [];

  void _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await authProvider.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _showPreview(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('공유하기'),
          content: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: UserDetailWidget(user: user),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _shareUserDetails(user);
                Navigator.pop(context);
              },
              child: Text('보내기'),
            ),
          ],
        );
      },
    );
  }

  void _shareUserDetails(UserModel user) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendUserDetailsMessage(
      chatId: widget.chatId,
      user: user,
      otherUserId: widget.otherUserId,
      context: context,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사용자 검색'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: (text) => _searchUsers(),
                      decoration: InputDecoration(
                        labelText: '검색',
                        labelStyle: TextStyle(color: Colors.blue, fontSize: 14.sp),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.blue),
                    onPressed: _searchUsers,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 20.r,
                        backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(user.profileImageUrl!)
                            : AssetImage('assets/images/default_profile.png') as ImageProvider,
                      ),
                      title: Text(user.name ?? '이름 없음'),
                      subtitle: Text(user.email ?? '이메일 없음'),
                      trailing: IconButton(
                        icon: Icon(Icons.share, color: Colors.blue),
                        onPressed: () => _showPreview(user),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
