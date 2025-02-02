import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_person.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubit/donation_cubit.dart';

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
                  expandedHeight: 280,
                  flexibleSpace: _HeaderImage(
                      imageUrl: state.donationData['mealImageUrl']),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _MealTitle(title: state.donationData['mealTitle']),
                        const SizedBox(height: 16),
                        _MealDescription(
                            description: state.donationData['mealDescription']),
                        const SizedBox(height: 32),
                        _SectionTitle(title: 'للتبرع للمطبخ'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _ContactListItem(contact: contacts[index]),
                      childCount: contacts.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          );
        }
        return const Center(
            child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ));
      },
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final String imageUrl;

  const _HeaderImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[100],
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.fastfood_rounded,
                size: 50, color: Colors.grey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTitle extends StatelessWidget {
  final String title;

  const _MealTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.grey[900],
          ),
    );
  }
}

class _MealDescription extends StatelessWidget {
  final String description;

  const _MealDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.6,
          ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
        ),
      ],
    );
  }
}

class _ContactListItem extends StatelessWidget {
  final ContactPerson contact;

  const _ContactListItem({required this.contact});

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
            _ContactHeader(contact: contact),
            const SizedBox(height: 16),
            _ContactInfoRow(
              label: 'خدمات كاش',
              icon: Icons.phone_rounded,
              value: contact.formattedPhoneNumber,
            ),
            const SizedBox(height: 8),
            _ContactInfoRow(
              label: 'انستاباي',
              icon: Icons.account_balance_rounded,
              value: contact.bankAccount,
            ),
            const SizedBox(height: 16),
            _ActionButtons(contact: contact),
          ],
        ),
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  final ContactPerson contact;

  const _ContactHeader({required this.contact});

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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                contact.role,
                style: TextStyle(
                  fontSize: 14,
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

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ContactInfoRow({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[50],
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      AppColors.primaryColor.withValues(alpha: 0.1),
                  radius: 16,
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () => _copyToClipboard(context, value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    FlutterClipboard.copy(text).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم نسخ الحساب"),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}

class _ActionButtons extends StatelessWidget {
  final ContactPerson contact;

  const _ActionButtons({required this.contact});

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
