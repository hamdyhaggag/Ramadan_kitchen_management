import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  AddExpenseScreenState createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  String _selectedCategory = 'خضروات';
  String? _selectedProduct;
  String _selectedUnitType = 'كيلوجرام'; // Default value
  DateTime _selectedDate = DateTime.now();

  final Map<String, List<String>> _categoryProducts = {
    'خضروات': ['طماطم', 'خيار', 'بطاطس'],
    'فاكهة': ['تفاح', 'برتقال', 'موز'],
    'غاز': ['أسطوانة صغيرة', 'أسطوانة كبيرة'],
    'أسماك': ['بلطي', 'بوري', 'ماكريل'],
    'فراخ': ['دجاجة كاملة', 'صدور', 'أجنحة'],
  };

  void _saveExpense() {
    final quantityText = _quantityController.text.trim();
    final unitPriceText = _unitPriceController.text.trim();
    final quantity = double.tryParse(quantityText);
    final unitPrice = double.tryParse(unitPriceText);

    if (quantity == null ||
        unitPrice == null ||
        _selectedProduct == null ||
        _selectedProduct!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال جميع التفاصيل بشكل صحيح')),
      );
      return;
    }

    final totalAmount = quantity * unitPrice;

    Navigator.pop(context, {
      'date': _selectedDate.toString().split(' ')[0],
      'amount': totalAmount,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitType': _selectedUnitType,
      'category': _selectedCategory,
      'product': _selectedProduct,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مصروف')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _unitPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر الوحدة'),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedUnitType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUnitType = newValue!;
                  });
                },
                items: ['كيلوجرام', 'لتر', 'قطعة']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                elevation: 3,
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    _selectedProduct =
                        null; // Reset product when category changes
                  });
                },
                items: _categoryProducts.keys
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                elevation: 3,
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              if (_categoryProducts[_selectedCategory] != null)
                DropdownButton<String>(
                  value: _selectedProduct,
                  hint: const Text('اختر المنتج'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProduct = newValue!;
                    });
                  },
                  items: _categoryProducts[_selectedCategory]!
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  elevation: 3,
                  isExpanded: true,
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
      ),
    );
  }
}
