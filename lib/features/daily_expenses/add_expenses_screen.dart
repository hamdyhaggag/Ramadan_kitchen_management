import 'package:flutter/material.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  AddExpenseScreenState createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  String _selectedCategory = 'قسم البقالة';
  String? _selectedProduct;
  String _selectedUnitType = 'كيلوجرام';
  String _selectedPaymentStatus = 'لم يتم الدفع';
  DateTime _selectedDate = DateTime.now();

  final Map<String, List<String>> _categoryProducts = {
    'قسم البقالة': ['رز', 'مكرونة', 'شعرية', 'زيت', 'سمن', 'سكر', 'ملح'],
    'قسم الخضروات': [
      'بسلة',
      'طماطم',
      'بطاطس',
      'جزر',
      'بصل',
      'ثوم',
      'خضرة سلطة'
    ],
    'قسم الفواكه': ['برتقال', 'موز', 'تمر'],
    'قسم الأسماك': ['بلطي', 'بوري', 'ماكاريل'],
    'قسم اللحوم': ['الفراخ', 'اللحم', 'الكبدة'],
    'قسم المواد الإضافية': ['بهارات', 'طرشي', 'طحينة'],
    'قسم الأدوات والمستلزمات': ['فويل', 'فوم', 'أكياس'],
    'قسم الوقود ': ['غاز'],
  };

  void _saveExpense() {
    final quantityText = _quantityController.text.trim();
    final unitPriceText = _unitPriceController.text.trim();
    final quantity = double.tryParse(quantityText);
    final unitPrice = double.tryParse(unitPriceText);

    if (quantity == null || unitPrice == null || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال جميع التفاصيل بشكل صحيح')),
      );
      return;
    }

    Navigator.pop(context, {
      'date': _selectedDate.toString().split(' ')[0],
      'amount': quantity * unitPrice,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitType': _selectedUnitType,
      'category': _selectedCategory,
      'product': _selectedProduct,
      'paid': _selectedPaymentStatus == 'تم الدفع',
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
          lastDate: DateTime(2101),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _selectedCategory,
      onChanged: (String? newValue) => setState(() {
        _selectedCategory = newValue!;
        _selectedProduct = null;
      }),
      items: _categoryProducts.keys.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      elevation: 3,
      isExpanded: true,
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButton<String>(
      value: _selectedProduct,
      hint: const Text('اختر المنتج'),
      onChanged: (String? newValue) =>
          setState(() => _selectedProduct = newValue),
      items: _categoryProducts[_selectedCategory]!.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      elevation: 3,
      isExpanded: true,
    );
  }

  Widget _buildUnitTypeDropdown() {
    return DropdownButton<String>(
      value: _selectedUnitType,
      onChanged: (String? newValue) =>
          setState(() => _selectedUnitType = newValue!),
      items: ['كيلوجرام', 'لتر', 'قطعة'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      elevation: 3,
      isExpanded: true,
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('الكمية'),
      cursorColor: AppColors.primaryColor,
    );
  }

  Widget _buildUnitPriceField() {
    return TextField(
      controller: _unitPriceController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration('سعر الوحدة'),
      cursorColor: AppColors.primaryColor,
    );
  }

  Widget _buildPaymentStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentStatus,
      decoration: _inputDecoration('حالة الدفع'),
      items: ['تم الدفع', 'لم يتم الدفع'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() => _selectedPaymentStatus = newValue!);
      },
      isExpanded: true,
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveExpense,
      child: GeneralButton(
        text: 'حفظ المصروف',
        backgroundColor: AppColors.primaryColor,
        textColor: AppColors.whiteColor,
      ),
    );
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
