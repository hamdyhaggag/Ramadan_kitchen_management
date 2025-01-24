import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';
import '../../core/utils/app_colors.dart';
import '../daily_expenses/logic/expense_state.dart';

String formatDateString(String dateString) {
  try {
    return DateFormat('EEEE , d MMM yyyy', 'ar')
        .format(DateTime.parse(dateString));
  } catch (e) {
    return 'تاريخ غير صالح';
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ExpenseCubit>().loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPaymentStatus(bool isPaid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          isPaid ? Icons.check_circle : Icons.cancel,
          color: isPaid ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          isPaid ? 'تم الدفع' : 'لم يتم الدفع',
          style: TextStyle(
            color: isPaid ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Map<String, List<Expense>> groupExpensesByDate(List<Expense> expenses,
      {bool unpaidOnly = false}) {
    final grouped = <String, List<Expense>>{};
    for (var expense in expenses) {
      if (unpaidOnly && expense.paid) continue;
      grouped.putIfAbsent(expense.date, () => []);
      grouped[expense.date]!.add(expense);
    }
    return grouped;
  }

  Widget _buildExpensesList(Map<String, List<Expense>> groupedExpenses) {
    final sortedEntries = groupedExpenses.entries.toList()
      ..sort((a, b) => _isAscending
          ? DateTime.parse(a.key).compareTo(DateTime.parse(b.key))
          : DateTime.parse(b.key).compareTo(DateTime.parse(a.key)));

    if (sortedEntries.isEmpty) {
      return const Center(
          child: Text('لا توجد مصروفات مسجلة', style: TextStyle(fontSize: 16)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: AppColors.primaryColor.withAlpha(200)),
                      const SizedBox(width: 8),
                      Text(formatDateString(entry.key),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Text('${entry.value.length} مصروفات',
                          style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(width: 8),
                      Text('${total.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatDateString(entry.key),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...entry.value.map((expense) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(expense.product,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      'المبلغ: ${expense.amount.toStringAsFixed(2)} ج.م',
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13)),
                                ],
                              ),
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primaryColor.withAlpha(200),
                                child: const Icon(Icons.attach_money,
                                    color: Colors.white),
                              ),
                              trailing: SizedBox(
                                width: 80,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildPaymentStatus(expense.paid),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير اليومية'),
          actions: [
            IconButton(
              icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => setState(() => _isAscending = !_isAscending),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'جميع المصروفات'),
              Tab(text: 'غير المدفوعة'),
            ],
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'DIN',
              color: AppColors.primaryColor,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontFamily: 'DIN',
              color: Colors.grey,
            ),
          ),
        ),
        body: BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            if (state is ExpenseLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ExpenseError) {
              return Center(child: Text(state.message));
            }
            if (state is ExpenseLoaded) {
              return TabBarView(
                children: [
                  _buildExpensesList(groupExpensesByDate(state.expenses)),
                  _buildExpensesList(
                      groupExpensesByDate(state.expenses, unpaidOnly: true)),
                ],
              );
            }
            return const Center(child: Text('لا توجد مصروفات'));
          },
        ),
      ),
    );
  }
}
