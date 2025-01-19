import 'package:flutter/material.dart';

import '../utils/app_styles.dart';

class GeneralButton extends StatelessWidget {
  const GeneralButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.height = 50,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          backgroundColor: backgroundColor,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: AppStyles.cairoRegular16
              .copyWith(color: textColor, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
