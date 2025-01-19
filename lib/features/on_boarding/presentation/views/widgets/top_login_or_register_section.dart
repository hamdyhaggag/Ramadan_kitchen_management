import 'package:flutter/material.dart';

import '../../../../../core/utils/app_styles.dart';
import '../../../../../core/utils/app_texts.dart';

class TopLoginOrRegisterSection extends StatelessWidget {
  const TopLoginOrRegisterSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppTexts.letsGo,
          style: AppStyles.cairoBold32,
        ),
        SizedBox(height: 15),
        Text(
          AppTexts.pickOnefromTheOptions,
          style: AppStyles.cairoRegular16,
        )
      ],
    );
  }
}
