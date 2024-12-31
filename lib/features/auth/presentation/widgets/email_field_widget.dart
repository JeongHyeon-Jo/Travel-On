import 'package:flutter/material.dart';
import 'text_field_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmailFieldWidget extends StatefulWidget {
  final TextEditingController emailIdController;
  final TextEditingController emailDomainController;
  final Function(String) onDomainSelected;
  final String selectedDomain;

  EmailFieldWidget({
    required this.emailIdController,
    required this.emailDomainController,
    required this.onDomainSelected,
    required this.selectedDomain,
  });

  @override
  _EmailFieldWidgetState createState() => _EmailFieldWidgetState();
}

class _EmailFieldWidgetState extends State<EmailFieldWidget> {
  final List<String> _emailDomains = ['naver.com', 'gmail.com', 'daum.net', '직접 입력'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFieldWidget(
            controller: widget.emailIdController,
            labelText: '이메일 아이디',
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0.w),
          child: Text('@'),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: widget.selectedDomain == '직접 입력'
                        // 직접 입력이면 TextField 활성화 아닐경우 Text 활성화 
                      ? TextField(
                          controller: widget.emailDomainController,
                          decoration: InputDecoration(
                            hintText: '직접 입력',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.blue),
                          ),
                        )
                      : Text(
                          widget.selectedDomain,
                          style: TextStyle(color: Colors.blue, fontSize: 14.sp,),
                        ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
                  onSelected: (value) {
                    widget.onDomainSelected(value);
                  },
                  itemBuilder: (context) => _emailDomains
                      .map((domain) => PopupMenuItem(
                            value: domain,
                            child: Text(domain, style: TextStyle(color: Colors.blue, fontSize: 14.sp,)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
