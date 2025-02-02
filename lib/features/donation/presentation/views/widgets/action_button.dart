import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/widgets/general_button.dart';
import 'contact_person.dart';

class ActionButtons extends StatelessWidget {
  final ContactPerson contact;

  const ActionButtons({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: GeneralButton(
                onPressed: () => _launchWhatsApp(contact.phoneNumber),
                text: 'للتواصل واتساب',
                backgroundColor: AppColors.primaryColor,
                textColor: AppColors.whiteColor)),
      ],
    );
  }

  void _launchWhatsApp(String number) async {
    final url = "https://wa.me/$number";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
