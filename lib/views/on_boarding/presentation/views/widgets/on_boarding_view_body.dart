import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/utils/app_texts.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import '../../../../../core/routes/app_routes.dart';
import 'custom_dots_indicators.dart';
import 'on_boarding_page_view.dart';
import 'row_buttons.dart';

class OnBoardingViewBody extends StatefulWidget {
  const OnBoardingViewBody({super.key});

  @override
  State<OnBoardingViewBody> createState() => _OnBoardingViewBodyState();
}

class _OnBoardingViewBodyState extends State<OnBoardingViewBody> {
  late PageController pageController;
  @override
  void initState() {
    pageController = PageController(initialPage: 0)
      ..addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          child: OnBoardingPageView(
            controller: pageController,
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.2,
          right: 10,
          left: 10,
          child: CustomDotsIndicators(
            dotIndex:
                pageController.hasClients ? pageController.page!.round() : 0,
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.05,
          right: 10,
          left: 10,
          child: pageController.hasClients && pageController.page! > 1
              ? GeneralButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.loginOrRegister);
                  },
                  text: AppTexts.letsStart,
                  backgroundColor: AppColors.primaryColor,
                  textColor: AppColors.whiteColor,
                )
              : RowButtons(pageController: pageController),
        ),
      ],
    );
  }
}
