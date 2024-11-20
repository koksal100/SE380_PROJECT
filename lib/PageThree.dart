import 'package:flutter/material.dart';

class PageThree extends StatelessWidget {
  const PageThree({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Statistics Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
