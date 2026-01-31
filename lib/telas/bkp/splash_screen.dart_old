import 'package:flutter/material.dart';
import 'crm_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmScreen()),
        );
      },
      child: Scaffold(
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/tela_inicial.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
