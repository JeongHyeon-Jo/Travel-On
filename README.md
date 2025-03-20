# <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNTgg/MDAxNzQyNDYxOTIwNTIw.DYosWgaQScyFaRE8ipOIJIU8GtE1I2yIFRI9YGYhTxUg.l3uygG1now65wLFUrW2uuxlZC0qN71xQEAKriXG0xb8g.PNG/%ED%8A%B8%EB%9E%98%EB%B8%94ON.png?type=w966" width="40"> TravelON (트래블ON)
여행 패키지 예약 및 가이드-여행객 매칭 플랫폼

## 프로젝트 기간
- 2024.10.28 ~ 2024.11.25 (2주)

## 팀원 및 담당 파트
### 도지훈 (팀장)
- 홈 화면 기능 (정보위젯/여행추천)
- 지역별 명소 리스트 기능
- 여행갤러리 기능(앱 내 SNS)
- 홈 화면 테스트 코드 작성
- 다크 모드 지원
- PUSH 알림
- 소셜로그인

### 고규화 (팀원)
- 여행 패키지 기능
  - 생성/수정/리뷰/찜
  - 예약승인/지역필터/정렬/검색
- 네이버 지도 연동 기능
- 가이드 랭킹 기능
- 마이페이지 기능
- 다국어 지원 기능

### 유경철 (팀원)
- 앱 내 결제기능 연동
- 결제 백엔드 파트

### 조정현 (팀원)
- 로그인/회원가입/인증 기능
- 프로필 기능
- 채팅 기능
  - 패키지/장소/사용자 정보 공유
  - 카메라/앨범 이미지 공유
  - 채팅방 목록
- 사용자 정보 수정 기능
- [시연 영상](https://youtu.be/oYZbfPeqkfE)
  - 촬영/편집/나레이션

## 담당 기능 📌
### 사용자 인증 시스템 🔑
- 로그인 화면
  - 로그인 정보 저장
  - 비밀번호 재설정
<img src="" width="200">

- 회원가입 화면
<img src="" width="200">

### 사용자 유형에 따라 다른 프로필 🤠
- 가이드 프로필
  - 가이드 마크
  - 해당 가이드가 올린 패키지의 평균 별점, 총 리뷰 수
<img src="" width="200">

  - 해당 가이드가 올린 패키지 리스트
<img src="" width="200">

- 일반 사용자 프로필
  - 본인의 프로필
    - 프로필 수정
    - 배경 이미지 변경, 제거
<img src="" width="200">

  - 그 외 프로필
    - 채팅 기능
<img src="" width="200">

### 채팅 시스템 🗨
- 실시간 1:1 채팅
<img src="" width="200">

- 바텀 시트 기능(화면 아래에서 올라오는 옵션 창) 
  - 카메라/앨범 이미지 전송
<img src="" width="200">

  - 지도 정보 공유
<img src="" width="200">

  - 사용자 정보 공유
<img src="" width="200">

  - 패키지 정보 공유
<img src="" width="200">

- 채팅방 목록
  - 사용자 검색 후 채팅
<img src="" width="200">

  - 좌측으로 밀어 대화방 나가기 기능
<img src="" width="200"> <img src="" width="200">

## 그 외 기능
### 여행 패키지
- 다국어 지원 (한국어, 영어, 일본어, 중국어)
- 지역별 패키지 검색 및 필터링
- 상세 여행 코스 및 경로 확인 (네이버 지도 연동)
- 실시간 예약 시스템
- 리뷰 및 평점 시스템
- 패키지 상세 정보 (가격, 인원, 일정, 설명)
- 이미지 갤러리 지원

### 가이드 기능
- 패키지 등록 및 관리
  - 다국어 정보 입력
  - 코스 경로 설정
  - 예약 가능 일자 관리
  - 가격 및 인원 설정
- 예약 관리
  - 예약 승인/거절
  - 예약 현황 확인
- 가이드 프로필 및 통계
  - 평점 및 리뷰 관리
  - 매출 통계
- 실시간 채팅 상담

### 여행 갤러리
- 여행 후기 공유
- 이미지 업로드
- 댓글 및 좋아요
- 게시물 스크랩
- 패키지 연동 태그
- 위치 정보 표시

### 알림 시스템
- FCM 푸시 알림
- 예약 관련 알림
  - 예약 신청
  - 승인/거절 상태
  - 예약 확정
- 채팅 메시지 알림
- 알림 이력 관리

## 기술 스택
### Frontend
- Flutter
- Provider (상태 관리)
- Easy Localization (다국어 지원)
- Naver Maps SDK
- Firebase UI
- 반응형 디자인 (ScreenUtil)

### Backend
- Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Functions
  - Cloud Messaging (FCM)
- Firebase App Check
- 보안 규칙 적용

### 사용자 인증 시스템
- Google 로그인
- Kakao 로그인
- GitHub 로그인

## 환경 설정
### 필수 요구사항
- Flutter SDK
- Firebase CLI
- Node.js
- Xcode (iOS 빌드용)
- Android Studio (Android 빌드용)

### 환경 변수 (.env)
```env
KAKAO_NATIVE_APP_KEY=your_kakao_native_key
KAKAO_JAVASCRIPT_KEY=your_kakao_js_key
NAVER_MAP_CLIENT_ID=your_naver_client_id
```

## 시연 영상
[![TravelON 시연영상](https://img.youtube.com/vi/oYZbfPeqkfE/0.jpg)](https://youtu.be/oYZbfPeqkfE)
