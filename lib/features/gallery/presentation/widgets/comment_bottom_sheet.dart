import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../../domain/entities/comment_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final List<Comment> comments;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.comments,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  String? _selectedCommentId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final optimisticComment = Comment(
      id: DateTime.now().toString(),
      postId: widget.postId,
      userId: user.id,
      username: user.name,
      userProfileUrl: user.profileImageUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    setState(() {
      widget.comments.insert(0, optimisticComment);
    });
    _commentController.clear();

    try {
      await context.read<GalleryProvider>().addComment(
            postId: widget.postId,
            userId: user.id,
            username: user.name,
            userProfileUrl: user.profileImageUrl,
            content: content,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.comments
              .removeWhere((comment) => comment.id == optimisticComment.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 작성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Widget _buildCommentItem(Comment comment) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isCommentOwner = currentUser?.id == comment.userId;
    final isSelected = _selectedCommentId == comment.id;

    return GestureDetector(
      onLongPress: isCommentOwner
          ? () {
              setState(() {
                _selectedCommentId =
                    _selectedCommentId == comment.id ? null : comment.id;
              });
              HapticFeedback.mediumImpact();
            }
          : null,
      onTap: () {
        if (_selectedCommentId != null) {
          setState(() {
            _selectedCommentId = null;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: Colors.grey[300],
              child: comment.userProfileUrl?.isNotEmpty == true
                  ? ClipOval(
                      child: Image.network(
                        comment.userProfileUrl!,
                        width: 32.r,
                        height: 32.r,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 20.r,
                      color: Colors.grey[600],
                    ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(comment.content),
                ],
              ),
            ),
            if (isCommentOwner && isSelected)
              IconButton(
                icon: Icon(CupertinoIcons.delete, size: 14.w),
                onPressed: () => _showDeleteConfirmation(comment),
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<GalleryProvider>().deleteComment(
              widget.postId,
              comment.id,
            );
        if (mounted) {
          setState(() {
            widget.comments.removeWhere((c) => c.id == comment.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('댓글 삭제 중 오류가 발생했습니다')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_selectedCommentId != null) {
          setState(() {
            _selectedCommentId = null;
          });
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.only(
          top: 16.h,
          left: 16.w,
          right: 16.w,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'commends.commend'.tr(),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: widget.comments.length,
                itemBuilder: (context, index) =>
                    _buildCommentItem(widget.comments[index]),
              ),
            ),
            Divider(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'commends.Writing comments'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
