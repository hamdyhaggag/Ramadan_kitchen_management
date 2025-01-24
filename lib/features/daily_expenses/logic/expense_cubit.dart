import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_state.dart';
import '../model/expense_model.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final FirebaseFirestore _firestore;
  final CollectionReference _expensesCollection;
  List<Expense> _localCache = [];

  ExpenseCubit()
      : _firestore = FirebaseFirestore.instance,
        _expensesCollection = FirebaseFirestore.instance.collection('expenses'),
        super(ExpenseInitial()) {
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _expensesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _localCache =
          snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      emit(ExpenseLoaded(List.from(_localCache)));
    }, onError: (error) {
      emit(_localCache.isEmpty
          ? ExpenseError('Failed to load expenses: $error')
          : ExpenseLoaded(List.from(_localCache)));
    });
  }

  Future<void> addExpense(Expense expense) async {
    String tempId = '';
    try {
      tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempExpense = expense.copyWith(id: tempId);

      _localCache = [tempExpense, ..._localCache];
      emit(ExpenseLoaded(List.from(_localCache)));

      final docRef = await _expensesCollection.add(tempExpense.toFirestore());
      final newExpense = tempExpense.copyWith(id: docRef.id);
      _localCache =
          _localCache.map((e) => e.id == tempId ? newExpense : e).toList();
      emit(ExpenseLoaded(List.from(_localCache)));
    } catch (e) {
      _localCache.removeWhere((e) => e.id == tempId);
      emit(ExpenseLoaded(List.from(_localCache)));
      emit(ExpenseError('Failed to add expense: ${e.toString()}'));
    }
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    final index = _localCache.indexWhere((e) => e.id == updatedExpense.id);
    if (index == -1) return;

    final previousExpense = _localCache[index];
    _localCache[index] = updatedExpense;
    emit(ExpenseLoaded(List.from(_localCache)));

    try {
      await _expensesCollection
          .doc(updatedExpense.id)
          .update(updatedExpense.toFirestore());
    } catch (e) {
      _localCache[index] = previousExpense;
      emit(ExpenseLoaded(List.from(_localCache)));
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final index = _localCache.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final deletedExpense = _localCache.removeAt(index);
    emit(ExpenseLoaded(List.from(_localCache)));

    try {
      await _expensesCollection.doc(expenseId).delete();
    } catch (e) {
      _localCache.insert(index, deletedExpense);
      emit(ExpenseLoaded(List.from(_localCache)));
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }

  Future<void> togglePaymentStatus(String expenseId, bool newStatus) async {
    final index = _localCache.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final updatedExpense = _localCache[index].copyWith(paid: newStatus);
    _localCache[index] = updatedExpense;
    emit(ExpenseLoaded(List.from(_localCache)));

    try {
      await _expensesCollection.doc(expenseId).update(
          {'paid': newStatus, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      _localCache[index] = _localCache[index].copyWith(paid: !newStatus);
      emit(ExpenseLoaded(List.from(_localCache)));
      emit(ExpenseError('Payment status update failed: ${e.toString()}'));
    }
  }

  Future<void> loadExpenses() async {
    try {
      emit(ExpenseLoading());
      final snapshot = await _expensesCollection
          .orderBy('timestamp', descending: true)
          .get();
      _localCache =
          snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
      emit(ExpenseLoaded(List.from(_localCache)));
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
    }
  }

  List<Expense> getExpensesByDate(DateTime date) {
    final dateString = date.toIso8601String().split('T')[0];
    return _localCache.where((e) => e.date == dateString).toList();
  }

  List<Expense> getUnpaidExpenses() {
    return _localCache.where((e) => !e.paid).toList();
  }
}
