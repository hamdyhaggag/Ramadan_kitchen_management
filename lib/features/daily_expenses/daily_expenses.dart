import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';
import 'add_expenses_screen.dart';
import 'logic/expense_state.dart';

class DailyExpensesScreen extends StatelessWidget {
  const DailyExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ExpenseCubit, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseError) return Center(child: Text(state.message));
          if (state is ExpenseLoaded) {
            return _ExpenseContent(expenses: state.expenses);
          }
          return const Center(child: Text('لا توجد مصروفات'));
        },
      ),
    );
  }
}

class _ExpenseContent extends StatefulWidget {
  final List<Expense> expenses;
  const _ExpenseContent({required this.expenses});

  @override
  State<_ExpenseContent> createState() => _ExpenseContentState();
}

class _ExpenseContentState extends State<_ExpenseContent> {
  DateTime? selectedDate;

  List<Expense> get filteredExpenses {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final filterDate = selectedDate?.toIso8601String().split('T')[0] ?? today;
    return widget.expenses.where((e) => e.date == filterDate).toList();
  }

  double get totalFilteredAmount =>
      filteredExpenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryAmounts {
    Map<String, double> amounts = {};
    for (var expense in filteredExpenses) {
      amounts.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return amounts;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 20),
            _buildPieChart(),
            const SizedBox(height: 20),
            _buildExpenseList(),
            const SizedBox(height: 20),
            _buildAddButton(context),
          ],
        ),
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
          icon: const Icon(Icons.calendar_today),
          onPressed: _pickDate,
        ),
      ],
    );
  }

  Widget _buildPieChart() {
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
              sections: categoryAmounts.entries.map((entry) {
                return PieChartSectionData(
                  value: entry.value,
                  title: '${entry.key}\n${entry.value.toStringAsFixed(0)}',
                  color: AppColors.customColors[
                      categoryAmounts.keys.toList().indexOf(entry.key) %
                          AppColors.customColors.length],
                  radius: 100,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 60,
              sectionsSpace: 4,
            ),
          ),
        ),
        Positioned(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الإجمالي',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                '${totalFilteredAmount.toStringAsFixed(2)} ج.م',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseList() {
    if (filteredExpenses.isEmpty) {
      return const Center(
          child: Text('لا توجد مصروفات لهذا اليوم',
              style: TextStyle(fontSize: 16)));
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
      child: ListTile(
        title: Text(expense.product),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكمية: ${expense.quantity} ${expense.unitType}'),
            Text('السعر: ${expense.unitPrice.toStringAsFixed(2)} ج.م/وحدة'),
            _buildPaymentStatus(expense),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${expense.amount.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            Text(expense.category,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(Expense expense) {
    return GestureDetector(
      onTap: () => _togglePaymentStatus(expense),
      child: Row(
        children: [
          Icon(expense.paid ? Icons.check_circle : Icons.cancel,
              color: expense.paid ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 4),
          Text(expense.paid ? 'تم الدفع' : 'لم يتم الدفع',
              style: TextStyle(
                  color: expense.paid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold)),
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
              child: const Text(
                'إلغاء',
                style: TextStyle(color: AppColors.blackColor),
              )),
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

  void _togglePaymentStatus(Expense expense) {
    context.read<ExpenseCubit>().togglePaymentStatus(expense.id, !expense.paid);
  }

  void _navigateToAddExpense(BuildContext context) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => const AddExpenseScreen()));
  }
}
