import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/model/paymentData.dart';
import 'payment_process.dart';

void main() {
  runApp(const PaymentEntry());
}

class PaymentEntry extends StatelessWidget {
  const PaymentEntry({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tosspayments Flutter Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toss Payments 결제 시작'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 결제 데이터 기본값 설정
            PaymentData data = PaymentData(
              paymentMethod: '카드',
              orderId:
                  'tosspaymentsFlutter_${DateTime.now().millisecondsSinceEpoch}',
              orderName: '서울 맛집 탐방 여행',
              amount: 12345,
              customerName: '김엘리스',
              customerEmail: 'elice@elice.com',
            );

            // Flutter의 Navigator.push를 사용하여 PaymentProcess로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentProcess(paymentData: data),
              ),
            );
          },
          child: const Text('결제하기'),
        ),
      ),
    );
  }
}
