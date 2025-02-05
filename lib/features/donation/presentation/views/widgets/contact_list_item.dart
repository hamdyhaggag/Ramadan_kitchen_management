import 'package:flutter/material.dart';
import 'action_button.dart';
import 'contact_info_row.dart';
import 'contact_person.dart';

class ContactListItem extends StatelessWidget {
  final ContactPerson contact;

  const ContactListItem({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContactInfoRow(
            label: 'فودافون كاش',
            icon: Icons.account_balance_wallet_rounded,
            value: contact.formattedPhoneNumber,
          ),
          const SizedBox(height: 8),
          if (contact.additionalPaymentInfo != null &&
              contact.additionalPaymentInfo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ContactInfoRow(
              label: 'اتصالات كاش',
              icon: Icons.account_balance_wallet_rounded,
              value: contact.formattedAdditionalPaymentInfo,
            ),
          ],
          const SizedBox(height: 8),
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
    );
  }
}
