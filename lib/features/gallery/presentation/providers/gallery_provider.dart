import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/gallery_repository.dart';
import '../../domain/entities/gallery_post_entity.dart';
import '../../domain/entities/comment_entity.dart';

class GalleryProvider extends ChangeNotifier {
  final GalleryRepository _repository;
  List<GalleryPost> _posts = [];
  bool _isLoading = false;
  Stream<List<GalleryPost>>? _postsStream;
  StreamSubscription<List<GalleryPost>>? _subscription;
  final Map<String, List<Comment>> _postComments = {};
  List<GalleryPost> _scrappedPosts = [];
  List<GalleryPost> _searchResults = [];
  bool _isSearching = false;

  GalleryProvider(this._repository) {
    _initStream();
  }

  void _initStream() {
    _postsStream = _repository.getGalleryPosts();
    _subscription = _postsStream?.listen((posts) {
      _posts = posts;
      notifyListeners();
    });
  }

  List<GalleryPost> get posts => _posts;
  bool get isLoading => _isLoading;
  List<GalleryPost> get scrappedPosts => _scrappedPosts;
  List<GalleryPost> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  // 포스트 업로드
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
      await _repository.uploadPost(
        userId: userId,
        username: username,
        userProfileUrl: userProfileUrl,
        imageFile: imageFile,
        location: location,
        description: description,
        packageId: packageId,
        packageTitle: packageTitle,
      );
    } catch (e) {
      throw Exception('게시물 업로드 실패: $e');
    }
  }

  // 좋아요 토글
  Future<void> toggleLike(String postId, String userId) async {
    await _repository.toggleLike(postId, userId);
  }

  // 댓글 추가
  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    String? userProfileUrl,
    required String content,
  }) async {
    // 낙관적 업데이트를 위해 현재 상태 유지
    final currentComments = List<Comment>.from(_postComments[postId] ?? []);

    try {
      await _repository.addComment(
        postId: postId,
        userId: userId,
        username: username,
        userProfileUrl: userProfileUrl,
        content: content,
      );
    } catch (e) {
      // 에러 발생 시 원래 상태로 복구
      _postComments[postId] = currentComments;
      notifyListeners();
      rethrow;
    }
  }

  // 특정 게시글의 댓글 목록 가져오기
  List<Comment> getCommentsForPost(String postId) {
    return _postComments[postId] ?? [];
  }

  // 댓글 스트림 구독
  void subscribeToComments(String postId) {
    _repository.getComments(postId).listen((comments) {
      _postComments[postId] = comments;
      notifyListeners();
    });
  }

  // 스크랩 토글
  Future<void> toggleScrap(String postId, String userId) async {
    try {
      await _repository.toggleScrap(postId, userId);
      // 스크랩 토글 후 즉시 스크랩된 게시글 목록 새로고침
      await loadScrappedPosts(userId);
    } catch (e) {
      rethrow;
    }
  }

  // 스크랩된 게시글 로드
  Future<void> loadScrappedPosts(String userId) async {
    try {
      _scrappedPosts = await _repository.getScrappedPosts(userId);
      notifyListeners();
    } catch (e) {
      rethrow;
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
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updatePost(
        postId: postId,
        location: location,
        description: description,
        newImage: newImage,
        packageId: packageId,
        packageTitle: packageTitle,
      );

      // 로컬 상태 업데이트
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          location: location,
          description: description,
        );
        notifyListeners();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 포스트 삭제
  Future<void> deletePost(String postId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    // 낙관적 업데이트를 위해 현재 상태 유지
    final currentComments = List<Comment>.from(_postComments[postId] ?? []);

    try {
      // 댓글 삭제 시도
      _postComments[postId]?.removeWhere((comment) => comment.id == commentId);
      notifyListeners();

      await _repository.deleteComment(postId, commentId);
    } catch (e) {
      // 에러 발생 시 원래 상태로 복구
      _postComments[postId] = currentComments;
      notifyListeners();
      rethrow;
    }
  }

  void searchPosts(String query) {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final lowercaseQuery = query.toLowerCase();
    _searchResults = _posts.where((post) {
      final locationMatch =
          post.location.toLowerCase().contains(lowercaseQuery);
      final descriptionMatch =
          post.description.toLowerCase().contains(lowercaseQuery);
      final packageMatch =
          post.packageTitle?.toLowerCase().contains(lowercaseQuery) ?? false;

      return locationMatch || descriptionMatch || packageMatch;
    }).toList();

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 로그아웃 시 호출할 메서드
  void reset() {
    _subscription?.cancel();
    _posts = [];
    _scrappedPosts = [];
    _searchResults = [];
    _initStream();
    notifyListeners();
  }
}
