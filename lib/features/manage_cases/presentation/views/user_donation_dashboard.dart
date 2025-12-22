import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_state.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/cubit/donation_cubit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_list_item.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_person.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDonationDashboard extends StatefulWidget {
  const UserDonationDashboard({super.key});

  @override
  State<UserDonationDashboard> createState() => _UserDonationDashboardState();
}

class _UserDonationDashboardState extends State<UserDonationDashboard> {
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationCubit, DonationState>(
      builder: (context, state) {
        if (state is DonationLoaded) {
          if (state.donations.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('لا توجد بيانات لوجبة اليوم')),
            );
          }

          final now = DateTime.now();
          final todayStr = "${now.year}-${now.month}-${now.day}";

          // Try to find today's donation first
          var donation = state.donations.firstWhere(
            (d) {
              final createdAt = d['created_at'];
              if (createdAt is Timestamp) {
                final date = createdAt.toDate();
                return "${date.year}-${date.month}-${date.day}" == todayStr;
              }
              return false;
            },
            orElse: () => state.donations.first,
          );
          final contacts = (donation['contacts'] as List<dynamic>?)
                  ?.map((e) => ContactPerson.fromMap(e))
                  .toList() ??
              [];
          final imageUrl = donation['mealImageUrl'] as String?;
          final List<String> carouselImages =
              (donation['carouselImages'] != null &&
                      (donation['carouselImages'] as List).isNotEmpty)
                  ? List<String>.from(donation['carouselImages'])
                  : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : []);
          final title = donation['mealTitle'] ?? 'وجبة اليوم';
          final description = donation['mealDescription'] ?? '';
          final individuals = donation['numberOfIndividuals'] as int? ?? 1;

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<DonationCubit>().getDonations();
                context.read<ExpenseCubit>().loadExpenses();
                await Future.delayed(const Duration(seconds: 1));
              },
              color: AppColors.primaryColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: carouselImages.isEmpty
                                ? Container(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.restaurant,
                                        size: 60,
                                        color: AppColors.primaryColor),
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CarouselSlider(
                                        items: carouselImages.map((url) {
                                          return GestureDetector(
                                            onTap: () {
                                              _showFullScreenImage(
                                                  context, url, title);
                                            },
                                            child: Center(
                                              child: CachedNetworkImage(
                                                imageUrl: url,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                placeholder: (context, url) =>
                                                    Shimmer.fromColors(
                                                  baseColor: Colors.grey[300]!,
                                                  highlightColor:
                                                      Colors.grey[100]!,
                                                  child: Container(
                                                      color: Colors.white),
                                                ),
                                                errorWidget: (context, url,
                                                        _) =>
                                                    Container(
                                                        color:
                                                            Colors.grey[300]),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        options: CarouselOptions(
                                          height: 200,
                                          viewportFraction: 1.0,
                                          autoPlay: carouselImages.length > 1,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _currentCarouselIndex = index;
                                            });
                                          },
                                        ),
                                      ),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(
                                                  0x99000000), // black with 0.6 opacity (approx)
                                            ],
                                            stops: [0.6, 1.0],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (carouselImages.length > 1) ...[
                            const SizedBox(height: 12),
                            DotsIndicator(
                              dotsCount: carouselImages.length,
                              position: _currentCarouselIndex,
                              decorator: DotsDecorator(
                                color: Colors.grey[200]!,
                                activeColor: AppColors.primaryColor,
                                size: const Size.square(6.0),
                                activeSize: const Size(18.0, 6.0),
                                activeShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
                                spacing:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 2. Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: AnimationLimiter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 600),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              horizontalOffset: 30.0,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              // 1. Today's Stats (Core Context)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      context,
                                      label: 'عدد الأفراد',
                                      value: '$individuals',
                                      icon: Iconsax.people,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child:
                                        BlocBuilder<ExpenseCubit, ExpenseState>(
                                      builder: (context, expenseState) {
                                        double costPerPerson = 0.0;
                                        if (expenseState is ExpenseLoaded) {
                                          final today = DateTime.now()
                                              .toIso8601String()
                                              .split('T')[0];
                                          double totalExpenses = expenseState
                                              .expenses
                                              .where((e) => e.date == today)
                                              .fold(0.0,
                                                  (sum, e) => sum + e.amount);
                                          if (individuals > 0) {
                                            costPerPerson =
                                                totalExpenses / individuals;
                                          }
                                        }
                                        return _buildStatCard(
                                          context,
                                          label: 'تكلفة الفرد',
                                          value: costPerPerson > 0
                                              ? '${costPerPerson.toStringAsFixed(1)} ج'
                                              : '---',
                                          icon: Iconsax.money_send,
                                          color: Colors.green,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 2. Primary Action (Conversion Point)
                              _buildActionCards(context, contacts),
                              const SizedBox(height: 24),

                              // 3. Today's Meal & Components (Visual Context)
                              _buildTodayMealImage(
                                  imageUrl, title, description),
                              const SizedBox(height: 24),

                              // 4. Total Impact (Social Proof/Trust)
                              _buildTotalImpact(state.donations),
                              const SizedBox(height: 24),

                              // 5. Yesterday's Highlight (Confirmation of Action)
                              if (state.donations.length > 1)
                                _buildYesterdayHighlight(state.donations[1]),
                              const SizedBox(height: 24),

                              // 6. Quick Support
                              _buildSupportCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is DonationError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor)),
        );
      },
    );
  }

  Widget _buildTodayMealImage(
      String? imageUrl, String title, String description) {
    final ingredients = description.isNotEmpty
        ? description
            .split(RegExp(r'\+|\,'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'وجبة اليوم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'مباشر من المطبخ',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _showFullScreenImage(context, imageUrl, title);
            }
          },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey, size: 40),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5)
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomRight,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'عرض الصورة كاملة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.fullscreen, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
          ),
        ),
        if (ingredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'مكونات الوجبة:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                ingredients.map((item) => _buildIngredientChip(item)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
                color: Color(0xFF0F172A)),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showDonationOptions(
      BuildContext context, List<ContactPerson> contacts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'طرق التبرع المتاحة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: contacts.length,
                itemBuilder: (context, index) => ContactListItem(
                  contact: contacts[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, List<ContactPerson> contacts) {
    return _buildSingleActionCard(
      title: 'كفالة وجبة إفطار',
      subtitle: 'ساهم في إطعام صائم بضغطة زر واحدة',
      icon: Iconsax.wallet_3, // Professional wallet icon
      color: AppColors.primaryColor,
      isFullWidth: true,
      onTap: () => _showDonationOptions(context, contacts),
    );
  }

  Widget _buildSingleActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'DIN',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalImpact(List<dynamic> donations) {
    // Basic aggregation for display
    int totalIndividuals = 0;
    for (var d in donations) {
      totalIndividuals += (d['numberOfIndividuals'] as int? ?? 0);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'أثرنا التراكمي',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImpactMetric(
                label: 'إجمالي الوجبات',
                value: totalIndividuals.toString(),
                icon: Iconsax.box_2,
              ),
              Container(width: 1, height: 40, color: Colors.grey[100]),
              _buildImpactMetric(
                label: 'أيام العطاء',
                value: donations.length.toString(),
                icon: Iconsax.calendar_1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(
      {required String label, required String value, required IconData icon}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 28),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'DIN',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildYesterdayHighlight(dynamic yesterdayData) {
    final imageUrl = yesterdayData['mealImageUrl'] as String?;
    final title = yesterdayData['mealTitle'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'لمحة من وجبة أمس',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'سِجل العطاء',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _showFullScreenImage(context, imageUrl, title);
            }
          },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'DIN',
                      ),
                    ),
                  ),
                  const Icon(Iconsax.arrow_right_3,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return InkWell(
      onTap: _launchWhatsApp,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عندك استفسار؟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'DIN',
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'تواصل معنا مباشرة عبر واتساب',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.messages,
                color: AppColors.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = "+201033420527";
    final whatsappUrl = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showFullScreenImage(
      BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DIN',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
