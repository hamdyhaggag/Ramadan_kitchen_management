import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TotalStatisticsContent extends StatefulWidget {
  const TotalStatisticsContent({super.key});

  @override
  State<TotalStatisticsContent> createState() => _TotalStatisticsContentState();
}

class _TotalStatisticsContentState extends State<TotalStatisticsContent>
    with TickerProviderStateMixin {
  int _totalIndividuals = 0;
  bool _isLoading = true;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _loadDonationData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  Future<void> _loadDonationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int historicalTotal = prefs.getInt('historicalTotal') ?? 0;
      int dailyValue = prefs.getInt('dailyValue') ?? 0;
      int cachedDateMillis = prefs.getInt('lastUpdated') ?? 0;

      DateTime cachedDate = cachedDateMillis == 0
          ? DateTime(1970)
          : DateTime.fromMillisecondsSinceEpoch(cachedDateMillis);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      bool isNewDay = cachedDate.isBefore(startOfDay);

      // Handle day transition
      if (isNewDay) {
        historicalTotal += dailyValue;
        dailyValue = 0;
        cachedDate = startOfDay;
        await prefs.setInt('historicalTotal', historicalTotal);
        await prefs.setInt('dailyValue', dailyValue);
        await prefs.setInt('lastUpdated', startOfDay.millisecondsSinceEpoch);
      }

      final isOnline = await _checkConnectivity();

      if (isOnline) {
        final snapshot = await FirebaseFirestore.instance
            .collection('donations')
            .where('created_at', isGreaterThanOrEqualTo: startOfDay)
            .get();

        dailyValue = snapshot.docs.isNotEmpty
            ? (snapshot.docs.first['numberOfIndividuals'] as int? ?? 0)
            : 0;

        await prefs.setInt('dailyValue', dailyValue);
        await prefs.setInt('lastUpdated', now.millisecondsSinceEpoch);
      }

      setState(() {
        _totalIndividuals = historicalTotal + dailyValue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _isLoading
              ? _buildEnhancedShimmerLoading()
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedRadialProgress(),
                        const SizedBox(height: 40),
                        _buildAnimatedProgressWave(),
                        const SizedBox(height: 30),
                        _buildFloatingParticles(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedRadialProgress() {
    return Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
          child: CustomPaint(
            painter: _AnimatedRadialPainter(),
            size: const Size(350, 350),
          ),
        ),
        Column(
          children: [
            Text(
              'إجمالي الأفراد',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(1, 1),
                  )
                ],
              ),
            ),
            AnimatedCount(
              count: _totalIndividuals,
              duration: const Duration(seconds: 1),
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.secondaryColor,
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
            Text(
              'تم إطعامهم',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedProgressWave() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(_waveController.value),
          child: Container(
            height: 30,
            width: 250,
            alignment: Alignment.center,
            child: Text(
              '${(_totalIndividuals / 1000 * 100).toStringAsFixed(1)}% من الهدف',
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedShimmerLoading() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingParticles() {
    return SizedBox(
      width: 200,
      height: 50,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: FloatingParticlePainter(_particleController.value),
          );
        },
      ),
    );
  }
}

class _AnimatedRadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = SweepGradient(
      colors: [
        AppColors.primaryColor.withValues(alpha: 0.2),
        AppColors.secondaryColor.withValues(alpha: 0.2),
      ],
      stops: const [0.0, 0.8],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.width / 2,
      ))
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [AppColors.primaryColor, AppColors.secondaryColor],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    final waveHeight = 10.0;
    final waveLength = 100.0;
    final phase = animationValue * 2 * pi;

    path.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final y = waveHeight * sin((x / waveLength) * 2 * pi + phase);
      path.lineTo(x, size.height / 2 + y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(0);
    final paint = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final offset = Offset(x, y + sin(animationValue * 2 * pi) * 10);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FloatingParticlePainter extends CustomPainter {
  final double animationValue;

  FloatingParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = i * 40.0;
      final y = sin(animationValue * 2 * pi + i) * 10;
      canvas.drawCircle(Offset(x, size.height / 2 + y), 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
