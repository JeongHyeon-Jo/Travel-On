import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/model/paymentData.dart';
import 'package:tosspayments_widget_sdk_flutter/model/tosspayments_result.dart';
import 'package:tosspayments_widget_sdk_flutter/pages/tosspayments_sdk_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentProcess extends StatefulWidget {
  final PaymentData paymentData;

  const PaymentProcess({super.key, required this.paymentData});

  @override
  State<PaymentProcess> createState() => _PaymentProcessState();
}

class _PaymentProcessState extends State<PaymentProcess> {
  late PaymentData data;

  @override
  void initState() {
    super.initState();
    data = widget.paymentData;
    print("초기화된 PaymentData: $data");
  }

  Future<void> confirmPayment(String paymentKey) async {
    final url =
        Uri.parse('https://travelon.onrender.com/confirm'); // Render URL

    try {
      final requestData = {
        'paymentKey': paymentKey,
        'orderId': data.orderId,
        'amount': data.amount.toInt(),
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        print('결제 승인 성공');
        await verifyPayment(paymentKey);
      } else {
        throw Exception('결제 승인 실패');
      }
    } catch (error) {
      throw Exception('결제 승인 중 오류 발생: $error');
    }
  }

  Future<void> verifyPayment(String paymentKey) async {
    final url =
        Uri.parse('https://travelon.onrender.com/verifyPayment'); // Render URL

    try {
      final requestData = {
        'paymentKey': paymentKey,
        'orderId': data.orderId,
        'buyer': data.customerName,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (mounted) {
          Navigator.pop(context, {
            'success': true,
            'message': responseData['message'] ?? '결제가 성공적으로 완료되었습니다.',
          });
        }
      } else {
        throw Exception('결제 검증 실패');
      }
    } catch (error) {
      throw Exception('결제 검증 중 오류 발생: $error');
    }
  }

  void handlePaymentSuccess(Success success) async {
    try {
      await confirmPayment(success.paymentKey);
    } catch (error) {
      if (mounted) {
        Navigator.pop(context, {'success': false, 'message': '결제 실패'});
      }
    }
  }

  void handlePaymentFailure(Fail fail) {
    if (mounted) {
      Navigator.pop(context, {'success': false, 'message': '결제 실패'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toss Payments 결제'),
      ),
      body: Center(
        child: TossPayments(
          clientKey: 'test_ck_GePWvyJnrKjNdbKddLZ6VgLzN97E',
          data: data,
          success: handlePaymentSuccess,
          fail: handlePaymentFailure,
        ),
      ),
    );
  }
}
