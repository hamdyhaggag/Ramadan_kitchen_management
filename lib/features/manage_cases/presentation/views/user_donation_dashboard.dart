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

class UserDonationDashboard extends StatelessWidget {
  const UserDonationDashboard({super.key});

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
          final title = donation['mealTitle'] ?? 'وجبة اليوم';
          final description = donation['mealDescription'] ?? '';
          final individuals = donation['numberOfIndividuals'] as int? ?? 1;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // 1. Meal Image Card (Replaces SliverAppBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Container(
                        height: 220,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (context, url, _) =>
                                    Container(color: Colors.grey[300]),
                              )
                            else
                              Container(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.2),
                                child: const Icon(Icons.restaurant,
                                    size: 50, color: AppColors.primaryColor),
                              ),
                            // Gradient Overlay
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black54],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                            // Title Overlay
                            Positioned(
                              bottom: 16,
                              right: 20,
                              child: Text(
                                'مطبخ رمضان',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontFamily: 'DIN',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Content Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meal Info Card
                          _buildInfoCard(
                            context,
                            title: title,
                            description: description,
                          ),
                          const SizedBox(height: 20),

                          // Stats Row (Individuals & Cost)
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  label: 'عدد الأفراد',
                                  value: '$individuals',
                                  icon: Icons.people_outline,
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
                                      icon: Icons.monetization_on_outlined,
                                      color: Colors.green,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'كيف يمكنك المساعدة؟',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'مساهمتك بتساعدنا نوفر وجبات إفطار صائم لأسر كتير. تقدر تتبرع بتكلفة وجبة أو أكتر، أو تشاركنا بالمجهود.',
                            style: TextStyle(
                                color: Colors.grey, height: 1.5, fontSize: 15),
                          ),

                          // Space for floating button
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 3. Floating Action Bar
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: ElevatedButton(
                  onPressed: () => _showDonationOptions(context, contacts),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primaryColor.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volunteer_activism),
                      SizedBox(width: 8),
                      Text(
                        'تبرع الآن',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child:
                    const Icon(Icons.restaurant, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style:
                TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.6),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'طرق التبرع المتاحة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
