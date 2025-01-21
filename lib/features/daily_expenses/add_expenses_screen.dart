import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  AddExpenseScreenState createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'خضروات';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['فاكهة', 'غاز', 'أسماك', 'فراخ', 'خضروات'];

  void _saveExpense() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال قيمة صحيحة')),
      );
      return;
    }

    Navigator.pop(context, {
      'date': _selectedDate.toString().split(' ')[0],
      'amount': amount,
      'description': _selectedCategory,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مصروف')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              elevation: 3,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('التاريخ'),
              subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _saveExpense,
              child: GeneralButton(
                  text: 'حفظ المصروف',
                  backgroundColor: AppColors.primaryColor,
                  textColor: AppColors.whiteColor),
            ),
          ],
        ),
      ),
    );
  }
}
