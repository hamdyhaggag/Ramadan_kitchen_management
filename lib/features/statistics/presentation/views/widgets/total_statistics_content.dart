import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/utils/app_colors.dart';

class TotalStatisticsContent extends StatefulWidget {
  const TotalStatisticsContent({super.key});

  @override
  State<TotalStatisticsContent> createState() => _TotalStatisticsContentState();
}

class _TotalStatisticsContentState extends State<TotalStatisticsContent> {
  int _totalIndividuals = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('created_at', isGreaterThanOrEqualTo: startOfDay)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Get the latest document for today
        final latestDoc = snapshot.docs.first;
        final dailyValue = latestDoc['numberOfIndividuals'] as int? ?? 0;

        // Get historical data (previous days)
        final historicalSnapshot = await FirebaseFirestore.instance
            .collection('donations')
            .where('created_at', isLessThan: startOfDay)
            .get();

        // Sum historical values
        int historicalTotal = historicalSnapshot.docs.fold(
          0,
          (sum, doc) => sum + (doc['numberOfIndividuals'] as int? ?? 0),
        );

        setState(() {
          _totalIndividuals = historicalTotal + dailyValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildShimmerLoading()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          child: CustomPaint(
                            painter: _RadialPainter(),
                            size: const Size(350, 350),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'إجمالي الأفراد',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            AnimatedCount(
                              count: _totalIndividuals,
                              duration: const Duration(seconds: 1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.customColors[4], // 10% shade
                              ),
                            ),
                            Text(
                              'تم إطعامهم',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Progress wave animation
                    Container(
                      height: 20,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                width: constraints.maxWidth *
                                    (_totalIndividuals / 1000),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.secondaryColor,
                                      AppColors.primaryColor
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            },
                          ),
                          Center(
                            child: Text(
                              '${(_totalIndividuals / 1000 * 100).toStringAsFixed(1)}% من الهدف',
                              style: const TextStyle(
                                color: AppColors.whiteColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: 200,
            height: 100,
            color: AppColors.whiteColor,
          ),
          const SizedBox(height: 30),
          Container(
            width: 200,
            height: 20,
            color: AppColors.whiteColor,
          ),
        ],
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 8; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width - i * 15,
          height: size.height - i * 15,
        ),
        0,
        pi * 1.5,
        false,
        paint..strokeWidth = 2 - (i * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedCount extends ImplicitlyAnimatedWidget {
  final int count;
  final TextStyle? style;

  const AnimatedCount({
    super.key,
    required this.count,
    required this.style,
    required super.duration,
  });

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _AnimatedCountState();
}

class _AnimatedCountState extends AnimatedWidgetBaseState<AnimatedCount> {
  IntTween? _countTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _countTween = visitor(
      _countTween,
      widget.count,
      (dynamic value) => IntTween(begin: value as int),
    ) as IntTween;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_countTween?.evaluate(animation) ?? 0}',
      style: widget.style,
    );
  }
}
