import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../donation/presentation/cubit/donation_cubit.dart';
import '../donation/presentation/views/widgets/contact_person.dart';

class DonationSection extends StatefulWidget {
  const DonationSection({super.key});

  @override
  State<DonationSection> createState() => _DonationSectionState();
}

class _DonationSectionState extends State<DonationSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationCubit>().fetchDonationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationCubit, DonationState>(
      builder: (context, state) {
        if (state is DonationLoaded) {
          final contacts = (state.donationData['contacts'] as List<dynamic>)
              .map((e) => ContactPerson.fromMap(e))
              .toList();

          return Scaffold(
            body: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                await context.read<DonationCubit>().fetchDonationData();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight:
                        MediaQuery.of(context).size.width * (1180 / 1500),
                    flexibleSpace: _MealHeader(
                        imageUrl: state.donationData['mealImageUrl']),
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
                      horizontal: MediaQuery.of(context).size.width * 0.1,
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
                        (context, index) =>
                            _DonorCard(contact: contacts[index]),
                        childCount: contacts.length,
                      ),
                    ),
                  ),
                ],
              ),
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
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Text(
                'لا يوجد صورة حتى الان',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                  const SizedBox(height: 10),
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
                  ...[
                    const SizedBox(height: 8),
                    Text(
                      contact.role,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                        ...[
                          const SizedBox(height: 12),
                          _ContactTile(
                            icon: Icons.account_balance_rounded,
                            value: contact.bankAccount,
                            onCopy: () =>
                                _copyToClipboard(contact.bankAccount, context),
                          ),
                        ],
                      ],
                    ),
                  ),
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
