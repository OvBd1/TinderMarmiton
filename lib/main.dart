import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const TinderMarmitonApp());
}

class TinderMarmitonApp extends StatelessWidget {
  const TinderMarmitonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinder Marmiton',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Center(child: Text('Tinder Marmiton')),
      ),
    );
  }
}
