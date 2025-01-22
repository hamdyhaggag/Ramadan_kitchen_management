import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/cache/prefs.dart';

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

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();
  factory ExpenseService() => _instance;
  ExpenseService._internal();

  List<Map<String, dynamic>> expenses = [];

  Future<void> loadExpenses() async {
    final jsonString = Prefs.getString('expenses');
    if (jsonString.isNotEmpty) {
      expenses = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
    }
  }

  Future<void> saveExpenses() async {
    final jsonString = jsonEncode(expenses);
    await Prefs.setString('expenses', jsonString);
  }

  void addExpense(Map<String, dynamic> expense) {
    expenses.add(expense);
    saveExpenses();
  }

  Map<String, List<Map<String, dynamic>>> getGroupedExpensesByDate() {
    final Map<String, List<Map<String, dynamic>>> groupedExpenses = {};

    for (var expense in expenses) {
      final date = expense['date'];

      if (date != null) {
        if (!groupedExpenses.containsKey(date)) {
          groupedExpenses[date] = [];
        }
        groupedExpenses[date]!.add(expense);
      }
    }

    var sortedKeys = groupedExpenses.keys.toList()
      ..sort((a, b) =>
          DateTime.parse(b).compareTo(DateTime.parse(a))); // Sort descending
    return {for (var key in sortedKeys) key: groupedExpenses[key]!};
  }
}
