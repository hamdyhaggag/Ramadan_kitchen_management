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

      // Optimistic update
      _localCache = [tempExpense, ..._localCache];
      emit(ExpenseLoaded(List.from(_localCache)));

      // Firestore operation
      final docRef = await _expensesCollection.add(tempExpense.toFirestore());

      // Update with real ID
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
    int index = -1;
    try {
      index = _localCache.indexWhere((e) => e.id == updatedExpense.id);
      if (index != -1) {
        // Store previous state for rollback
        final previousExpense = _localCache[index];

        // Optimistic update
        _localCache[index] = updatedExpense;
        emit(ExpenseLoaded(List.from(_localCache)));

        // Firestore operation
        await _expensesCollection
            .doc(updatedExpense.id)
            .update(updatedExpense.toFirestore());
      }
    } catch (e) {
      if (index != -1) {
        // Rollback to previous state
        _localCache[index] = _localCache[index];
        emit(ExpenseLoaded(List.from(_localCache)));
      }
      emit(ExpenseError('Failed to update expense: ${e.toString()}'));
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    Expense? deletedExpense;
    int index = -1;
    try {
      index = _localCache.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        deletedExpense = _localCache[index];

        // Optimistic update
        _localCache.removeAt(index);
        emit(ExpenseLoaded(List.from(_localCache)));

        // Firestore operation
        await _expensesCollection.doc(expenseId).delete();
      }
    } catch (e) {
      if (deletedExpense != null && index != -1) {
        // Rollback deletion
        _localCache.insert(index, deletedExpense);
        _localCache.sort((a, b) => b.date.compareTo(a.date));
        emit(ExpenseLoaded(List.from(_localCache)));
      }
      emit(ExpenseError('Failed to delete expense: ${e.toString()}'));
    }
  }

  Future<void> togglePaymentStatus(String expenseId, bool newStatus) async {
    int index = -1;
    try {
      index = _localCache.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        final updatedExpense = _localCache[index].copyWith(paid: newStatus);
        _localCache[index] = updatedExpense;
        emit(ExpenseLoaded(List.from(_localCache)));

        await _expensesCollection.doc(expenseId).update(
            {'paid': newStatus, 'timestamp': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (index != -1) {
        _localCache[index] = _localCache[index].copyWith(paid: !newStatus);
        emit(ExpenseLoaded(List.from(_localCache)));
      }
      emit(ExpenseError('Payment status update failed: ${e.toString()}'));
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
