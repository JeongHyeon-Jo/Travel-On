import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/gallery_post.dart';

class ScrappedPostsScreen extends StatefulWidget {
  const ScrappedPostsScreen({super.key});

  @override
  State<ScrappedPostsScreen> createState() => _ScrappedPostsScreenState();
}

class _ScrappedPostsScreenState extends State<ScrappedPostsScreen> {
  @override
  void initState() {
    super.initState();
    _loadScrappedPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadScrappedPosts();
  }

  Future<void> _loadScrappedPosts() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<GalleryProvider>().loadScrappedPosts(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '스크랩한 게시글',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final scrappedPosts = provider.scrappedPosts;

          if (scrappedPosts.isEmpty) {
            return const Center(
              child: Text('스크랩한 게시글이 없습니다'),
            );
          }

          return ListView.builder(
            itemCount: scrappedPosts.length,
            itemBuilder: (context, index) {
              final post = scrappedPosts[index];
              provider.subscribeToComments(post.id);
              final comments = provider.getCommentsForPost(post.id);

              return GalleryPost(
                userId: post.userId,
                postId: post.id,
                imgUrl: post.imageUrl,
                username: post.username,
                location: post.location,
                description: post.description,
                likedBy: post.likedBy,
                likeCount: post.likeCount,
                comments: comments,
              );
            },
          );
        },
      ),
    );
  }
}
