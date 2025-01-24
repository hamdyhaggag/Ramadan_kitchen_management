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
  String _selectedCategory = 'قسم البقالة';
  String? _selectedProduct;
  String _selectedUnitType = 'كيلوجرام';
  DateTime _selectedDate = DateTime.now();

  final Map<String, List<String>> _categoryProducts = {
    'قسم البقالة': [
      'رز  ',
      'مكرونة  ',
      'شعرية',
      'زيت  ',
      'سمن  ',
      'سكر',
      'ملح',
    ],
    'قسم الخضروات': [
      'بسلة',
      'طماطم',
      'بطاطس',
      'جزر',
      'بصل',
      'ثوم',
      'خضرة سلطة',
    ],
    'قسم الفواكه': [
      'برتقال',
      'موز',
      'تمر',
    ],
    'قسم الأسماك': [
      'بلطي',
      'بوري',
      'ماكاريل',
    ],
    'قسم اللحوم': [
      'الفراخ ',
      'اللحم',
      'الكبدة',
    ],
    'قسم المواد الإضافية': [
      'بهارات',
      'طرشي',
      'طحينة',
    ],
    'قسم الأدوات والمستلزمات': [
      'فويل',
      'فوم',
      'أكياس',
    ],
    'قسم الوقود ': [
      'غاز',
    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    _selectedProduct = null;
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
              if (_categoryProducts[_selectedCategory] != null)
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
              TextField(
                cursorColor: AppColors.primaryColor,
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: AppColors.primaryColor,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                cursorColor: AppColors.primaryColor,
                controller: _unitPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر الوحدة',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: AppColors.primaryColor,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
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
