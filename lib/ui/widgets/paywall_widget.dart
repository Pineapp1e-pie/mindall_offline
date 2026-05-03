import 'package:flutter/material.dart';

import '../app_route.dart';
import '../screens/profile_screen.dart';

class PaywallWidget extends StatelessWidget {
  final Color accentColor;

  const PaywallWidget({super.key, this.accentColor = const Color(0xFFFFEB89)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF18221C),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Эта функция доступна только в Premium',
            style: TextStyle(
              fontFamily: 'DotGothic',
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(AppRoute(page: const ProfileScreen()));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: accentColor,
              child: const Text(
                'Перейти на Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DotGothic',
                  color: Color(0xFF0E1511),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
