import 'package:flutter/material.dart';

import '../../../../../core/utils/app_colors.dart';
import 'contact_person.dart';

class ContactHeader extends StatelessWidget {
  final ContactPerson contact;

  const ContactHeader({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: contact.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(contact.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
          child: contact.photoUrl == null
              ? Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryColor,
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                contact.role,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
