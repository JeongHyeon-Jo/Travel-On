import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/gallery_post_entity.dart';
import '../../domain/entities/comment_entity.dart';

class GalleryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  GalleryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // 갤러리 포스트 목록 가져오기
  Stream<List<GalleryPost>> getGalleryPosts() {
    return _firestore
        .collection('gallery_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        final data = doc.data();

        return GalleryPost.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      return posts;
    });
  }

  // 새 포스트 업로드
  Future<void> uploadPost({
    required String userId,
    required String username,
    String? userProfileUrl,
    required File imageFile,
    required String location,
    required String description,
    String? packageId,
    String? packageTitle,
  }) async {
    try {
      // 1. 이미지를 Storage에 업로드
      final String fileName =
          'gallery_images/${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(imageFile);
      final String imageUrl = await storageRef.getDownloadURL();

      // 2. Firestore에 포스트 데이터 저장
      final docRef = _firestore.collection('gallery_posts').doc();
      final post = GalleryPost(
        id: docRef.id,
        userId: userId,
        username: username,
        userProfileUrl: userProfileUrl,
        imageUrl: imageUrl,
        location: location,
        description: description,
        createdAt: DateTime.now(),
        likedBy: [],
        likeCount: 0,
        comments: [],
        packageId: packageId,
        packageTitle: packageTitle,
      );

      await docRef.set(post.toJson());
    } catch (e) {
      throw Exception('포스트 업로드 실패: $e');
    }
  }

  // 좋아요 토글
  Future<void> toggleLike(String postId, String userId) async {
    final docRef = _firestore.collection('gallery_posts').doc(postId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('포스트를 찾을 수 없습니다');
      }

      final post = GalleryPost.fromJson(snapshot.data()!);
      final likedBy = List<String>.from(post.likedBy);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      transaction.update(docRef, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
    });
  }

  // 댓글 추가
  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    String? userProfileUrl,
    required String content,
  }) async {
    try {
      final docRef = _firestore
          .collection('gallery_posts')
          .doc(postId)
          .collection('comments')
          .doc();

      final comment = Comment(
        id: docRef.id,
        postId: postId,
        userId: userId,
        username: username,
        userProfileUrl: userProfileUrl,
        content: content,
        createdAt: DateTime.now(),
      );

      await docRef.set(comment.toJson());

      // 게시글의 댓글 수 업데이트
      await _firestore.collection('gallery_posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([docRef.id]),
      });
    } catch (e) {
      throw Exception('댓글 작성 실패: $e');
    }
  }

  // 게시글의 댓글 목록 가져오기
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('gallery_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
    });
  }

  Future<void> toggleScrap(String postId, String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final postRef = _firestore.collection('gallery_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final postDoc = await transaction.get(postRef);

        List<String> scrappedPosts =
            List<String>.from(userDoc.data()?['scrappedPosts'] ?? []);
        List<String> scrappedBy =
            List<String>.from(postDoc.data()?['scrappedBy'] ?? []);

        if (scrappedPosts.contains(postId)) {
          scrappedPosts.remove(postId);
          scrappedBy.remove(userId);
        } else {
          scrappedPosts.add(postId);
          scrappedBy.add(userId);
        }

        transaction.update(userRef, {'scrappedPosts': scrappedPosts});
        transaction.update(postRef, {'scrappedBy': scrappedBy});
      });
    } catch (e) {
      throw Exception('스크랩 처리 실패: $e');
    }
  }

  Future<List<GalleryPost>> getScrappedPosts(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final List<String> scrappedPostIds =
          List<String>.from(userDoc.data()?['scrappedPosts'] ?? []);

      if (scrappedPostIds.isEmpty) return [];

      final postsSnapshot = await _firestore
          .collection('gallery_posts')
          .where(FieldPath.documentId, whereIn: scrappedPostIds)
          .get();

      return postsSnapshot.docs
          .map((doc) => GalleryPost.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('스크랩된 게시글 로드 실패: $e');
    }
  }

  // 포스트 수정
  Future<void> updatePost({
    required String postId,
    required String location,
    required String description,
    File? newImage,
    String? packageId,
    String? packageTitle,
  }) async {
    try {
      final postRef = _firestore.collection('gallery_posts').doc(postId);
      final postDoc = await postRef.get();
      final currentData = postDoc.data();

      Map<String, dynamic> updates = {
        'location': location,
        'description': description,
        'updatedAt': DateTime.now(),
        'packageId': packageId,
        'packageTitle': packageTitle,
        'userProfileUrl': currentData?['userProfileUrl'],
      };

      // 새 이미지가 있는 경우에만 이미지 업로드 및 URL 업데이트
      if (newImage != null) {
        // 기존 이미지 URL 가져오기
        final postDoc = await postRef.get();
        final oldImageUrl = postDoc.data()?['imageUrl'] as String?;

        // 새 이미지 업로드
        final String fileName =
            'gallery_images/${DateTime.now().millisecondsSinceEpoch}_$postId.jpg';
        final Reference storageRef = _storage.ref().child(fileName);
        await storageRef.putFile(newImage);
        final String newImageUrl = await storageRef.getDownloadURL();

        // 업데이트할 데이터에 새 이미지 URL 추가
        updates['imageUrl'] = newImageUrl;

        // 기존 이미지 삭제 (있는 경우)
        if (oldImageUrl != null) {
          try {
            final oldImageRef = _storage.refFromURL(oldImageUrl);
            await oldImageRef.delete();
          } catch (e) {
            print('기존 이미지 삭제 실패: $e');
          }
        }
      }

      // Firestore 문서 업데이트
      await postRef.update(updates);
    } catch (e) {
      throw Exception('포스트 수정 실패: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    // Delete post document from Firestore
    await _firestore.collection('gallery_posts').doc(postId).delete();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('gallery_posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // 게시글의 comments 배열에서 해당 댓글 ID 제거
      await _firestore.collection('gallery_posts').doc(postId).update({
        'comments': FieldValue.arrayRemove([commentId]),
      });
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }
}
