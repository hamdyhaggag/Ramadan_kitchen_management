import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  AddExpenseScreenState createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'قسم البقالة';
  String? _selectedProduct;
  String _selectedUnitType = 'كيلوجرام';
  String _selectedPaymentStatus = 'تم الدفع';

  final Map<String, List<String>> _categoryProducts = {
    'قسم البقالة': [
      'رز',
      'مكرونة',
      'شعرية',
      'زيت',
      'سمن',
      'سكر',
      'ملح',
      'صلصة',
      'خل'
    ],
    'قسم الخضروات': [
      'بسلة',
      'طماطم',
      'بطاطس',
      'جزر',
      'بصل',
      'كوسة',
      'لوبيا',
      'فاصولياء',
      'ثوم',
      'خضرة سلطة'
    ],
    'قسم الفواكه': ['برتقال', 'موز', 'تمر'],
    'قسم الأسماك': ['بلطي', 'بوري', 'ماكاريل'],
    'قسم اللحوم': ['الفراخ', 'اللحم', 'الكبدة'],
    'قسم المواد الإضافية': ['بهارات', 'طرشي', 'طحينة'],
    'قسم الأدوات والمستلزمات': ['فويل', 'فوم', 'أكياس'],
    'قسم الوقود ': ['غاز'],
    'قسم التجهيزات ': ['تكلفة التجهيز'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مصروف')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatePicker(),
                _buildCategoryDropdown(),
                const SizedBox(height: 10),
                _buildProductDropdown(),
                const SizedBox(height: 10),
                _buildUnitTypeDropdown(),
                const SizedBox(height: 10),
                _buildQuantityField(),
                const SizedBox(height: 10),
                _buildUnitPriceField(),
                const SizedBox(height: 15),
                _buildPaymentStatusDropdown(),
                const SizedBox(height: 20),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('التاريخ'),
      subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _inputDecoration('القسم'),
      items: _categoryProducts.keys.map((String value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() {
        _selectedCategory = value!;
        _selectedProduct = null;
      }),
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedProduct,
      decoration: _inputDecoration('المادة'),
      items: _categoryProducts[_selectedCategory]!.map((String value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedProduct = value),
      validator: (value) => value == null ? 'الرجاء اختيار المادة' : null,
    );
  }

  Widget _buildUnitTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnitType,
      decoration: _inputDecoration('الوحدة'),
      items: ['كيلوجرام', 'لتر', 'قطعة', 'فرد'].map((String value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedUnitType = value!),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('الكمية'),
      cursorColor: AppColors.primaryColor,
      validator: (value) => _validateNumber(value, 'الكمية'),
    );
  }

  Widget _buildUnitPriceField() {
    return TextFormField(
      controller: _unitPriceController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('سعر الوحدة'),
      cursorColor: AppColors.primaryColor,
      validator: (value) => _validateNumber(value, 'السعر'),
    );
  }

  Widget _buildPaymentStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentStatus,
      decoration: _inputDecoration('حالة الدفع'),
      items: ['تم الدفع', 'لم يتم الدفع'].map((String value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPaymentStatus = value!),
    );
  }

  Widget _buildSaveButton() {
    return GeneralButton(
      text: 'حفظ المصروف',
      backgroundColor: AppColors.primaryColor,
      textColor: AppColors.whiteColor,
      onPressed: _submitForm,
    );
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    if (double.tryParse(value) == null) {
      return 'قيمة غير صالحة';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final expense = Expense(
        id: '',
        date: _selectedDate.toIso8601String().split('T')[0],
        amount: double.parse(_quantityController.text) *
            double.parse(_unitPriceController.text),
        description: _selectedProduct!,
        paid: _selectedPaymentStatus == 'تم الدفع',
        category: _selectedCategory,
        product: _selectedProduct!,
        quantity: double.parse(_quantityController.text),
        unitPrice: double.parse(_unitPriceController.text),
        unitType: _selectedUnitType,
      );

      context.read<ExpenseCubit>().addExpense(expense);
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(color: AppColors.blackColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.greyColor, width: 2.0),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 1.0),
      ),
    );
  }
}
