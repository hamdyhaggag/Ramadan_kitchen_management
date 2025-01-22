import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/cache/prefs.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  // Category Data
  final Map<String, List<String>> categories = {
    'قسم البقالة': ['رز أو مكرونة', 'زيت أو سمن', 'شعرية', 'سكر', 'ملح'],
    'قسم الخضروات': [
      'بسلة',
      'طماطم',
      'بطاطس',
      'جزر',
      'بصل',
      'ثوم',
      'خضرة سلطة'
    ],
    'قسم الفواكه': ['تمر', 'برتقال', 'موز'],
    'قسم اللحوم': [
      'الأسماك (بلطي، بوري، ماكاريل)',
      'الفراخ (بالعدد)',
      'اللحم',
      'الكبدة'
    ],
    'قسم المواد الإضافية': ['بهارات', 'طرشي', 'طحينة'],
    'قسم الأدوات والمستلزمات': ['فويل', 'فوم', 'أكياس'],
    'قسم الوقود والطاقة': ['غاز'],
  };

  List<Product> products = [];
  double totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _addProduct(String productName) {
    showDialog(
      context: context,
      builder: (context) {
        return AddProductDialog(
          productName: productName,
          onProductAdded: (quantity, unitPrice, unitType) {
            setState(() {
              products.add(Product(
                name: productName,
                quantity: quantity,
                unitPrice: unitPrice,
                unitType: unitType,
              ));
              _calculateTotalCost();
            });
          },
        );
      },
    );
  }

  void _calculateTotalCost() {
    totalCost = products.fold(0.0, (sum, product) => sum + product.partialCost);
    setState(() {});
  }

  void _resetFields() {
    setState(() {
      products.clear();
      totalCost = 0.0;
    });
    Prefs.removeData(key: 'productList');
    Prefs.removeData(key: 'totalCost');
  }

  void _saveData() {
    final productList = products.map((product) => product.toJson()).toList();
    Prefs.setString('productList', jsonEncode(productList));
    Prefs.setString('totalCost', totalCost.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ البيانات بنجاح!')),
    );
  }

  void _loadData() {
    final productListString = Prefs.getString('productList') ?? '';
    final totalCostString = Prefs.getString('totalCost') ?? '0.0';

    if (productListString.isNotEmpty) {
      final List<dynamic> cachedList = jsonDecode(productListString);
      products = cachedList.map((data) => Product.fromJson(data)).toList();
    }
    totalCost = double.tryParse(totalCostString) ?? 0.0;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Categories Section
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories.keys.elementAt(index);
                return CategorySection(
                  categoryName: category,
                  products: categories[category]!,
                  onAddProduct: _addProduct,
                );
              },
            ),
          ),
          const Divider(),
          // Receipt Section
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'الإيصال',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              '${product.quantity} ${product.unitType} × ${product.unitPrice.toStringAsFixed(2)} جنيه'),
                          trailing: Text(
                            '${product.partialCost.toStringAsFixed(2)} جنيه',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التكلفة الإجمالية:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '${totalCost.toStringAsFixed(2)} جنيه',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                    'حساب التكلفة', Colors.green, _calculateTotalCost),
                _buildActionButton('مسح الكميات', Colors.red, _resetFields),
                _buildActionButton('حفظ', Colors.blue, _saveData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildActionButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}

class CategorySection extends StatelessWidget {
  final String categoryName;
  final List<String> products;
  final Function(String) onAddProduct;

  const CategorySection({
    super.key,
    required this.categoryName,
    required this.products,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        categoryName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      children: products.map((productName) {
        return ListTile(
          title: Text(productName),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onAddProduct(productName),
          ),
        );
      }).toList(),
    );
  }
}

class Product {
  final String name;
  final int quantity;
  final double unitPrice;
  final String unitType;

  Product({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.unitType,
  });

  double get partialCost => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unitType': unitType,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
      unitType: json['unitType'],
    );
  }
}

class AddProductDialog extends StatefulWidget {
  final String productName;
  final Function(int, double, String) onProductAdded;

  const AddProductDialog({
    super.key,
    required this.productName,
    required this.onProductAdded,
  });

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedUnitType = 'كيلو جرام';

  final List<String> unitTypes = ['كيلو جرام', 'لتر', 'قطعة'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة ${widget.productName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'سعر الوحدة'),
            ),
            DropdownButtonFormField(
              value: selectedUnitType,
              items: unitTypes
                  .map((unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedUnitType = value as String;
                });
              },
              decoration: const InputDecoration(labelText: 'نوع الوحدة'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final quantity = int.tryParse(quantityController.text) ?? 0;
            final unitPrice = double.tryParse(priceController.text) ?? 0.0;
            widget.onProductAdded(quantity, unitPrice, selectedUnitType);
            Navigator.of(context).pop();
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
