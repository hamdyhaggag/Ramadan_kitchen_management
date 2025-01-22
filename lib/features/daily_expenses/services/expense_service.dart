import 'dart:convert';

import '../../../core/cache/prefs.dart';

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
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    return {for (var key in sortedKeys) key: groupedExpenses[key]!};
  }
}
