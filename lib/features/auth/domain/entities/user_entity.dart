// 사용자를 식별 가능한 필수 정보가 들어 있는 클래스
class User {
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });
}
