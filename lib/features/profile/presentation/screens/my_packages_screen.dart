import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:intl/intl.dart';

class MyPackagesScreen extends StatelessWidget {
  const MyPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 패키지 관리'),
      ),
      body: Consumer<TravelProvider>(
        builder: (context, provider, child) {
          // 현재 로그인한 가이드의 패키지만 필터링
          final myPackages = provider.packages
              .where((package) => package.guideId == userId)
              .toList();

          if (myPackages.isEmpty) {
            return const Center(
              child: Text('등록한 패키지가 없습니다.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myPackages.length,
            itemBuilder: (context, index) {
              final package = myPackages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // 패키지 이미지
                    if (package.mainImage != null)
                      Image.network(
                        package.mainImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₩${NumberFormat('#,###').format(package.price.toInt())}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          Text('최소 인원: ${package.minParticipants}명'),
                          Text('최대 인원: ${package.maxParticipants}명'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 수정 버튼
                              OutlinedButton(
                                onPressed: () {
                                  // TODO: 수정 화면으로 이동
                                  context.push('/edit-package/${package.id}', extra: package);
                                },
                                child: const Text('수정'),
                              ),
                              const SizedBox(width: 8),
                              // 삭제 버튼
                              ElevatedButton(
                                onPressed: () {
                                  // 삭제 확인 다이얼로그
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('패키지 삭제'),
                                      content: const Text('이 패키지를 삭제하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('취소'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // 삭제 확인 다이얼로그
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('패키지 삭제'),
                                                content: const Text('이 패키지를 삭제하시겠습니까?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('취소'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      try {
                                                        // 삭제 실행
                                                        await context.read<TravelProvider>().deletePackage(package.id);

                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('패키지가 삭제되었습니다')),
                                                          );
                                                          Navigator.pop(context); // 다이얼로그 닫기
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
                                                          );
                                                          Navigator.pop(context); // 다이얼로그 닫기
                                                        }
                                                      }
                                                    },
                                                    child: const Text(
                                                      '삭제',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('삭제',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('삭제',
                                style: TextStyle(
                                  color: Colors.white
                                 ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}