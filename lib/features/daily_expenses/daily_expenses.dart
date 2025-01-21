import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';

import 'add_expenses_Screen.dart';

class DailyExpensesScreen extends StatefulWidget {
  const DailyExpensesScreen({super.key});

  @override
  DailyExpensesScreenState createState() => DailyExpensesScreenState();
}

class DailyExpensesScreenState extends State<DailyExpensesScreen> {
  List<Map<String, dynamic>> expenses = [
    {'date': '2025-01-01', 'amount': 150.0, 'description': 'غاز'},
    {'date': '2025-01-02', 'amount': 300.0, 'description': 'فاكهة'},
  ];

  double get totalExpenses {
    return expenses.fold(0, (sum, item) => sum + item['amount']);
  }

  Map<String, double> get categoryExpenses {
    Map<String, double> categories = {};
    for (var expense in expenses) {
      categories.update(
        expense['description'],
        (existingValue) => existingValue + expense['amount'],
        ifAbsent: () => expense['amount'],
      );
    }
    return categories;
  }

  // Function to add expense
  void addExpense(String date, double amount, String description) {
    setState(() {
      expenses
          .add({'date': date, 'amount': amount, 'description': description});
    });
  }

  void navigateToAddExpenseScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(),
      ),
    );
    if (result != null) {
      addExpense(result['date'], result['amount'], result['description']);
    }
  }

  Widget _buildPieChart() {
    final categoryData = categoryExpenses;
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: categoryData.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value,
                  title: entry.key,
                  color: Colors.primaries[
                      categoryData.keys.toList().indexOf(entry.key) %
                          Colors.primaries.length],
                );
              }).toList(),
            ),
          ),
          Center(
            child: Text(
              'الإجمالي: ${totalExpenses.toStringAsFixed(2)} ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Display list of expenses
  Widget _buildExpenseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              '${expense['description']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('التاريخ: ${expense['date']}'),
            trailing: Text(
              '${expense['amount']} ج.م',
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            onTap: () {
              // Handle tap if needed for editing
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإحصائيات:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _buildPieChart(),
              const SizedBox(height: 20),
              Text(
                'المصروفات:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _buildExpenseList(),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: navigateToAddExpenseScreen,
                child: GeneralButton(
                    text: 'إضافة مصروف جديد',
                    backgroundColor: AppColors.primaryColor,
                    textColor: AppColors.whiteColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
