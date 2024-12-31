import 'package:flutter/material.dart';

class ThemeModeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ThemeModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 35,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: value ? Colors.indigo.withOpacity(0.5) : Colors.amber.shade200,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 아이콘들
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.only(right: 4),
                alignment: Alignment.centerRight,
                child: const Icon(
                  Icons.nightlight_round,
                  size: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: value ? 0 : 1,
              child: Container(
                padding: const EdgeInsets.only(left: 4),
                alignment: Alignment.centerLeft,
                child: const Icon(
                  Icons.wb_sunny,
                  size: 14,
                  color: Colors.white70,
                ),
              ),
            ),
            // 이동하는 원형 버튼
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    value ? Icons.nightlight_round : Icons.wb_sunny,
                    key: ValueKey(value),
                    size: 16,
                    color: value ? Colors.indigo : Colors.amber,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
