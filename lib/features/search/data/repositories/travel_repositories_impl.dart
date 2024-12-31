import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import '../../domain/repositories/travel_repositories.dart';
import '../../domain/entities/travel_package.dart';

class TravelRepositoryImpl implements TravelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<List<TravelPackage>> getPackages() async {
    try {
      final snapshot = await _firestore.collection('packages').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TravelPackage(
          id: doc.id,
          title: data['title'] ?? '',
          titleEn: data['titleEn'] ?? '',
          titleJa: data['titleJa'] ?? '',
          titleZh: data['titleZh'] ?? '',
          description: data['description'] ?? '',
          descriptionEn: data['descriptionEn'] ?? '',
          descriptionJa: data['descriptionJa'] ?? '',
          descriptionZh: data['descriptionZh'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          region: data['region'] ?? '',
          mainImage: data['mainImage'],
          descriptionImages: List<String>.from(data['descriptionImages'] ?? []),
          guideName: data['guideName'] ?? '',
          guideId: data['guideId'] ?? '',
          minParticipants: (data['minParticipants'] as num?)?.toInt() ?? 4,
          maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 8,
          nights: (data['nights'] as num?)?.toInt() ?? 0,
          totalDays: (data['totalDays'] as num?)?.toInt() ?? 0,
          departureDays:
              List<int>.from(data['departureDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          likedBy: List<String>.from(data['likedBy'] ?? []),
          likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
          routePoints: (data['routePoints'] as List<dynamic>?)
                  ?.map((point) =>
                      TravelPoint.fromJson(point as Map<String, dynamic>))
                  .toList() ??
              [],
        );
      }).toList();
    } catch (e) {
      print('Error getting packages: $e');
      rethrow;
    }
  }

  @override
  Future<void> addPackage(TravelPackage package) async {
    try {
      print('Starting to add package...');

      String? mainImageUrl;
      List<String> descriptionImageUrls = [];

      if (package.mainImage != null) {
        print('Uploading main image...');
        final mainImageFile = File(package.mainImage!);
        final mainImageRef = _storage.ref(
            'package_images/${DateTime.now().millisecondsSinceEpoch}_main.jpg');
        await mainImageRef.putFile(mainImageFile);
        mainImageUrl = await mainImageRef.getDownloadURL();
        print('Main image uploaded: $mainImageUrl');
      }

      for (String imagePath in package.descriptionImages) {
        print('Uploading description image...');
        final file = File(imagePath);
        final imageRef = _storage.ref(
            'package_images/${DateTime.now().millisecondsSinceEpoch}_${descriptionImageUrls.length}.jpg');
        await imageRef.putFile(file);
        final imageUrl = await imageRef.getDownloadURL();
        descriptionImageUrls.add(imageUrl);
        print('Description image uploaded: $imageUrl');
      }

      final packageData = {
        'title': package.title,
        'titleEn': package.titleEn,
        'titleJa': package.titleJa,
        'titleZh': package.titleZh,
        'description': package.description,
        'descriptionEn': package.descriptionEn,
        'descriptionJa': package.descriptionJa,
        'descriptionZh': package.descriptionZh,
        'price': package.price,
        'region': package.region,
        'mainImage': mainImageUrl,
        'descriptionImages': descriptionImageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'guideName': package.guideName,
        'guideId': package.guideId,
        'minParticipants': package.minParticipants,
        'maxParticipants': package.maxParticipants,
        'nights': package.nights,
        'totalDays': package.totalDays,
        'departureDays': package.departureDays,
        'likedBy': [],
        'likesCount': 0,
        'routePoints':
            package.routePoints.map((point) => point.toJson()).toList(),
      };

      if (package.minParticipants <= 0) {
        throw '최소 인원은 0보다 커야 합니다';
      }
      if (package.maxParticipants < package.minParticipants) {
        throw '최대 인원은 최소 인원보다 작을 수 없습니다';
      }

      final docRef = await _firestore.collection('packages').add(packageData);
      print('Package saved with ID: ${docRef.id}');

      final savedDoc = await docRef.get();
      final savedData = savedDoc.data();
      print('Saved package data:');
      print('minParticipants: ${savedData?['minParticipants']}');
      print('maxParticipants: ${savedData?['maxParticipants']}');
    } catch (e) {
      print('Error adding package: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePackage(TravelPackage package) async {
    try {
      print('Starting to update package...');

      String? mainImageUrl;
      List<String> descriptionImageUrls = [];

      if (package.mainImage != null && package.mainImage!.startsWith('/')) {
        print('Uploading new main image...');
        final mainImageFile = File(package.mainImage!);
        final mainImageRef = _storage.ref(
            'package_images/${DateTime.now().millisecondsSinceEpoch}_main.jpg');
        await mainImageRef.putFile(mainImageFile);
        mainImageUrl = await mainImageRef.getDownloadURL();
      }

      for (String imagePath in package.descriptionImages) {
        if (imagePath.startsWith('/')) {
          print('Uploading new description image...');
          final file = File(imagePath);
          final imageRef = _storage.ref(
              'package_images/${DateTime.now().millisecondsSinceEpoch}_${descriptionImageUrls.length}.jpg');
          await imageRef.putFile(file);
          final imageUrl = await imageRef.getDownloadURL();
          descriptionImageUrls.add(imageUrl);
        } else {
          descriptionImageUrls.add(imagePath);
        }
      }

      final packageData = {
        'title': package.title,
        'titleEn': package.titleEn,
        'titleJa': package.titleJa,
        'titleZh': package.titleZh,
        'description': package.description,
        'descriptionEn': package.descriptionEn,
        'descriptionJa': package.descriptionJa,
        'descriptionZh': package.descriptionZh,
        'price': package.price,
        'region': package.region,
        'mainImage': mainImageUrl ?? package.mainImage,
        'descriptionImages': descriptionImageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
        'guideName': package.guideName,
        'guideId': package.guideId,
        'minParticipants': package.minParticipants,
        'maxParticipants': package.maxParticipants,
        'nights': package.nights,
        'totalDays': package.totalDays,
        'departureDays': package.departureDays,
        'routePoints':
            package.routePoints.map((point) => point.toJson()).toList(),
      };

      if (package.minParticipants <= 0) {
        throw '최소 인원은 0보다 커야 합니다';
      }
      if (package.maxParticipants < package.minParticipants) {
        throw '최대 인원은 최소 인원보다 작을 수 없습니다';
      }

      await _firestore
          .collection('packages')
          .doc(package.id)
          .update(packageData);
      print('Package updated successfully');
    } catch (e) {
      print('Error updating package: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePackage(String packageId) async {
    try {
      print('Starting to delete package...');

      final packageDoc =
          await _firestore.collection('packages').doc(packageId).get();
      final data = packageDoc.data();

      if (data != null) {
        final mainImage = data['mainImage'] as String?;
        final descriptionImages =
            List<String>.from(data['descriptionImages'] ?? []);

        if (mainImage != null && mainImage.isNotEmpty) {
          try {
            await _storage.refFromURL(mainImage).delete();
            print('Main image deleted');
          } catch (e) {
            print('Error deleting main image: $e');
          }
        }

        for (String imageUrl in descriptionImages) {
          try {
            await _storage.refFromURL(imageUrl).delete();
            print('Description image deleted');
          } catch (e) {
            print('Error deleting description image: $e');
          }
        }
      }

      await _firestore.collection('packages').doc(packageId).delete();
      print('Package deleted successfully');
    } catch (e) {
      print('Error deleting package: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleLike(String packageId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final packageRef = _firestore.collection('packages').doc(packageId);
        final userRef = _firestore.collection('users').doc(userId);

        final packageDoc = await transaction.get(packageRef);
        final userDoc = await transaction.get(userRef);

        final List<String> likedBy =
            List<String>.from(packageDoc.data()!['likedBy'] ?? []);
        final List<String> userLikedPackages =
            List<String>.from(userDoc.data()!['likedPackages'] ?? []);

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          userLikedPackages.remove(packageId);
          transaction.update(packageRef, {
            'likedBy': likedBy,
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          likedBy.add(userId);
          userLikedPackages.add(packageId);
          transaction.update(packageRef, {
            'likedBy': likedBy,
            'likesCount': FieldValue.increment(1),
          });
        }

        transaction.update(userRef, {
          'likedPackages': userLikedPackages,
        });
      });
    } catch (e) {
      print('Error in toggleLike: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getLikedPackages(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      return List<String>.from(userDoc.data()!['likedPackages'] ?? []);
    } catch (e) {
      print('Error getting liked packages: $e');
      return [];
    }
  }
}
