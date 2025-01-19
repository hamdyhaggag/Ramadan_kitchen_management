import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_styles.dart';
import 'package:ramadan_kitchen_management/features/on_boarding/data/models/on_boarding_model.dart';

class OnBoardingPageViewItem extends StatelessWidget {
  const OnBoardingPageViewItem({
    super.key,
    required this.onBoardingModel,
  });
  final OnBoardingModel onBoardingModel;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .15),
          Image.asset(
            onBoardingModel.image,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            onBoardingModel.title,
            style: AppStyles.cairoBold24,
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              onBoardingModel.subtitle,
              style: AppStyles.cairoRegular16,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * .25),
        ],
      ),
    );
  }
}
