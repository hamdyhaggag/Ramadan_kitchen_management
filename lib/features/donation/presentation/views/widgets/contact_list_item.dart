import 'package:flutter/material.dart';

import 'action_button.dart';
import 'contact_header.dart';
import 'contact_info_row.dart';
import 'contact_person.dart';

class ContactListItem extends StatelessWidget {
  final ContactPerson contact;

  const ContactListItem({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      elevation: 2,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContactHeader(contact: contact),
            const SizedBox(height: 16),
            ContactInfoRow(
              label: 'خدمات كاش',
              icon: Icons.account_balance_wallet_rounded,
              value: contact.formattedPhoneNumber,
            ),
            if (contact.bankAccount != null &&
                contact.bankAccount!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ContactInfoRow(
                label: 'انستاباي',
                icon: Icons.account_balance_rounded,
                value: contact.bankAccount!,
              ),
            ],
            const SizedBox(height: 16),
            ActionButtons(contact: contact),
          ],
        ),
      ),
    );
  }
}
