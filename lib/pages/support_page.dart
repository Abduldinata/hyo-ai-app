import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key, required this.danaNumber});

  final String danaNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support us'),
        foregroundColor: const Color(0xFFF35D9C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'DANA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF35D9C),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB7C5).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              danaNumber,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/support/qr.png',
                      width: 400,
                      height: 400,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan QR untuk donasi DANA',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B6460),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
