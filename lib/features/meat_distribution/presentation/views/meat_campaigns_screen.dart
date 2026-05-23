import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/meat_campaigns_cubit.dart';
import '../../logic/meat_campaigns_state.dart';
import '../../data/models/meat_campaign_model.dart';
import '../../../../core/utils/app_colors.dart';
import 'meat_distribution_screen.dart';
// import 'meat_distribution_screen.dart'; // We will build this next

class MeatCampaignsScreen extends StatelessWidget {
  const MeatCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MeatCampaignsCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Slate 50
        appBar: AppBar(
          title: const Text(
            'مواسم الخير (اللحوم)',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B)),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        ),
        body: const _CampaignsList(),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _showAddCampaignSheet(context),
            backgroundColor: AppColors.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'مشروع جديد',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCampaignSheet(BuildContext context) {
    final cubit = context.read<MeatCampaignsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCampaignSheet(
        onAdd: (campaign) {
          cubit.addCampaign(campaign);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _CampaignsList extends StatelessWidget {
  const _CampaignsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeatCampaignsCubit, MeatCampaignsState>(
      builder: (context, state) {
        if (state is MeatCampaignsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (state is MeatCampaignsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 60),
                const SizedBox(height: 16),
                Text(state.message,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          );
        }
        if (state is MeatCampaignsLoaded) {
          final campaigns = state.campaigns;
          if (campaigns.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      'assets/icons/meat.png', // Assuming we have an icon, else fallback to Icon widget
                      width: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shopping_bag_outlined,
                              size: 100, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'لا توجد مشاريع لحوم موزعة حاليًا',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط على الزر بالأسفل لإضافة ذبيحة جديدة',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 90),
            itemCount: campaigns.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _CampaignCard(campaign: campaigns[index]);
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final MeatCampaign campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final remaining = campaign.weightAfter - campaign.totalDistributed;
    final progress = campaign.weightAfter > 0
        ? (campaign.totalDistributed / campaign.weightAfter).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        final cubit = context.read<MeatCampaignsCubit>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: cubit,
              child: MeatDistributionScreen(campaign: campaign),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMMM yyyy', 'ar')
                                  .format(campaign.date),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      campaign.animalType,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showEditSheet(context, campaign);
                      } else if (val == 'delete') {
                        _showDeleteDialog(context, campaign);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: AppColors.primaryColor), SizedBox(width: 8), Text('تعديل')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.redAccent))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Stats Cards
              Row(
                children: [
                   Expanded(
                    child: _StatBox(
                        icon: Icons.monitor_weight_outlined,
                        title: 'الوزن القائم',
                        value: '${campaign.weightBefore} كجم',
                        color: const Color(0xFF6366F1), // Indigo
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                        icon: Icons.scale_outlined,
                        title: 'الوزن الصافي',
                        value: '${campaign.weightAfter} كجم',
                        color: const Color(0xFF10B981), // Emerald
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'التقدم في التوزيع',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(1)} كجم' : 'اكتمل التوزيع 🎉',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? AppColors.primaryColor : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      remaining <= 0 ? const Color(0xFF10B981) : AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, MeatCampaign campaign) {
    final cubit = context.read<MeatCampaignsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditCampaignSheet(
        campaign: campaign,
        onSave: (data) {
          cubit.updateCampaign(campaign.id, data);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MeatCampaign campaign) {
    final cubit = context.read<MeatCampaignsCubit>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('حذف المشروع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18))),
            ],
          ),
          content: Text('هل أنت متأكد من حذف مشروع "${campaign.title}"؟\nسيتم حذف جميع بيانات التوزيع المرتبطة به نهائياً.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                Navigator.pop(ctx);
                cubit.deleteCampaign(campaign.id);
              },
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCampaignSheet extends StatefulWidget {
  final Function(MeatCampaign) onAdd;
  const _AddCampaignSheet({required this.onAdd});

  @override
  State<_AddCampaignSheet> createState() => _AddCampaignSheetState();
}

class _AddCampaignSheetState extends State<_AddCampaignSheet> {
  final _titleCtrl = TextEditingController();
  final _animalCtrl = TextEditingController();
  final _weightBeforeCtrl = TextEditingController();
  final _weightAfterCtrl = TextEditingController();
  final _sharePerPersonCtrl = TextEditingController(text: '0.5');

  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'مشروع توزيع جديد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            _buildField(
              controller: _titleCtrl,
              label: 'اسم المناسبة (مثال: عقيقة، صدقة)',
              icon: Icons.event,
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _animalCtrl,
              label: 'نوع الذبيحة (عجل، خروف..)',
              icon: Icons.pets,
            ),
            const SizedBox(height: 16),
            
            // Weights Row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _weightBeforeCtrl,
                    label: 'الوزن القائم (كجم)',
                    icon: Icons.monitor_weight_outlined,
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    controller: _weightAfterCtrl,
                    label: 'الوزن الصافي (كجم)',
                    icon: Icons.scale_outlined,
                    isNumber: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            _buildField(
              controller: _sharePerPersonCtrl,
              label: 'حصة الفرد (كجم) - مثال: 0.5',
              icon: Icons.person_outline,
              isNumber: true,
            ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2040),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              icon: const Icon(Icons.calendar_month, color: Color(0xFF64748B)),
              label: Text(
                'تاريخ الذبح: ${DateFormat('dd MMMM yyyy', 'ar').format(_selectedDate)}',
                style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final title = _titleCtrl.text.trim();
                final animal = _animalCtrl.text.trim();
                final before = double.tryParse(_weightBeforeCtrl.text) ?? 0;
                final after = double.tryParse(_weightAfterCtrl.text) ?? 0;

                if (title.isEmpty || animal.isEmpty || after == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى تعبئة كافة الحقول المطلوبة بشكل صحيح')),
                  );
                  return;
                }

                widget.onAdd(MeatCampaign(
                  id: '',
                  title: title,
                  animalType: animal,
                  weightBefore: before,
                  weightAfter: after,
                  totalDistributed: 0,
                  date: _selectedDate,
                  sharePerPerson: double.tryParse(_sharePerPersonCtrl.text) ?? 0.5,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('حفظ المشروع',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// EDIT CAMPAIGN BOTTOM SHEET
// ────────────────────────────────────────────────
class _EditCampaignSheet extends StatefulWidget {
  final MeatCampaign campaign;
  final Function(Map<String, dynamic>) onSave;
  const _EditCampaignSheet({required this.campaign, required this.onSave});

  @override
  State<_EditCampaignSheet> createState() => _EditCampaignSheetState();
}

class _EditCampaignSheetState extends State<_EditCampaignSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _animalCtrl;
  late final TextEditingController _weightBeforeCtrl;
  late final TextEditingController _weightAfterCtrl;
  late final TextEditingController _sharePerPersonCtrl;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.campaign.title);
    _animalCtrl = TextEditingController(text: widget.campaign.animalType);
    _weightBeforeCtrl = TextEditingController(text: widget.campaign.weightBefore.toString());
    _weightAfterCtrl = TextEditingController(text: widget.campaign.weightAfter.toString());
    _sharePerPersonCtrl = TextEditingController(text: widget.campaign.sharePerPerson.toString());
    _selectedDate = widget.campaign.date;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('تعديل المشروع', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            _buildField(controller: _titleCtrl, label: 'اسم المناسبة', icon: Icons.event),
            const SizedBox(height: 16),
            _buildField(controller: _animalCtrl, label: 'نوع الذبيحة', icon: Icons.pets),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField(controller: _weightBeforeCtrl, label: 'الوزن القائم', icon: Icons.monitor_weight_outlined, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(controller: _weightAfterCtrl, label: 'الوزن الصافي', icon: Icons.scale_outlined, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(controller: _sharePerPersonCtrl, label: 'حصة الفرد (كجم)', icon: Icons.person_outline, isNumber: true),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2040));
                if (date != null) setState(() => _selectedDate = date);
              },
              icon: const Icon(Icons.calendar_month, color: Color(0xFF64748B)),
              label: Text('تاريخ الذبح: ${DateFormat('dd MMMM yyyy', 'ar').format(_selectedDate)}', style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final title = _titleCtrl.text.trim();
                final animal = _animalCtrl.text.trim();
                final before = double.tryParse(_weightBeforeCtrl.text) ?? 0;
                final after = double.tryParse(_weightAfterCtrl.text) ?? 0;
                final share = double.tryParse(_sharePerPersonCtrl.text) ?? 0.5;

                if (title.isEmpty || animal.isEmpty || after == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تعبئة كافة الحقول المطلوبة')));
                  return;
                }

                widget.onSave({
                  'title': title,
                  'animalType': animal,
                  'weightBefore': before,
                  'weightAfter': after,
                  'sharePerPerson': share,
                  'date': Timestamp.fromDate(_selectedDate),
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
