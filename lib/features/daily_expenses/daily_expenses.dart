import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';

import '../../core/cache/prefs.dart';
import 'add_expenses_Screen.dart';

class DailyExpensesScreen extends StatefulWidget {
  const DailyExpensesScreen({super.key});

  @override
  DailyExpensesScreenState createState() => DailyExpensesScreenState();
}

class DailyExpensesScreenState extends State<DailyExpensesScreen> {
  List<Map<String, dynamic>> expenses = [];
  DateTime? selectedDate;

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

  List<Map<String, dynamic>> get filteredExpenses {
    if (selectedDate == null) return expenses;
    return expenses
        .where((expense) =>
            expense['date'] == selectedDate!.toIso8601String().split('T')[0])
        .toList();
  }

  void addExpense(String date, double amount, String description) {
    setState(() {
      expenses
          .add({'date': date, 'amount': amount, 'description': description});
    });
    saveExpenses();
  }

  void navigateToAddExpenseScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
    if (result != null) {
      setState(() {
        expenses.add({
          'date': result['date'],
          'amount': result['amount'],
          'description': result['product'],
        });
      });
      saveExpenses();
    }
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Widget _buildPieChart() {
    final categoryData = categoryExpenses;
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: categoryData.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value,
                  title: entry.key,
                  color: AppColors.customColors[
                      categoryData.keys.toList().indexOf(entry.key) %
                          AppColors.customColors.length],
                );
              }).toList(),
            ),
          ),
          Center(
            child: Text(
              'الإجمالي: ${totalExpenses.toStringAsFixed(0)} ',
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

  void _removeExpense(int index) {
    final removedExpense = expenses[index];

    setState(() {
      expenses.removeAt(index);
    });
    saveExpenses();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف المصروف: ${removedExpense['description']}'),
        action: SnackBarAction(
          disabledTextColor: AppColors.whiteColor,
          label: 'تراجع',
          onPressed: () {
            setState(() {
              expenses.insert(index, removedExpense);
            });
            saveExpenses();
          },
        ),
      ),
    );
  }

  Widget _buildExpenseList() {
    final displayExpenses = filteredExpenses;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayExpenses.length,
      itemBuilder: (context, index) {
        final expense = displayExpenses[index];
        return Dismissible(
          key: Key(expense['description'] + expense['date']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: const Text('هل أنت متأكد أنك تريد حذف هذا المصروف؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child:
                        const Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _removeExpense(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(50),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                expense['description'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('التاريخ: ${expense['date']}'),
              trailing: Text(
                '${expense['amount']} ج.م',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadExpenses();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المصروفات:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: pickDate,
                  ),
                ],
              ),
              if (selectedDate != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null;
                        });
                      },
                      child: const Text(
                        'إزالة الفلتر',
                        style: TextStyle(
                            color: AppColors.blackColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
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

  void saveExpenses() async {
    final jsonString = jsonEncode(expenses);
    await Prefs.setString('expenses', jsonString);
  }

  void loadExpenses() {
    final jsonString = Prefs.getString('expenses');
    if (jsonString.isNotEmpty) {
      setState(() {
        expenses = List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      });
    }
  }
}
