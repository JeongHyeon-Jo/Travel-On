import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../widgets/gallery_post.dart';

class GallerySearchScreen extends StatefulWidget {
  const GallerySearchScreen({super.key});

  @override
  State<GallerySearchScreen> createState() => _GallerySearchScreenState();
}

class _GallerySearchScreenState extends State<GallerySearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '위치, 내용, 패키지로 검색...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<GalleryProvider>().clearSearch();
              },
            ),
          ),
          onChanged: (query) {
            context.read<GalleryProvider>().searchPosts(query);
          },
        ),
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          final searchResults = provider.searchResults;
          if (_searchController.text.isEmpty) {
            return const Center(child: Text('검색어를 입력해주세요'));
          }

          if (searchResults.isEmpty) {
            return const Center(child: Text('검색 결과가 없습니다'));
          }

          return ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final post = searchResults[index];
              provider.subscribeToComments(post.id);
              final comments = provider.getCommentsForPost(post.id);

              return GalleryPost(
                imgUrl: post.imageUrl,
                username: post.username,
                location: post.location,
                description: post.description,
                postId: post.id,
                likedBy: post.likedBy,
                likeCount: post.likeCount,
                comments: comments,
                userId: post.userId,
                packageId: post.packageId,
                packageTitle: post.packageTitle,
                userProfileUrl: post.userProfileUrl,
              );
            },
          );
        },
      ),
    );
  }
}
