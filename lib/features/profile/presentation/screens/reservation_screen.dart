import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../reservation/presentation/providers/reservation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../search/presentation/providers/travel_provider.dart';
import '../../../search/domain/entities/travel_package.dart';

class CustomerReservationsScreen extends StatefulWidget {
  final String? initialTab;

  const CustomerReservationsScreen({
    super.key,
    this.initialTab,
  });

  @override
  State<CustomerReservationsScreen> createState() =>
      _CustomerReservationsScreenState();
}

class _CustomerReservationsScreenState extends State<CustomerReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == '1' ? 1 : 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      await context.read<ReservationProvider>().loadReservations(userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reservations: $e')),
      );
    }
  }

  Future<void> _navigateToPackageDetail(String packageId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final travelProvider = context.read<TravelProvider>();
      await travelProvider.loadPackages();

      if (!mounted) return;
      Navigator.pop(context);

      final package = travelProvider.packages.firstWhere(
        (p) => p.id == packageId,
        orElse: () => throw Exception('reservations.package_not_found'.tr()),
      );

      if (!mounted) return;
      context.push('/package-detail/${package.id}', extra: package);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'reservations.package_load_error'.tr(args: [e.toString()]))),
      );
    }
  }

  Widget _buildReservationList(ReservationProvider provider, String status) {
    final reservations =
        provider.reservations.where((res) => res.status == status).toList();

    if (reservations.isEmpty) {
      return Center(
        child: Text(status == 'pending'
            ? 'reservations.no_pending_reservations'.tr()
            : 'reservations.no_confirmed_reservations'.tr()),
      );
    }

    return Consumer<TravelProvider>(
      builder: (context, travelProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index];

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _navigateToPackageDetail(reservation.packageId),
                child: Column(
                  children: [
                    // Thumbnail image handling
                    _buildPackageImage(reservation, travelProvider),
                    // Reservation information
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPackageTitle(reservation),
                          const SizedBox(height: 8),
                          _buildReservationDetails(reservation, status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPackageImage(
      dynamic reservation, TravelProvider travelProvider) {
    final package = travelProvider.packages.firstWhere(
      (p) => p.id == reservation.packageId,
      orElse: () => TravelPackage(
        id: reservation.packageId,
        title: reservation.packageTitle,
        description: '',
        price: reservation.price,
        region: '',
        guideName: reservation.guideName,
        guideId: reservation.guideId,
        maxParticipants: 0,
        minParticipants: 1,
        nights: 1,
        departureDays: [1, 2, 3, 4, 5, 6, 7],
        totalDays: 1,
        descriptionImages: [],
        routePoints: [],
      ),
    );

    if (package.mainImage != null && package.mainImage!.isNotEmpty) {
      return SizedBox(
        height: 150,
        width: double.infinity,
        child: Image.network(
          package.mainImage!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.landscape,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPackageTitle(dynamic reservation) {
    return Row(
      children: [
        Expanded(
          child: Consumer<TravelProvider>(
            builder: (context, travelProvider, _) {
              // 해당 패키지 찾기
              final package = travelProvider.packages.firstWhere(
                    (p) => p.id == reservation.packageId,
                orElse: () => TravelPackage(
                  id: reservation.packageId,
                  title: reservation.packageTitle,
                  description: '',
                  price: reservation.price,
                  region: '',
                  guideName: reservation.guideName,
                  guideId: reservation.guideId,
                  maxParticipants: 0,
                  minParticipants: 1,
                  nights: 1,
                  departureDays: [1, 2, 3, 4, 5, 6, 7],
                  totalDays: 1,
                  descriptionImages: [],
                  routePoints: [],
                ),
              );

              // 현재 언어에 맞는 제목 가져오기
              return Text(
                package.getTitle(context.locale.languageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildReservationDetails(dynamic reservation, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'reservations.guide'.tr(namedArgs: {
            'name': reservation.guideName
          }),
          style: TextStyle(fontSize: 14.sp),
        ),
        Text(
          'reservations.reservation_date'.tr(namedArgs: {
            'date': DateFormat('yyyy년 MM월 dd일').format(reservation.reservationDate)
          }),
          style: TextStyle(fontSize: 14.sp),
        ),
        Text(
          'reservations.request_date'.tr(namedArgs: {
            'date': DateFormat('yyyy년 MM월 dd일').format(reservation.requestedAt)
          }),
          style: TextStyle(fontSize: 14.sp),
        ),
        Text(
          'reservations.price'.tr(namedArgs: {
            'amount': NumberFormat('#,###').format(reservation.price.toInt())
          }),
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: status == 'pending'
                ? Colors.orange.shade100
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            status == 'pending'
                ? 'reservations.pending_approval'.tr()
                : 'reservations.confirmed'.tr(),
            style: TextStyle(
              color: status == 'pending'
                  ? Colors.orange.shade900
                  : Colors.green.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.user.my_reservations'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'reservations.pending_reservations'.tr()),
            Tab(text: 'reservations.confirmed_reservations'.tr()),
          ],
        ),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, child) {
          if (provider.reservations.isEmpty) {
            return Center(
              child: Text('reservations.no_reservations'.tr()),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReservationList(provider, 'pending'),
              _buildReservationList(provider, 'approved'),
            ],
          );
        },
      ),
    );
  }
}
