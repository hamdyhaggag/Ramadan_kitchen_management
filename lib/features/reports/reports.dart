import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/services/expense_service.dart';

import '../../core/utils/app_colors.dart';

String formatDateString(String dateString) {
  try {
    final parsedDate = DateTime.parse(dateString);
    return DateFormat('EEEE , d MMM yyyy', 'ar').format(parsedDate);
  } catch (e) {
    return 'تاريخ غير صالح';
  }
}

String formatTimeString(String timeString) {
  try {
    if (timeString.isEmpty) return '';

    final now = DateTime.now();
    final timeParts = timeString.split(':');

    if (timeParts.length == 2) {
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final parsedTime = DateTime(now.year, now.month, now.day, hours, minutes);
      return DateFormat('h:mm a', 'ar').format(parsedTime);
    }

    final parsedTime = DateTime.parse(timeString);
    return DateFormat('h:mm a', 'ar').format(parsedTime);
  } catch (e) {
    return '';
  }
}

class ReportsScreen extends StatelessWidget {
  final ExpenseService _expenseService = ExpenseService();

  ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _expenseService.loadExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final groupedExpenses = _expenseService.getGroupedExpensesByDate();

        if (groupedExpenses.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Text(
                'لا توجد مصروفات مسجلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              itemCount: groupedExpenses.length,
              itemBuilder: (context, index) {
                final date = groupedExpenses.keys.elementAt(index);
                final dailyExpenses = groupedExpenses[date]!;

                double totalAmount = 0.0;
                for (var expense in dailyExpenses) {
                  totalAmount += expense['amount'] ?? 0.0;
                }

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppColors.primaryColor.withAlpha(200),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatDateString(date),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blackColor,
                              ),
                            ),
                          ],
                        ),
                        // Add total amount to the right of the row
                        Text(
                          '${totalAmount.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${dailyExpenses.length} مصروفات',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatDateString(date),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...dailyExpenses.map((expense) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      expense['description'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'المبلغ: ${expense['amount']} ج.م',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          AppColors.primaryColor.withAlpha(200),
                                      child: Icon(
                                        Icons.attach_money,
                                        color: AppColors.whiteColor,
                                      ),
                                    ),
                                    trailing: Text(
                                      formatTimeString(expense['time'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
