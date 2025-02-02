import 'package:flutter/material.dart';

class MealTitle extends StatelessWidget {
  final String title;

  const MealTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.grey[900],
          ),
    );
  }
}
