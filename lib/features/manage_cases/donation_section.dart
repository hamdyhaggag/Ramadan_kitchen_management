import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../donation/presentation/cubit/donation_cubit.dart';

class DonationSection extends StatelessWidget {
  const DonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationCubit, DonationState>(
      builder: (context, state) {
        if (state is DonationLoaded) {
          final contacts = (state.donationData['contacts'] as List<dynamic>)
              .map((e) => ContactPerson.fromMap(e))
              .toList();

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  flexibleSpace:
                      _MealHeader(imageUrl: state.donationData['mealImageUrl']),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.donationData['mealTitle'],
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.donationData['mealDescription'],
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            'تواصل معنا للمساهمة ودعم المطبخ',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio:
                          MediaQuery.of(context).size.width > 600 ? 0.8 : 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _DonorCard(contact: contacts[index]),
                      childCount: contacts.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _MealHeader extends StatelessWidget {
  final String imageUrl;

  const _MealHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade100,
              child: const Icon(Icons.restaurant, size: 60, color: Colors.grey),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final ContactPerson contact;

  const _DonorCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _launchWhatsApp(contact.phoneNumber),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isMobile ? 100 : 120,
                    height: isMobile ? 100 : 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: contact.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(contact.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey.shade100,
                      border:
                          Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: contact.photoUrl == null
                        ? Icon(Icons.person_outline_rounded,
                            size: isMobile ? 40 : 50,
                            color: Colors.grey.shade400)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    contact.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.role != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      contact.role!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ContactTile(
                          icon: Icons.phone_iphone_rounded,
                          value: contact.formattedPhoneNumber,
                          onCopy: () =>
                              _copyToClipboard(contact.phoneNumber, context),
                        ),
                        if (contact.bankAccount != null) ...[
                          const SizedBox(height: 12),
                          _ContactTile(
                            icon: Icons.account_balance_rounded,
                            value: contact.bankAccount!,
                            onCopy: () =>
                                _copyToClipboard(contact.bankAccount!, context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.copy_rounded,
                              size: 18, color: Colors.grey.shade700),
                          label: Text('نسخ',
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: () =>
                              _copyToClipboard(contact.phoneNumber, context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: const Text('واتساب',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _launchWhatsApp(contact.phoneNumber),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchWhatsApp(String number) async {
    final url = "https://wa.me/$number";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _copyToClipboard(String text, BuildContext context) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم النسخ بنجاح"),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    });
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onCopy;

  const _ContactTile({
    required this.icon,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onCopy,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactPerson {
  final String name;
  final String phoneNumber;
  final String role;
  final String bankAccount;
  final String? photoUrl;

  const ContactPerson({
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.bankAccount,
    this.photoUrl,
  });

  factory ContactPerson.fromMap(Map<String, dynamic> map) {
    return ContactPerson(
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      bankAccount: map['bankAccount']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role,
        'bankAccount': bankAccount,
        'photoUrl': photoUrl,
      };

  String get formattedPhoneNumber {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 7) return phoneNumber;

    final displayNumber = cleanNumber.startsWith('2') && cleanNumber.length > 2
        ? cleanNumber.substring(1)
        : cleanNumber;

    return '\u200E${displayNumber.substring(0, 3)} '
        '${displayNumber.substring(3, 6)} '
        '${displayNumber.substring(6)}';
  }

  ContactPerson copyWith({
    String? name,
    String? phoneNumber,
    String? role,
    String? bankAccount,
    String? photoUrl,
  }) {
    if (name == null &&
        phoneNumber == null &&
        role == null &&
        bankAccount == null &&
        photoUrl == null) return this;

    return ContactPerson(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      bankAccount: bankAccount ?? this.bankAccount,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
