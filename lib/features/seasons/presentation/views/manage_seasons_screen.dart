import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/ramadan_season_model.dart';
import '../../logic/season_cubit.dart';
import '../../../manage_cases/logic/cases_cubit.dart';
import '../../../donation/presentation/cubit/donation_cubit.dart';

/// Admin screen for managing Ramadan seasons
class ManageSeasonsScreen extends StatefulWidget {
  const ManageSeasonsScreen({super.key});

  @override
  State<ManageSeasonsScreen> createState() => _ManageSeasonsScreenState();
}

class _ManageSeasonsScreenState extends State<ManageSeasonsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SeasonCubit>().loadAllSeasons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'إدارة المواسم الرمضانية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'DIN',
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_right_3, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSeasonDialog(context),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Iconsax.add_circle, color: Colors.white),
        label: const Text(
          'موسم جديد',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'DIN',
          ),
        ),
      ),
      body: BlocConsumer<SeasonCubit, SeasonState>(
        listener: (context, state) {
          if (state is SeasonCreated) {
            _showSuccessSnackbar('تم إنشاء الموسم "${state.seasonName}" بنجاح');
          } else if (state is SeasonActivated) {
            _showSuccessSnackbar('تم تفعيل الموسم بنجاح');
          } else if (state is SeasonArchived) {
            _showSuccessSnackbar('تم أرشفة الموسم بنجاح');
          } else if (state is SeasonDeleted) {
            _showSuccessSnackbar('تم حذف الموسم بنجاح');
          } else if (state is SeasonError) {
            _showErrorSnackbar(state.message);
          }
        },
        builder: (context, state) {
          if (state is SeasonLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SeasonsListLoaded) {
            if (state.seasons.isEmpty) {
              return _buildEmptyState();
            }
            return _buildSeasonsList(state.seasons, state.activeSeason);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.calendar_1,
              size: 64,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد مواسم رمضانية',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر بالأسفل لإنشاء موسم جديد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsList(
      List<RamadanSeasonModel> seasons, RamadanSeasonModel? activeSeason) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seasons.length,
      itemBuilder: (context, index) {
        final season = seasons[index];
        return _buildSeasonCard(season, season.id == activeSeason?.id);
      },
    );
  }

  Widget _buildSeasonCard(RamadanSeasonModel season, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.8),
                      ],
                    )
                  : season.isArchived
                      ? LinearGradient(
                          colors: [
                            Colors.grey[600]!,
                            Colors.grey[500]!,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.orange[600]!,
                            Colors.orange[400]!,
                          ],
                        ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.moon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'DIN',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        season.dateRangeFormatted,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive
                        ? 'نشط'
                        : season.isArchived
                            ? 'مؤرشف'
                            : 'غير نشط',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (season.isMigratedToV2) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Text(
                      'V2',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Statistics (if available)
          if (season.statistics != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatItem(
                    icon: Iconsax.people,
                    label: 'الحالات',
                    value: '${season.statistics!.totalCases}',
                  ),
                  _buildStatItem(
                    icon: Iconsax.category,
                    label: 'المجموعات',
                    value: '${season.statistics!.totalGroups}',
                  ),
                  _buildStatItem(
                    icon: Iconsax.activity,
                    label: 'الوجبات',
                    value: '${season.statistics!.totalMealsServed}',
                  ),
                  _buildStatItem(
                    icon: Iconsax.money,
                    label: 'المصروفات',
                    value:
                        '${season.statistics!.totalExpenses.toStringAsFixed(0)} ج',
                  ),
                ],
              ),
            ),

          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isActive)
                  _buildActionButton(
                    icon: Iconsax.info_circle,
                    label: 'إيقاف تفعيل',
                    color: Colors.blueGrey,
                    onTap: () => _confirmDeactivate(season),
                  ),
                if (!isActive)
                  _buildActionButton(
                    icon: Iconsax.tick_circle,
                    label: 'تفعيل',
                    color: Colors.green,
                    onTap: () => _confirmActivate(season),
                  ),
                if (!season.isArchived)
                  _buildActionButton(
                    icon: Iconsax.archive_1,
                    label: 'أرشفة',
                    color: Colors.orange,
                    onTap: () => _confirmArchive(season),
                  ),
                if (season.isArchived)
                  _buildActionButton(
                    icon: Iconsax.refresh_2,
                    label: 'إلغاء أرشفة',
                    color: Colors.teal,
                    onTap: () => _confirmUnarchive(season),
                  ),
                _buildActionButton(
                  icon: Iconsax.import_1,
                  label: 'استيراد بيانات',
                  color: Colors.purple,
                  onTap: () => _showImportDialog(season),
                ),
                _buildActionButton(
                  icon: Iconsax.edit_2,
                  label: 'تعديل',
                  color: AppColors.primaryColor,
                  onTap: () => _showEditSeasonDialog(context, season),
                ),
                if (!season.isMigratedToV2)
                  _buildActionButton(
                    icon: Iconsax.recovery_convert,
                    label: 'هجرة V2',
                    color: Colors.blueAccent,
                    onTap: () => _confirmMigration(season),
                  ),
                _buildActionButton(
                  icon: Iconsax.trash,
                  label: 'حذف',
                  color: Colors.red,
                  onTap: () => _confirmDelete(season),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'DIN',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSeasonDialog(BuildContext context) {
    final nameController = TextEditingController();
    final hijriYearController = TextEditingController();
    final gregorianYearController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool copyFromPrevious = false;
    bool copyDonationSettings = false;
    bool isMigratedToV2 = false;
    String? sourceSeasonId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Iconsax.moon, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'إنشاء موسم جديد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الموسم',
                    hintText: 'مثال: رمضان 1447 هـ - 2026',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Iconsax.text),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hijriYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'السنة الهجرية',
                          hintText: '1447',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: gregorianYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'السنة الميلادية',
                          hintText: '2026',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker(
                  label: 'تاريخ البداية',
                  selectedDate: startDate,
                  onSelect: (date) {
                    setState(() => startDate = date);
                  },
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  label: 'تاريخ النهاية',
                  selectedDate: endDate,
                  onSelect: (date) {
                    setState(() => endDate = date);
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text(
                    'نسخ الحالات والمجموعات من موسم سابق',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: copyFromPrevious,
                  onChanged: (value) {
                    setState(() => copyFromPrevious = value ?? false);
                  },
                  activeColor: AppColors.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.1)),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'نظام التخزين المطور (V2)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor),
                    ),
                    subtitle: const Text(
                      'تفعيل هيكلة البيانات الجديدة المحسنة لهذا الموسم.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isMigratedToV2,
                    onChanged: (value) {
                      setState(() => isMigratedToV2 = value ?? false);
                    },
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                  );
                  return;
                }
                Navigator.pop(context);
                context.read<SeasonCubit>().createSeason(
                      name: nameController.text,
                      hijriYear: hijriYearController.text,
                      gregorianYear: gregorianYearController.text,
                      startDate: startDate!,
                      endDate: endDate!,
                      isActive: false,
                      isMigratedToV2: isMigratedToV2,
                      copyFromPreviousSeason: copyFromPrevious,
                      copyDonationSettings:
                          copyDonationSettings, // Pass new param
                      sourceSeasonId: sourceSeasonId,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('إنشاء', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar_1, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(selectedDate)
                  : label,
              style: TextStyle(
                color: selectedDate != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSeasonDialog(BuildContext context, RamadanSeasonModel season) {
    final nameController = TextEditingController(text: season.name);
    final hijriYearController = TextEditingController(text: season.hijriYear);
    final gregorianYearController =
        TextEditingController(text: season.gregorianYear);
    DateTime startDate = season.startDate;
    DateTime endDate = season.endDate;
    bool isMigratedToV2 = season.isMigratedToV2;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Iconsax.edit_2, color: AppColors.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'تعديل الموسم',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontFamily: 'DIN'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الموسم',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Iconsax.text),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hijriYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'السنة الهجرية',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: gregorianYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'السنة الميلادية',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker(
                  label: 'تاريخ البداية',
                  selectedDate: startDate,
                  onSelect: (date) => setState(() => startDate = date),
                ),
                const SizedBox(height: 12),
                _buildDatePicker(
                  label: 'تاريخ النهاية',
                  selectedDate: endDate,
                  onSelect: (date) => setState(() => endDate = date),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.1)),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'نظام التخزين المطور (V2)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor),
                    ),
                    value: isMigratedToV2,
                    onChanged: (value) {
                      setState(() => isMigratedToV2 = value ?? false);
                    },
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<SeasonCubit>().updateSeason(
                      season.copyWith(
                        name: nameController.text,
                        hijriYear: hijriYearController.text,
                        gregorianYear: gregorianYearController.text,
                        startDate: startDate,
                        endDate: endDate,
                        isMigratedToV2: isMigratedToV2,
                        updatedAt: DateTime.now(),
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('حفظ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmActivate(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('تفعيل الموسم', style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'هل تريد تفعيل "${season.name}"؟\n\nسيتم إلغاء تفعيل أي موسم آخر نشط.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SeasonCubit>().activateSeason(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تفعيل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.archive_1, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('أرشفة الموسم', style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'هل تريد أرشفة "${season.name}"؟\n\nسيتم حفظ جميع الإحصائيات النهائية ولن يمكن التعديل عليه.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SeasonCubit>().archiveSeason(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('أرشفة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.info_circle, color: Colors.blueGrey),
            const SizedBox(width: 12),
            const Text('إيقاف تفعيل الموسم',
                style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'هل تريد إيقاف تفعيل "${season.name}"؟\n\nلن يظهر هذا الموسم في الشاشة الرئيسية حتى يتم تفعيله مرة أخرى.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SeasonCubit>().deactivateSeason(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmUnarchive(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.refresh_2, color: Colors.teal),
            const SizedBox(width: 12),
            const Text('إلغاء أرشفة الموسم',
                style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'هل تريد إلغاء أرشفة "${season.name}"؟\n\nسيعود الموسم لقائمة المواسم الحالية ويمكنك التعديل عليه.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SeasonCubit>().unarchiveSeason(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.trash, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('حذف الموسم', style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${season.name}"؟\n\n⚠️ تحذير: سيتم حذف جميع البيانات المرتبطة بهذا الموسم نهائياً!',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SeasonCubit>().deleteSeason(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmMigration(RamadanSeasonModel season) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.recovery_convert, color: Colors.blueAccent),
            const SizedBox(width: 12),
            const Text('تحويل للنظام الجديد',
                style: TextStyle(fontFamily: 'DIN')),
          ],
        ),
        content: Text(
          'سيتم نقل جميع بيانات موسم "${season.name}" (الحالات، المجموعات، التبرعات، المصاريف، الإشعارات) إلى هيكلة V2 المنظمة.\n\nهذه العملية آمنة وتحافظ على البيانات الأصلية.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SeasonCubit>().migrateSeasonToV2(season.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('بدء التحويل',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.danger, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Legacy migration dialog removed

  void _showImportDialog(RamadanSeasonModel currentSeason) {
    // Capture the screen context to use later for providers safely
    final screenContext = context;

    // We assume the user wants to import from the most recent ARCHIVED season
    // or simply the most recent season that is NOT the current one.
    // For simplicity, let's fetch the list and pick the first one that isn't current.

    // We'll show a loading state first or just resolve this inside the dialog builder
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<RamadanSeasonModel>>(
          // Get all seasons (sorted newest first) using screenContext
          future: screenContext
              .read<SeasonCubit>()
              .getSeasonById('dummy')
              .then((_) async {
            // Hacky way to access service, better expose a method in cubit
            // But simpler: just use what we have in the state or fetch fresh
            // Actually, we can just use the cubit to get all seasons
            // Let's rely on the user to pick? No, auto-pick latest previous
            final seasons = await screenContext.read<SeasonCubit>().state
                    is SeasonsListLoaded
                ? (screenContext.read<SeasonCubit>().state as SeasonsListLoaded)
                    .seasons
                : <RamadanSeasonModel>[];

            // Filter out current season
            return seasons.where((s) => s.id != currentSeason.id).toList();
          }),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final previousSeasons = snapshot.data!;
            if (previousSeasons.isEmpty) {
              return AlertDialog(
                title: const Text('لا توجد مواسم سابقة'),
                content: const Text('لا يوجد موسم آخر لاستيراد البيانات منه.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('حسناً'))
                ],
              );
            }

            // Default to the first one (most recent)
            String selectedSourceId = previousSeasons.first.id;
            bool importCases = true;
            bool importGroups = true;
            bool importDonationSettings = false;

            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Iconsax.import_1, color: Colors.purple[600]),
                    const SizedBox(width: 12),
                    const Text('استيراد بيانات',
                        style: TextStyle(fontFamily: 'DIN')),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'استيراد بيانات إلى "${currentSeason.name}" من:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSourceId,
                            isExpanded: true,
                            items: previousSeasons
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => selectedSourceId = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('اختر البيانات المراد نسخها:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('الحالات (مع تصفير حالة الاستلام)'),
                        value: importCases,
                        onChanged: (v) => setState(() => importCases = v!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.purple,
                      ),
                      CheckboxListTile(
                        title: const Text('المجموعات'),
                        value: importGroups,
                        onChanged: (v) => setState(() => importGroups = v!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.purple,
                      ),
                      CheckboxListTile(
                        title: const Text(
                            'إعدادات التبرع (بيانات الاتصال والصور)'),
                        subtitle: const Text('يتم إنشاء مسودة للوجبة الأولى'),
                        value: importDonationSettings,
                        onChanged: (v) =>
                            setState(() => importDonationSettings = v!),
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      // Show loading dialog
                      showDialog(
                        context: screenContext,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('جاري نسخ البيانات...'),
                            ],
                          ),
                        ),
                      );

                      await screenContext
                          .read<SeasonCubit>()
                          .importDataFromSeason(
                            targetSeasonId: currentSeason.id,
                            sourceSeasonId: selectedSourceId,
                            importCases: importCases,
                            importGroups: importGroups,
                            importDonationSettings: importDonationSettings,
                          );

                      if (screenContext.mounted) {
                        Navigator.of(screenContext)
                            .pop(); // Close loading dialog (using parent context nav)

                        // Force refresh other cubits using the safe parent context
                        screenContext.read<CasesCubit>().loadCases();

                        // Also refresh donations if settings were copied
                        if (importDonationSettings) {
                          screenContext.read<DonationCubit>().getDonations();
                        }

                        _showSuccessSnackbar(
                            'تم استيراد البيانات المختارة بنجاح');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple),
                    child: const Text('استيراد',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
