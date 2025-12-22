import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../daily_expenses/logic/expense_cubit.dart';
import '../../../daily_expenses/logic/expense_state.dart';
import 'details_of_previous_days.dart';

class DonationCardOfPrevious extends StatelessWidget {
  final DateTime date;
  final String mealTitle;
  final String description;
  final int participants;
  final String imageUrl;

  const DonationCardOfPrevious({
    super.key,
    required this.date,
    required this.mealTitle,
    required this.description,
    required this.participants,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetailScreen(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            mealTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontFamily: 'DIN',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.user,
                                  size: 14, color: AppColors.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '$participants',
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        String costText = 'تحميل التكلفة...';
        if (state is ExpenseLoaded) {
          final dateString = date.toIso8601String().split('T')[0];
          final totalExpenses = state.expenses
              .where((expense) => expense.date == dateString)
              .fold(0.0, (sum, expense) => sum + expense.amount);
          final costPerMeal =
              participants > 0 ? totalExpenses / participants : 0.0;
          costText = costPerMeal == 0.0
              ? 'لم تحدد التكلفة'
              : '${costPerMeal.toStringAsFixed(2)} ج.م / فرد';
        }

        return Row(
          children: [
            Icon(Iconsax.money_send, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              costText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'التفاصيل',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'DIN',
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Iconsax.arrow_right_1,
                size: 16, color: AppColors.primaryColor),
          ],
        );
      },
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Hero(
          tag: imageUrl,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: const Color(0xFFF1F5F9),
              child: const Icon(Iconsax.image, size: 40, color: Colors.grey),
            ),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        // Date Pill
        Positioned(
          bottom: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.calendar_1,
                    size: 14, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMMM yyyy', 'ar').format(date),
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DIN',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToDetailScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsOfPreviousDay(
          date: date,
          mealTitle: mealTitle,
          description: description,
          participants: participants,
          imageUrl: imageUrl,
        ),
      ),
    );
  }
}
