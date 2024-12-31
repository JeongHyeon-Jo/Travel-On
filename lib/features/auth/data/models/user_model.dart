import 'package:travel_on_final/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? backgroundImageUrl;
  final bool isGuide;
  final String? gender;
  final DateTime? birthDate;
  final String? introduction;
  List<String> likedPackages;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.backgroundImageUrl,
    this.isGuide = false,
    this.gender,
    this.birthDate,
    this.introduction,
    List<String>? likedPackages,
  }) : likedPackages = likedPackages ?? [],
        super(id: id, name: name, email: email);

  // JSON 데이터를 UserModel 객체로 변환하는 fromJson 메서드
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      isGuide: json['isGuide'] as bool? ?? false,
      gender: json['gender'] as String?,
      birthDate: json['birthDate'] != null 
          ? (json['birthDate'] as Timestamp).toDate() 
          : null,
      introduction: json['introduction'] as String?,
      likedPackages: List<String>.from(json['likedPackages'] ?? []),
    );
  }

  // UserModel 객체를 JSON 형식으로 변환하는 toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'isGuide': isGuide,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'introduction': introduction,
      'likedPackages': likedPackages,
    };
  }

  // 복사본 생성 메서드 (찜 목록 업데이트 시 사용)
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? backgroundImageUrl,
    bool? isGuide,
    String? gender,
    DateTime? birthDate,
    String? introduction,
    List<String>? likedPackages,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      isGuide: isGuide ?? this.isGuide,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      introduction: introduction ?? this.introduction,
      likedPackages: likedPackages ?? List<String>.from(this.likedPackages),
    );
  }
}
