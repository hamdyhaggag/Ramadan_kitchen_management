import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_cubit.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/logic/expense_state.dart';
import 'package:ramadan_kitchen_management/features/daily_expenses/model/expense_model.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/services/service_locator.dart';

String formatDateString(String dateString) {
  try {
    return DateFormat('EEEE ، d MMM yyyy', 'ar')
        .format(DateTime.parse(dateString));
  } catch (e) {
    return 'تاريخ غير صالح';
  }
}

String formatDateDay(String dateString) {
  try {
    return DateFormat('d', 'ar').format(DateTime.parse(dateString));
  } catch (e) {
    return '-';
  }
}

String formatDateMonthYear(String dateString) {
  try {
    return DateFormat('MMMM yyyy', 'ar').format(DateTime.parse(dateString));
  } catch (e) {
    return '-';
  }
}

String formatDayName(String dateString) {
  try {
    return DateFormat('EEEE', 'ar').format(DateTime.parse(dateString));
  } catch (e) {
    return '-';
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
  bool _isAscending = false; // Default to newest first
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.empty_wallet, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('لم يتم تسجيل أي مصروفات',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Elegant Header Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'إجمالي المصروفات',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      NumberFormat('#,###').format(total),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.blackColor,
                        fontFamily: 'DIN',
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sortedEntries.length} يوم',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // List Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: sortedEntries.map((entry) {
                final dayTotal =
                    entry.value.fold(0.0, (sum, e) => sum + e.amount);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => _showDetailsBottomSheet(
                        context, entry.key, entry.value, dayTotal),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Date Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  formatDateDay(entry.key),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blackColor,
                                    height: 1,
                                    fontFamily: 'DIN',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDayName(entry.key),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDateMonthYear(entry.key),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blackColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Iconsax.bag_2,
                                        size: 14, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.value.length} عملية شراء',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat('#,###').format(dayTotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryColor,
                                  fontFamily: 'DIN',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ج.م',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 80), // Fab space mostly
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

    if (sortedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box_remove, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('لا توجد بيانات كميات',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: sortedEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final expense = expenses.firstWhere((e) => e.product == entry.key);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _getUnitTypeColor(expense.unitType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.box,
                color: _getUnitTypeColor(expense.unitType),
                size: 22,
              ),
            ),
            title: Text(entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                )),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${_getPurchaseCount(expenses, entry.key)} مرات شراء',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.value.toStringAsFixed(1).replaceAll('.0', ''),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blackColor,
                    fontFamily: 'DIN',
                  ),
                ),
                Text(
                  expense.unitType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            onTap: () =>
                _showQuantityDetails(context, entry.key, entry.value, expenses),
          ),
        );
      },
    );
  }

  Color _getUnitTypeColor(String unitType) {
    switch (unitType) {
      case 'كجم':
        return const Color(0xFF10B981); // Emerald Green
      case 'لتر':
        return const Color(0xFF3B82F6); // Blue
      case 'علبة':
        return const Color(0xFFF59E0B); // Amber
      case 'عدد':
        return const Color(0xFF8B5CF6); // Violet
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
            child: pw.Text('تقرير المصروفات',
                style: pw.TextStyle(font: arabicFont, fontSize: 24),
                textDirection: pw.TextDirection.rtl),
          ),
          ...groupedData.entries.map((entry) {
            final total = entry.value.fold(0.0, (sum, e) => sum + e.amount);
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.grey100,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${total.toStringAsFixed(0)} ج.م',
                        style: pw.TextStyle(
                            font: arabicFont, fontWeight: pw.FontWeight.bold),
                        textDirection: pw.TextDirection.rtl,
                      ),
                      pw.Text(
                        formatDateString(entry.key),
                        style: pw.TextStyle(
                            font: arabicFont, fontWeight: pw.FontWeight.bold),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    ...entry.value.map((expense) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(expense.product,
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.right),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(expense.amount.toStringAsFixed(0),
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                  '${expense.quantity} ${expense.unitType}',
                                  style: pw.TextStyle(font: arabicFont),
                                  textDirection: pw.TextDirection.rtl,
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }),
          pw.SizedBox(height: 20),
          pw.Text(
              'تم الاستخراج: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(
                  font: arabicFont, fontSize: 10, color: PdfColors.grey600),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Expense_Report_${DateTime.now().toIso8601String()}.pdf',
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تصدير التقرير'),
        content: const Text('هل تريد تصدير التقرير اليومي كملف PDF؟'),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('تصدير PDF', style: TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.white,
        appBar: isAdmin
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'التقارير اليومية',
                  style: TextStyle(
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_right_3, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Iconsax.document_download,
                        color: AppColors.primaryColor),
                    onPressed: () => _showExportDialog(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _isAscending ? Iconsax.sort : Iconsax.sort,
                      color: Colors.black,
                    ),
                    onPressed: () =>
                        setState(() => _isAscending = !_isAscending),
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : null,
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
                      labelColor: AppColors.primaryColor,
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

void _showDetailsBottomSheet(BuildContext context, String dateKey,
    List<Expense> expenses, double total) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDayName(dateKey),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDateDay(dateKey)} ${formatDateMonthYear(dateKey)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    NumberFormat('#,###').format(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryColor,
                      fontFamily: 'DIN',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Icon(
                        Iconsax.bag_2,
                        size: 22,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.product,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${expense.quantity} ${expense.unitType}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      expense.amount.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DIN',
                        color: AppColors.blackColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void _showQuantityDetails(BuildContext context, String product,
    double totalQuantity, List<Expense> allExpenses) {
  final productExpenses =
      allExpenses.where((e) => e.product == product).toList();
  productExpenses.sort((a, b) =>
      DateTime.parse(b.date).compareTo(DateTime.parse(a.date))); // Recent first

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل شراء',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blackColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الإجمالي',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    Text(
                      '${totalQuantity.toStringAsFixed(1).replaceAll('.0', '')} ${productExpenses.first.unitType}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryColor,
                        fontFamily: 'DIN',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: productExpenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final expense = productExpenses[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${formatDateDay(expense.date)}/${DateFormat('M').format(DateTime.parse(expense.date))}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        formatDayName(expense.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${expense.quantity} ${expense.unitType}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'DIN',
                        color: AppColors.blackColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
