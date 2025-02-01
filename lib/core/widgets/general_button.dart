import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import '../utils/app_styles.dart';

class GeneralButton extends StatelessWidget {
  const GeneralButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.height = 50,
    this.icon,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double? height;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: backgroundColor,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(color: AppColors.whiteColor),
                child: icon!,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppStyles.dinRegular16
                  .copyWith(color: textColor, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
