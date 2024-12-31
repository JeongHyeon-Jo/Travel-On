// 두 개의 비밀번호 입력 값이 동일한지 확인하는 메서드
bool validatePasswordMatch(String password, String confirmPassword) {
  return password == confirmPassword;
}

// 비밀번호가 최소 6자 이상 인지 확인하는 메서드
bool validatePasswordLength(String password) {
  return password.length >= 6;
}
