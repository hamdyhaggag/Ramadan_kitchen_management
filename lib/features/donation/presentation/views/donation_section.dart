import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_list_item.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_person.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/header_image.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/meal_description.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/meal_title.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/section_title.dart';
import 'package:shimmer/shimmer.dart';
import '../../../daily_expenses/logic/expense_state.dart';
import '../cubit/donation_cubit.dart';

class DonationSection extends StatelessWidget {
  const DonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationCubit, DonationState>(
      builder: (context, state) {
        if (state is DonationLoaded) {
          final contacts = (state.donations.first['contacts'] as List<dynamic>)
              .map((e) => ContactPerson.fromMap(e))
              .toList();
          final carouselImages = state.donations.first['carouselImages'] != null
              ? List<String>.from(state.donations.first['carouselImages'])
              : [state.donations.first['mealImageUrl']];
          return Scaffold(
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CarouselSlider(
                    items: carouselImages.map((url) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        MealTitle(title: state.donations.first['mealTitle']),
                        const SizedBox(height: 12),
                        MealDescription(
                            description:
                                state.donations.first['mealDescription']),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SectionTitle(
                              title: 'عدد الأفراد لهذا اليوم:',
                            ),
                            const SizedBox(width: 8),
                            Card(
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.whiteColor,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Text(
                                  '${state.donations.first['numberOfIndividuals']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blackColor,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'فرد',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: AppColors.blackColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SectionTitle(title: 'تكلفة الفرد:'),
                            const SizedBox(width: 8),
                            BlocBuilder<ExpenseCubit, ExpenseState>(
                              builder: (context, expenseState) {
                                double totalExpenses = 0.0;
                                if (expenseState is ExpenseLoaded) {
                                  final today = DateTime.now()
                                      .toIso8601String()
                                      .split('T')[0];
                                  totalExpenses = expenseState.expenses
                                      .where((expense) => expense.date == today)
                                      .fold(
                                          0.0,
                                          (sum, expense) =>
                                              sum + expense.amount);
                                }
                                return Card(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: AppColors.whiteColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    child: Text(
                                      '${(totalExpenses / (state.donations.first['numberOfIndividuals'] as int)).toStringAsFixed(2)} ج.م',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blackColor,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        HeaderImage(
                            imageUrl: state.donations.first['mealImageUrl']),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _showDonationOptions(context, contacts);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'للتبرع',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          );
        } else if (state is DonationError) {
          return Center(child: Text(state.message));
        }
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
        );
      },
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
        padding: const EdgeInsets.only(top: 16),
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
            const SizedBox(height: 16),
            const Text(
              'تقدر تتبرع من خلال',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
            const SizedBox(height: 16),
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
