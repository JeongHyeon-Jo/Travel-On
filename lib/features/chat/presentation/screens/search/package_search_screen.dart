import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/chat/presentation/widgets/package_detail_widget.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PackageSearchScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const PackageSearchScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _PackageSearchScreenState createState() => _PackageSearchScreenState();
}

class _PackageSearchScreenState extends State<PackageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TravelPackage> _searchResults = [];

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final packageProvider = Provider.of<TravelProvider>(context, listen: false);
      setState(() {
        _searchResults = packageProvider.searchPackages(query);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('패키지 찾기'),
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
                      labelText: '패키지 이름, 지역 또는 가이드 이름 검색',
                      labelStyle: TextStyle(color: Colors.blue, fontSize: 14.sp),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.blue),
                  onPressed: () {
                    _onSearchChanged();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final package = _searchResults[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        package.mainImage ?? '',
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/assets/images/default_image.png.png',
                            width: 60.w,
                            height: 60.h,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    title: Text(
                      package.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '가격: ${package.price}원',
                          style: TextStyle(color: Colors.blue, fontSize: 14.sp),
                        ),
                        Text(
                          '가이드: ${package.guideName}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.share, color: Colors.blue),
                      onPressed: () {
                        _showPackageDetail(context, package);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPackageDetail(BuildContext context, TravelPackage package) {
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
            child: PackageDetailWidget(package: package),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _sendPackageDetails(package);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('보내기'),
            ),
          ],
        );
      },
    );
  }

  void _sendPackageDetails(TravelPackage package) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    chatProvider.sendPackageDetailsMessage(
      chatId: widget.chatId,
      package: package,
      otherUserId: widget.otherUserId,
      context: context,
    );
  }
}
