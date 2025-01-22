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

class ReportsScreen extends StatefulWidget {
  final ExpenseService _expenseService = ExpenseService();

  ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  bool _isAscending =
      true; // State to toggle between ascending and descending order

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget._expenseService.loadExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final groupedExpenses =
            widget._expenseService.getGroupedExpensesByDate();

        // Sort the expenses based on date
        final sortedGroupedExpenses = Map.fromEntries(
          groupedExpenses.entries.toList()
            ..sort((a, b) => _isAscending
                ? DateTime.parse(a.key).compareTo(DateTime.parse(b.key))
                : DateTime.parse(b.key).compareTo(DateTime.parse(a.key))),
        );

        if (sortedGroupedExpenses.isEmpty) {
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
          appBar: AppBar(
            title: const Text('التقارير اليومية'),
            actions: [
              IconButton(
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () {
                  setState(() {
                    _isAscending = !_isAscending; // Toggle sort order
                  });
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              itemCount: sortedGroupedExpenses.length,
              itemBuilder: (context, index) {
                final date = sortedGroupedExpenses.keys.elementAt(index);
                final dailyExpenses = sortedGroupedExpenses[date]!;

                // Calculate total amount for the date
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
                        Row(
                          children: [
                            Text(
                              '${dailyExpenses.length} مصروفات',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                      ],
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
