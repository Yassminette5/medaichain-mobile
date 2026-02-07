import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String centerName;

  const HomePage({
    super.key,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hello',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
            ),
            const SizedBox(height: 16),
            if (centerName.isNotEmpty)
              Text(
                centerName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
