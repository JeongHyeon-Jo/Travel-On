import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TravelProvider _travelProvider;
  final ResetPasswordUseCase _resetPasswordUseCase;

  UserModel? _currentUser;
  bool isEmailVerified = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider(
    this._auth,
    this._resetPasswordUseCase,
    this._travelProvider,
  ) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        throw '이메일 인증이 필요합니다. 인증 메일이 발송되었습니다.';
      }

      await _fetchUserData(userCredential.user!.uid);
      notifyListeners();
    } catch (e) {
      print('로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> signup(String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user!.updateDisplayName(name);

      final userDoc = {
        'id': userCredential.user!.uid,
        'name': name,
        'email': email,
        'profileImageUrl': '',
        'backgroundImageUrl': '',
        'isGuide': false,
        'likedPackages': [],
        'introduction': '',
      };
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userDoc);
      _currentUser = UserModel.fromJson(userDoc);

      await userCredential.user!.sendEmailVerification();
      print('이메일 인증 메일 발송 시도');

      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        print('이메일 인증 미완료: 다시 확인 필요');
      }
      notifyListeners();
    } catch (e) {
      print('회원가입 실패: $e');
      rethrow;
    }
  }

  Future<void> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      isEmailVerified = user.emailVerified;
      notifyListeners();
    }
  }

  // 로그아웃 메서드
  Future<void> logout(BuildContext context) async {
    try {
      Provider.of<ChatProvider>(context, listen: false).clearDataOnLogout();

      await _auth.signOut();

      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('로그아웃 실패: $e');
      rethrow;
    }
  }

  // 회원 탈퇴 메서드
  Future<void> deleteAccount(BuildContext context, String password) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw '사용자가 인증되지 않았습니다.';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final userId = user.uid;

      Provider.of<ChatProvider>(context, listen: false).clearDataOnLogout();

      final batch = _firestore.batch();

      final userDocRef = _firestore.collection('users').doc(userId);
      batch.delete(userDocRef);

      final chatSnapshots = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (final chatDoc in chatSnapshots.docs) {
        batch.delete(chatDoc.reference);
      }

      await batch.commit();

      await user.delete();

      _currentUser = null;
      notifyListeners();

      print('회원 탈퇴가 성공적으로 완료되었습니다.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw '최근 로그인 상태가 필요합니다. 다시 로그인 후 시도해주세요.';
      }
      throw '회원 탈퇴 중 오류가 발생했습니다: ${e.message}';
    } catch (e) {
      print('회원 탈퇴 실패: $e');
      throw '회원 탈퇴에 실패했습니다.';
    }
  }

  // userId를 받아서 Firestore에서 해당 유저 정보를 가져오는 메서드
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!);
      } else {
        print('유저를 찾을 수 없습니다.');
        return null;
      }
    } catch (e) {
      print('getUserById 에러: $e');
      return null;
    }
  }

  Future<void> certifyAsGuide(File certificateImage) async {
    try {
      if (_currentUser == null) throw '로그인이 필요합니다';

      final storageRef = _storage.ref().child('guide_certificates').child(
          '${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(certificateImage);
      final imageUrl = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'isGuide': true,
        'certificateImageUrl': imageUrl,
        'certifiedAt': FieldValue.serverTimestamp(),
      });

      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        profileImageUrl: _currentUser!.profileImageUrl,
        isGuide: true,
      );

      notifyListeners();
    } catch (e) {
      print('가이드 인증 실패: $e');
      throw '가이드 인증에 실패했습니다';
    }
  }

  Future<void> _fetchUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      _currentUser = UserModel.fromJson(userDoc.data()!);
      await _travelProvider.loadLikedPackages(_currentUser!.id);
    }
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null && firebaseUser.emailVerified) {
      isEmailVerified = true;
      await _fetchUserData(firebaseUser.uid);
    } else {
      isEmailVerified = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  // 비밀번호 확인
  Future<bool> checkPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('비밀번호 확인 실패: $e');
      return false;
    }
  }

  // 프로필 업데이트
  Future<void> updateUserProfile({
    required String name,
    String? gender,
    DateTime? birthDate,
    String? profileImageUrl,
    String? backgroundImageUrl,
    String? introduction,
  }) async {
    if (_currentUser == null) throw '로그인이 필요합니다';

    try {
      final userRef = _firestore.collection('users').doc(_currentUser!.id);

      String? profileImageUrlUpdated;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty && File(profileImageUrl).existsSync()) {
        final ref = _storage.ref().child('user_profiles/${_currentUser!.id}_profile.jpg');
        await ref.putFile(File(profileImageUrl));
        profileImageUrlUpdated = await ref.getDownloadURL();
      } else {
        profileImageUrlUpdated = _currentUser!.profileImageUrl;
      }

      String? backgroundImageUrlUpdated;
      if (backgroundImageUrl != null && backgroundImageUrl.isNotEmpty && File(backgroundImageUrl).existsSync()) {
        final ref = _storage.ref().child('user_profiles/${_currentUser!.id}_background.jpg');
        await ref.putFile(File(backgroundImageUrl));
        backgroundImageUrlUpdated = await ref.getDownloadURL();
      } else if (backgroundImageUrl == null) {
        await userRef.update({'backgroundImageUrl': FieldValue.delete()});
        backgroundImageUrlUpdated = null;
      } else {
        backgroundImageUrlUpdated = _currentUser!.backgroundImageUrl;
      }

      await userRef.update({
        'name': name,
        'gender': gender,
        'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
        'profileImageUrl': profileImageUrlUpdated,
        'backgroundImageUrl': backgroundImageUrlUpdated,
        'introduction': introduction,
      });

      _currentUser = _currentUser!.copyWith(
        name: name,
        gender: gender,
        birthDate: birthDate,
        profileImageUrl: profileImageUrlUpdated,
        backgroundImageUrl: backgroundImageUrlUpdated,
        introduction: introduction,
      );

      notifyListeners();
    } catch (e) {
      print('프로필 업데이트 실패: $e');
      throw '프로필 업데이트에 실패했습니다';
    }
  }

  // 비밀번호 재설정
  Future<void> resetPassword(String email) async {
    await _resetPasswordUseCase.call(email);
  }

  Future<void> toggleLikePackage(String packageId) async {
    if (_currentUser == null) throw '로그인이 필요합니다';

    try {
      final userRef = _firestore.collection('users').doc(_currentUser!.id);
      final userDoc = await userRef.get();

      final packageRef = _firestore.collection('packages').doc(packageId);
      final packageDoc = await packageRef.get();

      if (!userDoc.exists || !packageDoc.exists) {
        throw '사용자 또는 패키지를 찾을 수 없습니다';
      }

      List<String> userLikedPackages =
          List<String>.from(userDoc.data()!['likedPackages'] ?? []);
      List<String> packageLikedBy =
          List<String>.from(packageDoc.data()!['likedBy'] ?? []);

      bool isLiked = userLikedPackages.contains(packageId);
      if (isLiked) {
        userLikedPackages.remove(packageId);
        packageLikedBy.remove(_currentUser!.id);
      } else {
        userLikedPackages.add(packageId);
        packageLikedBy.add(_currentUser!.id);
      }

      await userRef.update({'likedPackages': userLikedPackages});

      await packageRef.update(
          {'likedBy': packageLikedBy, 'likesCount': packageLikedBy.length});

      _currentUser = _currentUser!.copyWith(
        likedPackages: userLikedPackages,
      );

      notifyListeners();
    } catch (e) {
      print('Error toggling like in AuthProvider: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final userCollection = _firestore.collection('users');

      final emailSnapshot =
          await userCollection.where('email', isEqualTo: query).get();

      final nameSnapshot = await userCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailResults = emailSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
      final nameResults = nameSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();

      final allResults = {...emailResults, ...nameResults}.toList();
      return allResults;
    } catch (e) {
      print('사용자 검색 실패: $e');
      return [];
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      // Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 정보 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인 수행
      final userCredential = await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장 또는 업데이트
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // 새 사용자인 경우 Firestore에 정보 저장
        final newUser = {
          'id': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'profileImageUrl': userCredential.user!.photoURL ?? '',
          'isGuide': false,
          'likedPackages': [],
          'introduction': '',
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser);

        _currentUser = UserModel.fromJson(newUser);
      } else {
        // 기존 사용자인 경우 정보 로드
        await _fetchUserData(userCredential.user!.uid);
      }

      notifyListeners();
    } catch (e) {
      print('Google 로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> signInWithGithub(BuildContext context) async {
    try {
      // GitHub 제공자 생성
      final githubProvider = GithubAuthProvider();

      // 플랫폼에 따라 다른 로그인 메서드 사용
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(githubProvider);
      } else {
        userCredential = await _auth.signInWithProvider(githubProvider);
      }

      // Firestore에 사용자 정보 저장 또는 업데이트
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // 새 사용자인 경우 Firestore에 정보 저장
        final newUser = {
          'id': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'profileImageUrl': userCredential.user!.photoURL ?? '',
          'isGuide': false,
          'likedPackages': [],
          'introduction': '',
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser);

        _currentUser = UserModel.fromJson(newUser);
      } else {
        // 기존 사용자인 경우 정보 로드
        await _fetchUserData(userCredential.user!.uid);
      }

      notifyListeners();
    } catch (e) {
      print('GitHub 로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> signInWithKakao(BuildContext context) async {
    try {
      // 카카오톡 설치 여부 확인
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          final token = await kakao.UserApi.instance.loginWithKakaoTalk();
          await _signInWithKakaoToken(token, context);
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return;
          }
          // 카카오톡 로그인 실패 시 카카오계정으로 로그인 시도
          try {
            final token = await kakao.UserApi.instance.loginWithKakaoAccount();
            await _signInWithKakaoToken(token, context);
          } catch (error) {
            print('카카오계정으로 로그인 실패 $error');
            rethrow;
          }
        }
      } else {
        try {
          final token = await kakao.UserApi.instance.loginWithKakaoAccount();
          await _signInWithKakaoToken(token, context);
        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
          rethrow;
        }
      }
    } catch (e) {
      print('카카오 로그인 실패: $e');
      rethrow;
    }
  }

  Future<void> _signInWithKakaoToken(
      kakao.OAuthToken token, BuildContext context) async {
    try {
      // 카카오 사용자 정보 가져오기
      final kakaoUser = await kakao.UserApi.instance.me();

      // Firebase 인증
      final provider = OAuthProvider('oidc.kakao.com');
      final credential = provider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // Firestore에서 사용자 정보 확인
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // 새 사용자인 경우 Firestore에 정보 저장
        final newUser = {
          'id': userCredential.user!.uid,
          'name': kakaoUser.kakaoAccount?.profile?.nickname ?? '',
          'email': kakaoUser.kakaoAccount?.email ?? '',
          'profileImageUrl':
              kakaoUser.kakaoAccount?.profile?.profileImageUrl ?? '',
          'isGuide': false,
          'likedPackages': [],
          'introduction': '',
        };

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser);

        _currentUser = UserModel.fromJson(newUser);
      } else {
        // 기존 사용자인 경우 정보 로드
        await _fetchUserData(userCredential.user!.uid);
      }

      notifyListeners();
    } catch (e) {
      print('Firebase 인증 실패: $e');
      rethrow;
    }
  }
}
