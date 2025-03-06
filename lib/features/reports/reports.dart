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
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Flexible(
                        //   flex: 2,
                        //   child: Text(
                        //     '${entry.value.length} مصروفات',
                        //     style: TextStyle(color: Colors.grey[700]),
                        //     overflow: TextOverflow.ellipsis,
                        //     maxLines: 1,
                        //     textAlign: TextAlign.end,
                        //   ),
                        // ),
                        // const SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: Text(
                            '${total.toStringAsFixed(0)} جنيه',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SafeArea(
                  child: SingleChildScrollView(
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
                                        'المبلغ: ${expense.amount.toStringAsFixed(0)} ج.م',
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
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          ..._buildPdfContent(groupedData),
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

  List<pw.Widget> _buildPdfContent(Map<String, List<Expense>> groupedData) {
    return groupedData.entries.map((entry) {
      final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'تاريخ: ${formatDateString(entry.key)}',
            style: pw.TextStyle(
                font: arabicFont, fontWeight: pw.FontWeight.bold, fontSize: 18),
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
                        child: pw.Text(expense.paid ? 'تم الدفع' : 'غير مدفوع',
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
    }).toList();
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
            if (state is ExpenseError) {
              return Center(child: Text(state.message));
            }
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
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) => Colors.transparent,
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
                        Tab(text: 'غير المدفوعة'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          '${state.expenses.fold(0.0, (sum, e) => sum + e.amount).toStringAsFixed(0)} جنيه',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExpensesList(groupExpensesByDate(state.expenses)),
                        _buildExpensesList(groupExpensesByDate(state.expenses,
                            unpaidOnly: true)),
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
