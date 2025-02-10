import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';
import '../../core/services/service_locator.dart';
import 'add_expenses_screen.dart';
import 'logic/expense_state.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';

class DailyExpensesScreen extends StatefulWidget {
  const DailyExpensesScreen({super.key});

  @override
  State<DailyExpensesScreen> createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  DateTime? selectedDate;
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    final authRepo = getIt<AuthRepo>();
    isAdmin = authRepo.currentUser?.role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(
                child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ));
          }
          if (state is ExpenseError) return Center(child: Text(state.message));
          if (state is ExpenseLoaded) return _buildContent(state.expenses);
          return const Center(child: Text('لا توجد مصروفات'));
        },
      ),
    );
  }

  Widget _buildContent(List<Expense> expenses) {
    List<Expense> filteredExpenses = _getFilteredExpenses(expenses);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 20),
            _buildPieChart(filteredExpenses),
            const SizedBox(height: 20),
            _buildExpenseList(filteredExpenses),
            const SizedBox(height: 20),
            if (isAdmin) _buildAddButton(context),
            const SizedBox(height: 20),
            if (!isAdmin) _buildPermissionBanner(),
          ],
        ),
      ),
    );
  }

  List<Expense> _getFilteredExpenses(List<Expense> expenses) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final filterDate = selectedDate?.toIso8601String().split('T')[0] ?? today;
    return expenses.where((e) => e.date == filterDate).toList();
  }

  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline,
              color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text('التعديلات متاحة فقط للمشرفين',
              style: TextStyle(color: AppColors.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          selectedDate != null
              ? 'المصاريف بتاريخ: ${selectedDate!.toLocal().toString().split(' ')[0]}'
              : 'مصاريف اليوم',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          icon: Icon(Icons.calendar_today, color: isAdmin ? null : Colors.grey),
          onPressed: isAdmin ? _pickDate : null,
        ),
      ],
    );
  }

  Widget _buildPieChart(List<Expense> filteredExpenses) {
    final totalAmount = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final categoryAmounts = _getCategoryAmounts(filteredExpenses);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: PieChart(
            PieChartData(
              sections: categoryAmounts.entries
                  .map((entry) => PieChartSectionData(
                        value: entry.value,
                        title:
                            '${entry.key}\n${entry.value.toStringAsFixed(0)}',
                        color: AppColors.customColors[
                            categoryAmounts.keys.toList().indexOf(entry.key) %
                                AppColors.customColors.length],
                        radius: 100,
                        titleStyle: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ))
                  .toList(),
              centerSpaceRadius: 60,
              sectionsSpace: 4,
            ),
          ),
        ),
        Positioned(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الإجمالي',
                  style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold)),
              Text(totalAmount.toStringAsFixed(0),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, double> _getCategoryAmounts(List<Expense> filteredExpenses) {
    Map<String, double> amounts = {};
    for (var expense in filteredExpenses) {
      amounts.update(expense.category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    return amounts;
  }

  Widget _buildExpenseList(List<Expense> filteredExpenses) {
    if (filteredExpenses.isEmpty) {
      return SizedBox(
        height: 20,
        child: const Center(
            child: Text('لا توجد مصروفات لهذا اليوم',
                style: TextStyle(fontSize: 16))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredExpenses.length,
      itemBuilder: (context, index) =>
          _buildExpenseItem(filteredExpenses[index]),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    if (isAdmin) {
      return Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          color: Colors.red,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) => _confirmDelete(expense),
        onDismissed: (direction) => _deleteExpense(expense),
        child: _buildExpenseListTile(expense),
      );
    } else {
      return _buildExpenseListTile(expense);
    }
  }

  Widget _buildExpenseListTile(Expense expense) {
    return ListTile(
      title: Text(expense.product),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الكمية: ${expense.quantity} ${expense.unitType}'),
          Text('السعر: ${expense.unitPrice.toStringAsFixed(2)} ج.م/وحدة'),
          _buildPaymentStatus(expense),
          const SizedBox(height: 8),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${expense.amount.toStringAsFixed(2)} ',
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(expense.category,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus(Expense expense) {
    final bool canEdit = isAdmin;
    final Color iconColor =
        canEdit ? (expense.paid ? Colors.green : Colors.red) : Colors.grey;

    return GestureDetector(
      onTap: canEdit
          ? () => context
              .read<ExpenseCubit>()
              .togglePaymentStatus(expense.id, !expense.paid)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('فقط المشرفون يمكنهم تعديل حالة الدفع'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
      child: Row(
        children: [
          Icon(
            expense.paid ? Icons.check_circle : Icons.cancel,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            expense.paid ? 'تم الدفع' : 'لم يتم الدفع',
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GeneralButton(
      text: 'إضافة مصروف جديد',
      backgroundColor: AppColors.primaryColor,
      textColor: AppColors.whiteColor,
      onPressed: () => _navigateToAddExpense(context),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Future<bool?> _confirmDelete(Expense expense) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.blackColor))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _deleteExpense(Expense expense) {
    context.read<ExpenseCubit>().deleteExpense(expense.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف مصروف ${expense.product}'),
        action: SnackBarAction(
            label: 'تراجع',
            onPressed: () => context.read<ExpenseCubit>().addExpense(expense)),
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
  }
}
