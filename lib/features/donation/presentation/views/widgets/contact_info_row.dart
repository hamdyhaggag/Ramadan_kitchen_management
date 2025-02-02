import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/app_colors.dart';

class ContactInfoRow extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;

  const ContactInfoRow({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  State<ContactInfoRow> createState() => _ContactInfoRowState();
}

class _ContactInfoRowState extends State<ContactInfoRow> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.whiteColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _copyToClipboard(context, widget.value),
        hoverColor: AppColors.primaryColor.withValues(alpha: 0.05),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      widget.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'نسخ إلى الحافظة',
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Icon(
                            Icons.check_rounded,
                            key: const ValueKey('check'),
                            color: AppColors.primaryColor,
                            size: 20,
                          )
                        : Icon(
                            Icons.copy_rounded,
                            key: const ValueKey('copy'),
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                  ),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _copyToClipboard(context, widget.value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    FlutterClipboard.copy(text).then((_) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم النسخ بنجاح"),
          backgroundColor: AppColors.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    });
  }
}
