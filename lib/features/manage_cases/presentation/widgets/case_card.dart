import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';

class CaseCard extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final String? groupName;
  final Function(String field, bool value) onStatusChanged;
  final VoidCallback onTap;

  const CaseCard({
    super.key,
    required this.caseData,
    this.groupName,
    required this.onStatusChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final bool isReady = caseData['جاهزة'] ?? false;
    final bool isDelivered = caseData['هنا؟'] ?? false;
    final String name = caseData['الاسم'] ?? 'بدون اسم';
    final String number = caseData['الرقم'].toString();
    final String familySize = caseData['عدد الأفراد'].toString();

    // Visual State
    final bool isCompleted = isReady && isDelivered;
    final Color statusColor = isCompleted
        ? AppColors.greyColor.withOpacity(0.5)
        : AppColors.blackColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: Colors.grey[200]!)
              : Border.all(color: Colors.transparent),
          boxShadow: isCompleted
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Header: Number + Name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.grey[200]
                          : AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      number,
                      style: TextStyle(
                        color: isCompleted
                            ? AppColors.greyColor
                            : AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (groupName != null)
                          Text(
                            groupName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.greyColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildFamilyBadge(familySize, isCompleted),
                ],
              ),
            ),

            // Actions Divider
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

            // Actions Row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'تجهيز الوجبة',
                      activeLabel: 'تم التجهيز',
                      isActive: isReady,
                      activeColor: Colors.green,
                      icon: Icons.soup_kitchen_outlined,
                      activeIcon: Icons.check_circle,
                      onTap: () => onStatusChanged('جاهزة', !isReady),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      label: 'فاضل التوزيع',
                      activeLabel: 'خرجت للتوزيع',
                      isActive: isDelivered,
                      activeColor: AppColors.primaryColor,
                      icon: Icons.volunteer_activism_outlined,
                      activeIcon: Icons.handshake_rounded,
                      onTap: () => onStatusChanged('هنا؟', !isDelivered),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyBadge(String count, bool isDimmed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDimmed ? Colors.grey[200] : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 16,
            color: isDimmed ? Colors.grey : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '$count أفراد',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDimmed ? Colors.grey : Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required String activeLabel,
    required bool isActive,
    required Color activeColor,
    required IconData icon,
    required IconData activeIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // Active: Soft background (Badge style)
          // Inactive: White background (Button style)
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Active: No border (or transparent)
            // Inactive: Colored border (Call to action)
            color: isActive
                ? Colors.transparent
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              // Active: Colored Icon
              // Inactive: Grey Icon (or maybe colored to attract attention? Let's keep grey for now usually inactive is dull, but we want CTA. Let's try Colored for inactive too?)
              // User said "Colored button pulls me to click". So Active should NOT be fully colored.
              // Let's make Inactive = Grey/Black text, Active = Colored Text.
              // Wait, if Inactive is "To Do", it should probably be distinct.
              // Let's stick to the plan:
              // Active = Colored Text on Light BG.
              // Inactive = Grey Text on White BG with Grey Border. (Standard neutral).
              color: isActive ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? activeLabel : label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
