import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String date;
  final double amount;
  final String description;
  final bool paid;
  final String category;
  final String product;
  final double quantity;
  final double unitPrice;
  final String unitType;

  Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.paid,
    required this.category,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.unitType,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      date: data['date'],
      amount: data['amount'].toDouble(),
      description: data['description'],
      paid: data['paid'],
      category: data['category'],
      product: data['product'],
      quantity: data['quantity'].toDouble(),
      unitPrice: data['unitPrice'].toDouble(),
      unitType: data['unitType'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'amount': amount,
      'description': description,
      'paid': paid,
      'category': category,
      'product': product,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitType': unitType,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  Expense copyWith({
    String? id,
    String? date,
    double? amount,
    String? description,
    bool? paid,
    String? category,
    String? product,
    double? quantity,
    double? unitPrice,
    String? unitType,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paid: paid ?? this.paid,
      category: category ?? this.category,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitType: unitType ?? this.unitType,
    );
  }
}
