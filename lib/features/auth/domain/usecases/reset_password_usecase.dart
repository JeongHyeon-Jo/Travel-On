import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordUseCase {
  final FirebaseAuth _auth;

  ResetPasswordUseCase(this._auth);

  Future<void> call(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('비밀번호 재설정 메일 전송 실패: $e');
      throw '비밀번호 재설정 메일 전송에 실패했습니다';
    }
  }
}
