import 'package:flutter/material.dart';

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tests Page',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
