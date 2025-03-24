# <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNTgg/MDAxNzQyNDYxOTIwNTIw.DYosWgaQScyFaRE8ipOIJIU8GtE1I2yIFRI9YGYhTxUg.l3uygG1now65wLFUrW2uuxlZC0qN71xQEAKriXG0xb8g.PNG/%ED%8A%B8%EB%9E%98%EB%B8%94ON.png?type=w966" width="40"> TravelON (트래블ON)
여행 패키지 예약 및 가이드-여행객 매칭 플랫폼

## 프로젝트 기간
- 2024.10.28 ~ 2024.11.25

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
  - 사용자 정보 수정 기능
- 프로필 기능
- 채팅 기능
  - 메시지 입력 시 보내기 버튼 활성화
  - 카메라/앨범 이미지 공유
  - 사용자/패키지/장소 정보 공유
  - 채팅방 목록
- [시연 영상](https://youtu.be/oYZbfPeqkfE)
  - 촬영/편집/나레이션

## 담당 기능 📌
### 사용자 인증 시스템 🔑
- 로그인 화면
  - 로그인 정보 저장
  - 비밀번호 재설정
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjY4/MDAxNzQyNDY0MzE3MDc0.rGBYEleNJLZzhXF2gEAxB-x-hgFsUoJ2m_ahjc1nmHcg.DojI3ncWY3yWt74RMMxI3_YKPV_lk6wgqzoFNTmwi6Qg.PNG/1.PNG?type=w966" width="200">

- 회원가입 화면
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjUx/MDAxNzQyNDY0MzE3MDc4.eTelTO55u6yoVki30wZWoo-6mfI4b8JrjXWcK5gt6YAg.bHu-3hPfsJnwRw2uAJ6RXpedKwg5NpM2J0HvRJ5cVUkg.PNG/11.PNG?type=w966" width="200">

- 사용자 정보 수정
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTEz/MDAxNzQyNDYzNDkzNTM0.dv6WfzXWNI3L0cgAP4H8hX-ead1oUoIkDzLxVB64Q20g.lR6bbOA6dmu1ESBdVVSh71qR1Z3SSWXGBoSfTbNC5pog.PNG/%EC%A0%95%EB%B3%B4%EC%88%98%EC%A0%95.PNG?type=w966" width="200">

### 사용자 유형에 따라 다른 프로필 🤠
- 가이드 프로필
  - 가이드 마크
  - 해당 가이드가 올린 패키지의 평균 별점, 총 리뷰 수
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjAz/MDAxNzQyNDY0MzE3MDk3.n2H_qOuPpLOJ72bQ04tqXwFS7o2VrqiruO-lssJCe78g.NoT8K1pPrBZ-fXA0FG-QkPlmB9998Mea_IARV5o7s8gg.PNG/111.PNG?type=w966" width="200">

  - 해당 가이드가 올린 패키지 리스트

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNzcg/MDAxNzQyNDYzNDkzMjUy.RjwLHqyYrXlVro8HjbeiPEX4sVEzag96ZEhnr5wZDDsg.GWNCKoKjsar87YeljQRwYFizSHNfeguRM5sWY131OMYg.PNG/%ED%95%B4%EB%8B%B9_%EA%B0%80%EC%9D%B4%EB%93%9C%EA%B0%80_%EC%98%AC%EB%A6%B0_%ED%8C%A8%ED%82%A4%EC%A7%801.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjM4/MDAxNzQyNDYzNDkzMTAy.0rjwHtYT5FDRD-CCmXNlkxvg0ou8K_zOMtYR5Kv-RgAg.gpdWjkPsnWvGHWVF9k5B6RAE8EJ4PKR6kDv9mNzGb3cg.PNG/%ED%95%B4%EB%8B%B9_%EA%B0%80%EC%9D%B4%EB%93%9C%EA%B0%80_%EC%98%AC%EB%A6%B0_%ED%8C%A8%ED%82%A4%EC%A7%802.PNG?type=w966" width="200">

- 일반 사용자 프로필
  - 최근에 작성한 리뷰

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTE3/MDAxNzQyNDYzNDkzNzUy.8BNsblIAXHesMproxjq8AeRVDxzUsNUEHb-0pERLEucg.IL2n3PzCSHRZZbnanBamrh0MFSNz0Gxk7ahDMnuuN74g.PNG/%EC%B5%9C%EA%B7%BC%EC%97%90_%EC%9E%91%EC%84%B1%ED%95%9C_%EB%A6%AC%EB%B7%B0.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjQ2/MDAxNzQyNDYzNDkzNzU2.Fz7Q4sMoXyJdazb-AADBN2ElUf4k_LI4Alf97IrE9_Ug.neBYxguJHJ8Cr8vufESU0lbapD_gsev_nsy0o2U-bkMg.PNG/%EC%B5%9C%EA%B7%BC%EC%97%90_%EC%9E%91%EC%84%B1%ED%95%9C_%EB%A6%AC%EB%B7%B02.PNG?type=w966" width="200">

  - 본인의 프로필
    - 프로필 수정
    - 배경 이미지 변경, 제거

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTMx/MDAxNzQyNDYzNDkzMzQx.56XMDlGqDjiQF8gk15t6TXq-v0PCmoMgFAesKDVqbe4g.PzWZQCuIJMNePGXnE6rZiaR9jaEAfj0gep8WtYoc98Eg.PNG/%EB%B3%B8%EC%9D%B81.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfOTMg/MDAxNzQyNDYzNDkzMDg0.NY_e8ohQApiyoJvyq1pnOmfOl0Vrwdl4kBuBc82LYsAg.szgpSawdVV74PIIvo7QLt_AHBDNvmNX-M5Js8qqNanIg.PNG/%EB%B3%B8%EC%9D%B82.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTgz/MDAxNzQyNDYzNDkzMDg3.qLo5Tm4YkndQSWgUA_R97s_Iw9qEFWla1GVT98xHvkAg.Br1xZq2HhslzggiKdNdal5Hnmzm195uQ9LYUvcoNEaog.PNG/%EB%B3%B8%EC%9D%B83.PNG?type=w966" width="200">

  - 그 외 프로필
    - 채팅 기능
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNDIg/MDAxNzQyNDYzNDkzNDE3.GNl8xN64iJ9-S4t63poSpdaULtEXeJjqSdpSmvEvjaYg.QAEmj2KxZDDIwycsyrWhd6khSIZz-FM4Wzy5C5Plnt8g.PNG/%EA%B7%B8%EC%99%B8.PNG?type=w966" width="200">

### 채팅 시스템 🗨
- 실시간 1:1 채팅
- 메시지 입력 시 입력 버튼 활성화

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjk2/MDAxNzQyNDYzNDkzMjUz.WCFSlq9dQ5uyQMZ7lm3YZEu-BJfkOPOyrnMxtk114EMg.gfsbfp8wtpV6ZzQulphWl-QWP-9d4bAfB1Gg2MhrrSwg.PNG/%ED%99%9C%EC%84%B1.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjcw/MDAxNzQyNDYzNDkzMjcx.0pKmgBtMLbRg50pbSk92EaSU0Z46j4WK6ifDpXZMi4Ug.lxAfxnhCM2sAygTaNdW7IFJJZDXdD80jqcRB7L7ut3Eg.PNG/%ED%99%9C%EC%84%B12.PNG?type=w966" width="200">

- +버튼을 눌러 바텀 시트 기능(화면 아래에서 올라오는 옵션 창)
  - 갤러리, 카메라, 사용자, 패키지, 지도
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNjMg/MDAxNzQyNDY0NjQ5NDc0.hjWVu6n_69PgQBqgO8AH5N_KZPv7y9VpCKaWDPCEtegg.deWvAedb9Yfy3r-J9R2iiLYDAkQF3mzHDs9CQ7QuJUgg.PNG/0.PNG?type=w966" width="350">

  - 카메라/앨범 이미지 전송
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTc0/MDAxNzQyNDYzNDkzNjQz.nzqNEtEy-Yr6P-EYaPtAK7YCsSVAQ4YC6lR9YLWJ9lwg.Ffj38fJR4TjIXNoL-ypM2Iae6zNCLUmm5qQinWvQHTYg.PNG/%EC%9D%B4%EB%AF%B8%EC%A7%80.PNG?type=w966" width="200">

  - 사용자 정보 공유

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjY2/MDAxNzQyNDYzNDkzMDc2.U6Q6aD7_16MHk8hE_NNMod3vxGtaTgrvMXll9o9iv9sg.Df8o_fmNWkf5cMCNKc0BpaffXwY1kKHPKc8MDLzknogg.PNG/%EC%82%AC%EC%9A%A9%EC%9E%901.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTQ4/MDAxNzQyNDYzNDkzNTI1.0zYMdYAjxToWiJ0KEr8yyUCiW_hueqH41jPvRBk8Y4cg.r3nHESF9TwDHdZfVEYtXx6rhauFea8RKcPX58eflq0Ag.PNG/%EC%82%AC%EC%9A%A9%EC%9E%902.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjYz/MDAxNzQyNDYzNDkzMDg5.aFlj1frSyEhkH_ZOHDW7HxNlKAuZsx6NPezk3DeBsm8g.Mu6vWHmNotK4yHTeMHlvz2nUwn4hdN3eRLegiaffw9Yg.PNG/%EC%82%AC%EC%9A%A9%EC%9E%903.PNG?type=w966" width="200">

  - 패키지 정보 공유

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTQ1/MDAxNzQyNDYzNDkzMDgw.uQ8wjrMJfxu2F_FL-pBIc4ARWbwAJI9hFKUwlEkLCTQg.Prl9IgZ0KldV8NYpvAtK-H7FO1fx1_EoM7_AYtFjXdAg.PNG/%ED%8C%A8%ED%82%A4%EC%A7%801.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjIz/MDAxNzQyNDYzNDkzODMy.R1LOwlaobCfd_BIzJgnpXPxNfp8cEvuhybVzG2zTD5Eg.OnQTPAENdECYgZRb8RRwn0PWqpbk54QuIgc2KLzcwQ4g.PNG/%ED%8C%A8%ED%82%A4%EC%A7%802.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMTQw/MDAxNzQyNDYzNDkzODc0.bOYYzXZ2qwh-Y84CPxnOHczGrVsNFsSNTkhKhwwK0HIg.3hnFNaSVhtzSLCI_GnngZjGaj_wMWN7PYLFg4h9wQ5gg.PNG/%ED%8C%A8%ED%82%A4%EC%A7%803.PNG?type=w966" width="200">

  - 지도 정보 공유

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjYx/MDAxNzQyNDYzNDkzNDY1.3mSCfwGnaz3MI27wJSSd37JGIOdERI04wdy9lOhzd0Yg.GSA6qx8YpX_Rs4EgzWoiR56N5nHxKHSm1avfHTg-_MIg.PNG/%EC%A7%80%EB%8F%841.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjA1/MDAxNzQyNDYzNDkzNTA1.q2__Y6pJzF5hgWpvkl-Lb2Q-WR_NLgLyDFJE-342Pkgg.ihMJTog0_6NTn8uz60S1HpTVWm0yC5IuijfNEWSZAQ0g.PNG/%EC%A7%80%EB%8F%842.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNzEg/MDAxNzQyNDYzNDkzNjg1.E0PMYAzhIEnknpWynTkl4xjv4SGA7HMs4ncTF3unFfAg.F_ChX7l8l3fsmUkv5soYgMKXJDrVQsyjtxP8SqBibs0g.PNG/%EC%A7%80%EB%8F%843.PNG?type=w966" width="200">

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfNCAg/MDAxNzQyNDYzNDkzNzU0.CfNM2CZ-74I7xTmJtsewUMUQK5K7txSYUyaz8gfP-G4g.ev5-LZhj3yNy9T9nvFQhOJe1ZjEmxwBRkUuDnTwuvYAg.PNG/%EC%A7%80%EB%8F%844.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjcy/MDAxNzQyNDYzNDkzNjQ5.hq07IwOnDXD77MF-20sOUm1wTFNNhLncPIcWZKuMde4g.JHym-hu42CqUtZtHJaDSv59wCVVsrGZQjm37ky_Jmdsg.PNG/%EC%A7%80%EB%8F%845.PNG?type=w966" width="200">

- 채팅방 목록
  - 사용자 검색 후 채팅
<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjc5/MDAxNzQyNDY0MzE3MDcz.0AwLm2gUqjNxml49fW47dFbw00qPjKviJaS9WXdD44Qg.yiRi38VVXMKAm3fhS5d9QK2XxGhtIQSfBHdl-spC5AYg.PNG/1111.PNG?type=w966" width="200">

  - 좌측으로 밀어 대화방 나가기 기능

<img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjky/MDAxNzQyNDYzNDkzNDQ4.WnddN-nVXDfjrrZFqmA8vkYAsgz4cPzAAUg9owvaLmgg.50I4Z-uanc0M6B0DV1uYvXExeRlKriKVuQ3GHAAtjbkg.PNG/%EB%82%98%EA%B0%80%EA%B8%B01.PNG?type=w966" width="200"> <img src="https://postfiles.pstatic.net/MjAyNTAzMjBfMjQ1/MDAxNzQyNDYzNDkzMzI0.b2R2LJhM8ttDRXtBos6Kpk8cTITlJd5FKsdaTN70xxQg.aNbmMODjYUK4UTAmdciaTp15Fks34c-cuwfM2ZDxFRIg.PNG/%EB%82%98%EA%B0%80%EA%B8%B02.PNG?type=w966" width="200">

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
