import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/chat/domain/usecases/create_chat_id.dart';
import 'package:go_router/go_router.dart';

class GuideSearchScreen extends StatefulWidget {
  const GuideSearchScreen({Key? key}) : super(key: key);

  @override
  _GuideSearchScreenState createState() => _GuideSearchScreenState();
}

class _GuideSearchScreenState extends State<GuideSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _guides = [];

  void _searchGuides(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isGuide', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .get();

    setState(() {
      _guides = snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('가이드 찾기'),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '가이드 이름 검색',
                      labelStyle: TextStyle(color: Colors.blue, fontSize: 14.sp),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      _searchGuides(value);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.blue),
                  onPressed: () {
                    _searchGuides(_searchController.text);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _guides.length,
              itemBuilder: (context, index) {
                final guide = _guides[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: guide.profileImageUrl != null && guide.profileImageUrl!.isNotEmpty
                        ? NetworkImage(guide.profileImageUrl!)
                        : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  ),
                  title: Text(
                    guide.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    guide.introduction ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: currentUserId != guide.id
                      ? IconButton(
                          icon: Icon(Icons.chat_bubble, color: Colors.blue),
                          onPressed: () {
                            if (currentUserId != null) {
                              final chatId = CreateChatId().call(currentUserId, guide.id);
                              context.push('/chat/$chatId');
                            }
                          },
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
