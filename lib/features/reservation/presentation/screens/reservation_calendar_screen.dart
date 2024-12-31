import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/reservation/presentation/providers/reservation_provider.dart';
import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:tosspayments_widget_sdk_flutter/model/paymentData.dart';
import 'package:get/route_manager.dart';
import 'package:travel_on_final/features/payment/payment_entry.dart';
import 'package:travel_on_final/features/payment/payment_process.dart';

class ReservationCalendarScreen extends StatefulWidget {
  final TravelPackage package;

  const ReservationCalendarScreen({
    super.key,
    required this.package,
  });

  @override
  State<ReservationCalendarScreen> createState() =>
      _ReservationCalendarScreenState();
}

class _ReservationCalendarScreenState extends State<ReservationCalendarScreen> {
  // 상태 변수들
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final Map<String, bool> _availabilityCache = {};
  bool _isLoading = false;
  late int _selectedParticipants;
  late final int _minParticipants;
  late final int _maxParticipants;

  @override
  void initState() {
    super.initState();
    _minParticipants = widget.package.minParticipants;
    _maxParticipants = widget.package.maxParticipants;
    assert(widget.package.minParticipants > 0, 'Invalid minimum participants');
    _selectedParticipants = widget.package.minParticipants;
    _preloadAvailability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // locale 초기화를 여기서 수행
    initializeDateFormatting(context.locale.languageCode);
  }

  // 헬퍼 메서드
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isValidDepartureDay(DateTime date) {
    return widget.package.departureDays.contains(date.weekday);
  }

  // 가용성 로딩
  Future<void> _preloadAvailability() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final start = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final end = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('packageId', isEqualTo: widget.package.id)
          .where('status', isEqualTo: 'approved')
          .get();

      final approvedDates = snapshot.docs
          .map((doc) => (doc.data()['reservationDate'] as Timestamp).toDate())
          .toList();

      if (mounted) {
        setState(() {
          for (var date = start;
              date.isBefore(end.add(const Duration(days: 1)));
              date = date.add(const Duration(days: 1))) {
            if (!date.isBefore(now)) {
              final dateKey = _getDateKey(date);
              final hasApprovedReservation = approvedDates.any((approvedDate) =>
                  approvedDate.year == date.year &&
                  approvedDate.month == date.month &&
                  approvedDate.day == date.day);
              _availabilityCache[dateKey] = !hasApprovedReservation;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // UI 빌더 메서드
  Widget _buildParticipantSelector() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    // widget.package.minParticipants 대신 _minParticipants 사용
    if (_selectedParticipants < _minParticipants) {
      _selectedParticipants = _minParticipants;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reservation_calendar.participants.title'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 여기도 저장된 변수 사용
              Text('reservation_calendar.participants.range'.tr(namedArgs: {
                'min': _minParticipants.toString(),
                'max': _maxParticipants.toString()
              })),
              Row(
                children: [
                  IconButton(
                    // 여기도 수정
                    onPressed: _selectedParticipants > _minParticipants
                        ? () {
                            setState(() {
                              final newValue = _selectedParticipants - 1;
                              if (newValue >= _minParticipants) {
                                _selectedParticipants = newValue;
                              }
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _selectedParticipants > _minParticipants
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    'reservation_calendar.participants.count'.tr(
                        namedArgs: {'count': _selectedParticipants.toString()}),
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    // 여기도 수정
                    onPressed: _selectedParticipants < _maxParticipants
                        ? () {
                            setState(() {
                              _selectedParticipants++;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _selectedParticipants < _maxParticipants
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 예약 처리
  void _requestReservation(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final reservationProvider = context.read<ReservationProvider>();

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.auth.login_required'.tr())),
      );
      context.push('/login');
      return;
    }

    if (_selectedParticipants < _minParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reservation_calendar.participants.min_error'
              .tr(namedArgs: {'min': _minParticipants.toString()})),
        ),
      );
      return;
    }

    if (_selectedParticipants > _maxParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('reservation_calendar.participants.max_error'
              .tr(namedArgs: {'max': _maxParticipants.toString()})),
        ),
      );
      return;
    }

    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('reservation_calendar.date.select_error'.tr())),
      );
      return;
    }

    try {
      await reservationProvider.createReservation(
        packageId: widget.package.id,
        packageTitle: widget.package.title,
        customerId: authProvider.currentUser!.id,
        customerName: authProvider.currentUser!.name,
        guideName: widget.package.guideName,
        guideId: widget.package.guideId,
        reservationDate: _selectedDay!,
        price: (widget.package.price * _selectedParticipants),
        participants: _selectedParticipants,
      );

      // Toss Payments 결제 화면으로 이동 
      PaymentData paymentData = PaymentData(
        paymentMethod: '카드',
        orderId: 'tosspaymentsFlutter_${DateTime.now().millisecondsSinceEpoch}',
        orderName: widget.package.title,
        amount: (widget.package.price * _selectedParticipants).toInt(),
        customerName: authProvider.currentUser!.name,
        customerEmail: authProvider.currentUser!.id,
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentProcess(paymentData: paymentData),
        ),
      );

      // 결제 성공 여부 확인 후 처리
      if (result != null && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('reservation_calendar.request.success'.tr())),
          );
          context.pop(); // 이전 화면으로 돌아가기
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '결제에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('reservation_calendar.request.error'
                  .tr(namedArgs: {'error': e.toString()}))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text('reservation_calendar.title'.tr()),
            scrolledUnderElevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(),
                TableCalendar(
                  locale: context.locale.languageCode, // 현재 선택된 언어 적용
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  enabledDayPredicate: (day) {
                    if (day.isBefore(DateTime.now())) return false;
                    if (!_isValidDepartureDay(day)) return false;
                    final dateKey = _getDateKey(day);
                    return _availabilityCache[dateKey] ?? true;
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (selectedDay.isBefore(DateTime.now())) return;

                    if (!_isValidDepartureDay(selectedDay)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'reservation_calendar.date.unavailable_error'
                                    .tr())),
                      );
                      return;
                    }

                    final dateKey = _getDateKey(selectedDay);
                    final isAvailable = _availabilityCache[dateKey] ?? true;

                    if (isAvailable) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'reservation_calendar.date.booked_error'
                                      .tr())),
                        );
                      }
                    }
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _availabilityCache.clear();
                    });
                    _preloadAvailability();
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      bool isDepartureDay = _isValidDepartureDay(date);
                      return Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isDepartureDay
                              ? Colors.blue.shade50
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isDepartureDay &&
                                      !date.isBefore(DateTime.now())
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, date, _) {
                      return Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                    disabledBuilder: (context, date, _) {
                      return Container(
                        margin: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    todayDecoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: Colors.blue),
                    disabledTextStyle: const TextStyle(color: Colors.grey),
                    defaultDecoration:
                        const BoxDecoration(shape: BoxShape.circle),
                    weekendDecoration:
                        const BoxDecoration(shape: BoxShape.circle),
                    outsideDecoration:
                        const BoxDecoration(shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                if (_selectedDay != null) ...[
                  Padding(
                    padding: EdgeInsets.all(16.0.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'reservation_calendar.date.selected'.tr(namedArgs: {
                            'date': DateFormat('yyyy년 MM월 dd일')
                                .format(_selectedDay!)
                          }),
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'reservation_calendar.date.package'.tr(namedArgs: {
                            'title': _getLocalizedTitle(context, widget.package)
                          }),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'reservation_calendar.date.duration'
                                  .tr(namedArgs: {
                                'nights': widget.package.nights.toString(),
                                'days': (widget.package.nights + 1).toString()
                              }),
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children:
                                    widget.package.departureDays.map((day) {
                                  final weekdayKey = [
                                    'mon',
                                    'tue',
                                    'wed',
                                    'thu',
                                    'fri',
                                    'sat',
                                    'sun'
                                  ][day - 1];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      'reservation_calendar.date.weekdays.$weekdayKey'
                                          .tr(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'reservation_calendar.price'.tr(namedArgs: {
                            'price': NumberFormat('#,###')
                                .format((widget.package.price * _selectedParticipants).toInt())
                          }),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        SizedBox(height: 16.h),
                        _buildParticipantSelector(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar:
              _selectedDay != null // 예약 버튼을 bottomNavigationBar로 이동
                  ? Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: ElevatedButton(
                        onPressed: () => _requestReservation(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          minimumSize: Size(double.infinity, 50.h),
                        ),
                        child: Text(
                          'reservation_calendar.submit'.tr(),
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    )
                  : null,
        ),
      ),
    );
  }

  String _getLocalizedTitle(BuildContext context, TravelPackage package) {
    final locale = context.locale.languageCode;
    switch (locale) {
      case 'en':
        return package.titleEn ?? package.title;
      case 'ja':
        return package.titleJa ?? package.title;
      case 'zh':
        return package.titleZh ?? package.title;
      default:
        return package.title;
    }
  }
}
