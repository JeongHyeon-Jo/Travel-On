import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/gallery_post.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';

class TravelGalleryScreen extends StatelessWidget {
  const TravelGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text('gallery.title'.tr()),
        actions: [
          IconButton(
            onPressed: () => context.push('/gallery-search'),
            icon: const Icon(CupertinoIcons.search),
          ),
          IconButton(
            onPressed: () => context.push('/scrapped-posts'),
            icon: const Icon(CupertinoIcons.bookmark),
          ),
          IconButton(
            onPressed: () => context.push('/add-gallery-post'),
            icon: const Icon(CupertinoIcons.plus_circle),
          ),
        ],
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = provider.posts;
          if (posts.isEmpty) {
            return Center(child: Text('gallery.no_posts'.tr()));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
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
