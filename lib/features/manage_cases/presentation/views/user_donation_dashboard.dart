import 'package:cached_network_image/cached_network_image.dart';
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

          final donation = state.donations.first;
          final contacts = (donation['contacts'] as List<dynamic>?)
                  ?.map((e) => ContactPerson.fromMap(e))
                  .toList() ??
              [];
          final imageUrl = donation['mealImageUrl'] as String?;
          final carouselImages = donation['carouselImages'] != null
              ? List<String>.from(donation['carouselImages'])
              : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : []);
          final title = donation['mealTitle'] ?? 'وجبة اليوم';
          final description = donation['mealDescription'] ?? '';
          final individuals = donation['numberOfIndividuals'] as int? ?? 1;

          return CustomScrollView(
            slivers: [
              // 1. Premium Carousel / Image Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black, // Background for contain fit
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: carouselImages.isEmpty
                            ? Container(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.1),
                                child: const Icon(Icons.restaurant,
                                    size: 60, color: AppColors.primaryColor),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  CarouselSlider(
                                    items: carouselImages.map((url) {
                                      return Center(
                                        child: CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child:
                                                Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, _) =>
                                              Container(
                                                  color: Colors.grey[300]),
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
                                  // Premium Gradient Overlay
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black87
                                        ],
                                        stops: [0.5, 1.0],
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
                            color: Colors.grey[300]!,
                            activeColor: AppColors.primaryColor,
                            size: const Size.square(8.0),
                            activeSize: const Size(24.0, 8.0),
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
                          // 1. Meal Info Section
                          _buildInfoCard(
                            context,
                            title: title,
                            description: description,
                          ),
                          const SizedBox(height: 20),

                          // 3. Stats Section
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
                                child: BlocBuilder<ExpenseCubit, ExpenseState>(
                                  builder: (context, expenseState) {
                                    double costPerPerson = 0.0;
                                    if (expenseState is ExpenseLoaded) {
                                      final today = DateTime.now()
                                          .toIso8601String()
                                          .split('T')[0];
                                      double totalExpenses = expenseState
                                          .expenses
                                          .where((e) => e.date == today)
                                          .fold(
                                              0.0, (sum, e) => sum + e.amount);
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

                          const SizedBox(height: 24),
                          const Text(
                            'شاركنا الأثر والخير',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DIN',
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 4. Actionable Help Cards
                          _buildActionCards(context, contacts),

                          // Space for floating button
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildInfoCard(BuildContext context,
      {required String title, required String description}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.restaurant,
                    color: AppColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DIN'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style:
                TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.6),
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
                color: Color(0xFF1E293B)),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500),
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
}
