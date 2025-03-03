import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../daily_expenses/logic/expense_cubit.dart';
import '../../../daily_expenses/logic/expense_state.dart';

class DetailsOfPreviousDay extends StatelessWidget {
  final DateTime date;
  final String mealTitle;
  final String description;
  final int participants;
  final String imageUrl;

  const DetailsOfPreviousDay({
    required this.date,
    required this.mealTitle,
    required this.description,
    required this.participants,
    required this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: imageUrl,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(color: Colors.grey[300]),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image,
                                size: 40, color: Colors.grey[700]),
                            const SizedBox(height: 8),
                            Text(
                              "Loading...",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 280,
                    color: Colors.grey[200],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.error, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text("لا يوجد اتصال بالانترنت"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const Divider(height: 40),
                  _buildDetailSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDateChip(),
            const SizedBox(width: 12),
            _buildParticipantsChip(),
          ],
        ),
        const SizedBox(height: 12),
        _buildCostPerMealChip(),
      ],
    );
  }

  Widget _buildDateChip() {
    return Expanded(
      child: _buildMetaChip(
        icon: Icons.calendar_month,
        label: DateFormat('EEE, d MMM , y').format(date),
      ),
    );
  }

  Widget _buildParticipantsChip() {
    return Expanded(
      child: _buildMetaChip(
        icon: Icons.people_alt_outlined,
        label: '$participants فرد تم إفطارهم',
      ),
    );
  }

  Widget _buildCostPerMealChip() {
    return BlocBuilder<ExpenseCubit, ExpenseState>(
      builder: (context, state) {
        if (state is ExpenseLoaded) {
          final totalExpenses = _calculateDailyExpenses(state);
          final costPerMeal =
              participants > 0 ? totalExpenses / participants : 0.0;
          return _buildMetaChip(
            icon: Icons.attach_money,
            label: '${costPerMeal.toStringAsFixed(2)} ج.م/وجبة',
          );
        }
        return _buildMetaChip(
          icon: Icons.attach_money,
          label: '0.00 ج.م/وجبة',
        );
      },
    );
  }

  double _calculateDailyExpenses(ExpenseLoaded state) {
    final dateString = date.toIso8601String().split('T')[0]; // Use UTC date
    return state.expenses
        .where((expense) => expense.date == dateString)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الوجبة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description.isNotEmpty ? description : 'لا يوجد وصف متوفر',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
