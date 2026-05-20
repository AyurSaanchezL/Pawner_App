import 'package:flutter/widgets.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pawner_app/core/app_colors.dart';

class CustomNumberPicker extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final int val;
  final int min;
  final int max;
  final Function(int) onChanged;
  final BuildContext context;
  const CustomNumberPicker({
    super.key,
    required this.context,
    required this.label,
    required this.backgroundColor,
    required this.val,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),
      width: 50,
      child: Column(
        children: [
          if (label.isNotEmpty) Text(label),
          NumberPicker(
            decoration: BoxDecoration(
              border: Border.all(color: backgroundColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            minValue: min,
            maxValue: max,
            value: val,
            onChanged: onChanged,
            itemHeight: 40,
            textStyle: TextStyle(color: AppColors.dark, fontSize: 13),
            selectedTextStyle: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}
