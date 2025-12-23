import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_state.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';
import 'package:ramadan_kitchen_management/core/networking/firestore_constants.dart';
import '../model/expense_model.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final FirebaseFirestore _firestore;
  final SeasonService _seasonService = SeasonService();
  List<Expense> _localCache = [];
  StreamSubscription? _expenseSubscription;

  ExpenseCubit()
      : _firestore = FirebaseFirestore.instance,
        super(ExpenseInitial()) {
    _loadInitialData();
  }

  CollectionReference get _expensesCollection =>
      _seasonService.getCollection(FirestoreCollections.expenses);

  Future<void> _loadInitialData() async {
    await loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      emit(ExpenseLoading());

      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason == null) {
        _localCache = [];
        emit(const ExpenseLoaded([]));
        return;
      }

      // Cancel previous subscription if exists to avoid duplicates when reloading
      await _expenseSubscription?.cancel();

      Query query = _expensesCollection;

      // Only filter by season if we have an active season AND it's not migrated
      if (!activeSeason.isMigratedToV2) {
        query = query.where('seasonId', isEqualTo: activeSeason.id);
      }

      _expenseSubscription = query
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        _localCache =
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList();
        emit(ExpenseLoaded(List.from(_localCache)));
      }, onError: (error) {
        // Fallback for missing index or other errors
        print("Expense listener error: $error");
        emit(_localCache.isEmpty
            ? ExpenseError('Failed to load expenses: $error')
            : ExpenseLoaded(List.from(_localCache)));
      });
    } catch (e) {
      emit(ExpenseError('Failed to load expenses: ${e.toString()}'));
    }
  }

  Future<void> addExpense(Expense expense) async {
    String tempId = '';
    try {
      final activeSeason = await _seasonService.getActiveSeason();
      if (activeSeason == null) {
        emit(ExpenseError('لا يوجد موسم نشط لإضافة مصروف'));
        return;
      }

      tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      // Add seasonId to the expense model
      // Assuming Expense model has a seasonId field or a Map based model.
      // If Expense model doesn't have seasonId, we must pass it toFirestore/copyWith manually or update the model.
      // Let's assume we can add it to the map in toFirestore() or use a modified copyWith if supported.
      // Since I can't see Expense model fully, I will assume it handles extra fields or I send as Map.
      // Actually, safest is to send as Map to Firestore directly or update helper.

      // We'll trust the user to have updated the model or flexibility.
      // But wait, if Expense model is strict, this might fail on local copy.
      // Let's create a map for Firestore.

      final tempExpense = expense.copyWith(id: tempId);
      // We add it locally
      _localCache = [tempExpense, ..._localCache];
      emit(ExpenseLoaded(List.from(_localCache)));

      final data = tempExpense.toFirestore();
      data['seasonId'] = activeSeason.id; // Inject seasonId

      final docRef = await _expensesCollection.add(data);
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

  List<Expense> getExpensesByDate(DateTime date) {
    final dateString = date.toIso8601String().split('T')[0];
    return _localCache.where((e) => e.date == dateString).toList();
  }

  List<Expense> getUnpaidExpenses() {
    return _localCache.where((e) => !e.paid).toList();
  }

  @override
  Future<void> close() {
    _expenseSubscription?.cancel();
    return super.close();
  }
}
