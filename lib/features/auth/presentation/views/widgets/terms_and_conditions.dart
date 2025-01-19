import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_styles.dart';
import '../../../../../core/utils/app_texts.dart';
import 'custom_check_box.dart';

class TermsAncConditions extends StatefulWidget {
  const TermsAncConditions({
    super.key,
    required this.onChanged,
  });
  final ValueChanged<bool> onChanged;

  @override
  State<TermsAncConditions> createState() => _TermsAncConditionsState();
}

class _TermsAncConditionsState extends State<TermsAncConditions> {
  bool isTermsAccepted = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomCheckBox(
            isChecked: isTermsAccepted,
            onChecked: (bool value) {
              isTermsAccepted = value;
              widget.onChanged(value);
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(
              children: [
                TextSpan(
                  text: AppTexts.fromCreatinganAccount,
                  style: AppStyles.cairoRegular16.copyWith(
                    color: AppColors.blackColor,
                  ),
                ),
                TextSpan(
                  text: AppTexts.youAreAccept,
                  style: AppStyles.cairoRegular16.copyWith(
                    color: AppColors.blackColor,
                  ),
                ),
                const TextSpan(
                  text: AppTexts.termsAndConditions,
                  style: AppStyles.cairoRegular16,
                ),
                TextSpan(
                  text: AppTexts.privacyPolicy,
                  style: AppStyles.cairoRegular16.copyWith(
                    color: AppColors.blackColor,
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}
