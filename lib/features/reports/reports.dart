import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/services/expense_service.dart';

String formatDateString(String dateString) {
  try {
    final parsedDate = DateTime.parse(dateString);
    return DateFormat('EEEE, MMM d, yyyy', 'ar').format(parsedDate);
  } catch (e) {
    return 'تاريخ غير صالح';
  }
}

String formatTimeString(String timeString) {
  try {
    if (timeString.isEmpty) return 'وقت غير صالح';

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
    return 'وقت غير صالح';
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
          return const Center(child: CircularProgressIndicator());
        }

        final groupedExpenses = _expenseService.getGroupedExpensesByDate();

        if (groupedExpenses.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد مصروفات مسجلة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: groupedExpenses.length,
              itemBuilder: (context, index) {
                final date = groupedExpenses.keys.elementAt(index);
                final dailyExpenses = groupedExpenses[date]!;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      formatDateString(date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    subtitle: Text(
                      '${dailyExpenses.length} مصروفات',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    children: dailyExpenses.map((expense) {
                      return ListTile(
                        title: Text(
                          expense['description'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'المبلغ: ${expense['amount']} ج.م',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[50],
                          child: Icon(
                            Icons.attach_money,
                            color: Colors.teal[400],
                          ),
                        ),
                        trailing: Text(
                          formatTimeString(expense['time'] ?? ''),
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      );
                    }).toList(),
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
