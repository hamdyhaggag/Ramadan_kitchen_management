import 'package:flutter/material.dart';

class MealDescription extends StatelessWidget {
  final String description;

  const MealDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.6,
          ),
    );
  }
}
