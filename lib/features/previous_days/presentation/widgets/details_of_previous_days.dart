import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_colors.dart';

class DetailsOfPreviousDay extends StatelessWidget {
  final DateTime date;
  final String mealTitle;
  final String description;
  final int participants;
  final String imageUrl;

  const DetailsOfPreviousDay({
    required this.date,
    required this.mealTitle,
    required this.description,
    required this.participants,
    required this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const LinearProgressIndicator(),
                ),
              ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const Divider(height: 40),
                  _buildDetailSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMetaChip(
              icon: Icons.calendar_month,
              label: DateFormat('EEE, d MMM , y').format(date),
            ),
            const SizedBox(width: 12),
            _buildMetaChip(
              icon: Icons.people_alt_outlined,
              label: '$participants فرد تم إفطارهم',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل الوجبة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description.isNotEmpty ? description : 'لا يوجد وصف متوفر',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
