import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_state.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';

import '../../core/services/service_locator.dart';

String formatDateString(String dateString) {
  try {
    return DateFormat('EEEE ، d MMM yyyy', 'ar')
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
  late pw.Font arabicFont;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ExpenseCubit>().loadExpenses();
    _loadFont();
  }

  Future<void> _loadFont() async {
    final fontData =
        await rootBundle.load('assets/fonts/DINNextLTArabic-Regular.ttf');
    arabicFont = pw.Font.ttf(fontData);
  }

  Map<String, List<Expense>> groupExpensesByDate(List<Expense> expenses) {
    final grouped = <String, List<Expense>>{};
    for (var expense in expenses) {
      grouped.putIfAbsent(expense.date, () => []);
      grouped[expense.date]!.add(expense);
    }
    return grouped;
  }

  Map<String, double> groupQuantitiesByProduct(List<Expense> expenses) {
    final grouped = <String, double>{};
    for (var expense in expenses) {
      grouped.update(
        expense.product,
        (value) => value + expense.quantity,
        ifAbsent: () => expense.quantity,
      );
    }
    return grouped;
  }

  Widget _buildExpensesList(Map<String, List<Expense>> groupedExpenses) {
    final total = groupedExpenses.values
        .expand((expenses) => expenses)
        .fold(0.0, (sum, e) => sum + e.amount);

    final sortedEntries = groupedExpenses.entries.toList()
      ..sort((a, b) => _isAscending
          ? DateTime.parse(a.key).compareTo(DateTime.parse(b.key))
          : DateTime.parse(b.key).compareTo(DateTime.parse(a.key)));

    if (sortedEntries.isEmpty) {
      return const Center(
        child: Text('لا توجد مصروفات مسجلة', style: TextStyle(fontSize: 16)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'إجمالي المصروفات حتى الآن : ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackColor,
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(0)} جنيه',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    title: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryColor.withAlpha(200),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formatDateString(entry.key),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                flex: 1,
                                child: Text(
                                  '${total.toStringAsFixed(0)} جنيه',
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatDateString(entry.key),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ...entry.value.map((expense) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(expense.product,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                              'المبلغ: ${expense.amount.toStringAsFixed(0)} ج.م',
                                              style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13)),
                                        ],
                                      ),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.primaryColor
                                            .withAlpha(200),
                                        child: const Icon(Icons.attach_money,
                                            color: Colors.white),
                                      ),
                                      trailing: SizedBox(
                                        width: 80,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  expense.paid
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: expense.paid
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  expense.paid
                                                      ? 'تم الدفع'
                                                      : 'لم يتم الدفع',
                                                  style: TextStyle(
                                                    color: expense.paid
                                                        ? Colors.green
                                                        : Colors.red,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'المجموع اليومي:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${total.toStringAsFixed(0)} جنيه',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitiesList(List<Expense> expenses) {
    final groupedQuantities = groupQuantitiesByProduct(expenses);
    final sortedEntries = groupedQuantities.entries.toList()
      ..sort((a, b) => _isAscending
          ? a.value.compareTo(b.value)
          : b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: sortedEntries.isEmpty
                ? const Center(
                    child: Text('لا توجد كميات مسجلة',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: sortedEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final expense =
                          expenses.firstWhere((e) => e.product == entry.key);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getUnitTypeColor(expense.unitType)
                                      .withOpacity(0.8),
                                  _getUnitTypeColor(expense.unitType),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.production_quantity_limits_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                  child: Text(entry.key,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_getPurchaseCount(expenses, entry.key)} مشتريات',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.value.toStringAsFixed(0),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor),
                              ),
                              Text(
                                expense.unitType,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          onTap: () => _showQuantityDetails(
                              context, entry.key, entry.value, expenses),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getUnitTypeColor(String unitType) {
    switch (unitType) {
      case 'كجم':
        return Colors.green.shade400;
      case 'لتر':
        return Colors.blue.shade400;
      case 'علبة':
        return Colors.orange.shade400;
      default:
        return AppColors.primaryColor;
    }
  }

  int _getPurchaseCount(List<Expense> expenses, String product) {
    return expenses.where((e) => e.product == product).length;
  }

  Future<void> _generatePdfReport(BuildContext context) async {
    final state = context.read<ExpenseCubit>().state;
    final expenses = state is ExpenseLoaded ? state.expenses : <Expense>[];
    final pdf = pw.Document();
    final groupedData = groupExpensesByDate(expenses);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
          fontFallback: [arabicFont],
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('تقرير يومي',
                style: pw.TextStyle(font: arabicFont, fontSize: 24),
                textDirection: pw.TextDirection.rtl),
          ),
          ...groupedData.entries.map((entry) {
            final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تاريخ: ${formatDateString(entry.key)}',
                  style: pw.TextStyle(
                      font: arabicFont,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      children: ['البند', 'المبلغ', 'حالة الدفع']
                          .map((text) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(text,
                                    style: pw.TextStyle(
                                        font: arabicFont,
                                        fontWeight: pw.FontWeight.bold),
                                    textDirection: pw.TextDirection.rtl,
                                    textAlign: pw.TextAlign.right),
                              ))
                          .toList(),
                    ),
                    ...entry.value.map((expense) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(expense.product,
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.right),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${expense.amount.toStringAsFixed(0)} ج.م',
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.right),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  expense.paid ? 'تم الدفع' : 'غير مدفوع',
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.right),
                            ),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('المجموع: ${total.toStringAsFixed(2)} ج.م',
                      style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16),
                      textDirection: pw.TextDirection.rtl),
                ),
                pw.SizedBox(height: 20),
              ],
            );
          }).toList(),
          pw.SizedBox(height: 20),
          pw.Text(
              'تاريخ التصدير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: arabicFont),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'daily_report_${DateTime.now().toIso8601String()}.pdf',
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير التقرير'),
        content: const Text('تصدير التقرير اليومي'),
        actions: [
          TextButton(
            child: const Text('تصدير'),
            onPressed: () {
              Navigator.pop(context);
              _generatePdfReport(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = getIt<AuthRepo>().currentUser?.role == 'admin';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير اليومية'),
          actions: [
            IconButton(
              icon: Icon(Icons.picture_as_pdf,
                  color: isAdmin ? null : Colors.grey),
              onPressed: () {
                if (isAdmin) {
                  _showExportDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا تمتلك الصلاحية لتصدير التقارير'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              onPressed: () => setState(() => _isAscending = !_isAscending),
            ),
          ],
        ),
        body: BlocBuilder<ExpenseCubit, ExpenseState>(
          builder: (context, state) {
            if (state is ExpenseLoading) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor));
            }
            if (state is ExpenseError)
              return Center(child: Text(state.message));
            if (state is ExpenseLoaded) {
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      unselectedLabelColor: AppColors.greyColor,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) => Colors.transparent,
                      ),
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        color: AppColors.primaryColor,
                        fontFamily: 'DIN',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorColor: AppColors.primaryColor,
                      tabs: const [
                        Tab(text: 'جميع المصروفات'),
                        Tab(text: 'الكميات'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExpensesList(groupExpensesByDate(state.expenses)),
                        _buildQuantitiesList(state.expenses),
                      ],
                    ),
                  ),
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

void _showQuantityDetails(BuildContext context, String product, double quantity,
    List<Expense> expenses) {
  final productExpenses = expenses.where((e) => e.product == product).toList();
  final purchaseDates = productExpenses.map((e) => e.date).toSet().toList();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      titlePadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          Icon(Icons.inventory, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Text(product, style: const TextStyle(fontSize: 20)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('الكمية الإجمالية',
                '${quantity.toStringAsFixed(0)} ${productExpenses.first.unitType}'),
            _buildDetailRow('عدد المشتريات', '${productExpenses.length} مرة'),
            const SizedBox(height: 16),
            const Text('تواريخ الشراء:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...purchaseDates.map((date) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(formatDateString(date),
                      style: TextStyle(color: Colors.grey.shade600)),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
