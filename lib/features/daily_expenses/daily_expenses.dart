import 'package:flutter/material.dart';

class DailyExpensesScreen extends StatefulWidget {
  const DailyExpensesScreen({super.key});

  @override
  DailyExpensesScreenState createState() => DailyExpensesScreenState();
}

class DailyExpensesScreenState extends State<DailyExpensesScreen> {
  List<Map<String, dynamic>> expenses = [
    {'date': '2025-01-01', 'amount': 100, 'description': 'Food Supplies'},
    {'date': '2025-01-02', 'amount': 50, 'description': 'Transportation'},
  ];

  void addExpense(String date, double amount, String description) {
    setState(() {
      expenses
          .add({'date': date, 'amount': amount, 'description': description});
    });
  }

  void updateExpense(
      int index, String date, double amount, String description) {
    setState(() {
      expenses[index] = {
        'date': date,
        'amount': amount,
        'description': description
      };
    });
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
  }

  void generateReport() {
    // Add logic to create and share PDF report
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            title: Text('${expense['description']} - \$${expense['amount']}'),
            subtitle: Text('Date: ${expense['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    // Edit expense logic
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteExpense(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
