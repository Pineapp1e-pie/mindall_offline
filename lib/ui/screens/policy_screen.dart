import 'dart:math';

import 'package:mindall_offline/ui/app_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/repositories/local_repository.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/subscription_service.dart';
import '../../domain/services/user_profile_service.dart';
import '../widgets/achievement_popup.dart';
import 'onboarding_screen.dart';
import 'cycle_setup_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        title: const Text(
          'Политика конфиденциальности',
          style: TextStyle(fontFamily: 'DotGothic', fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0E1511),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сбор и обработка данных',
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 18,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Приложение собирает ваш email, имя и пол для создания профиля. Эти данные хранятся в защищённой базе и используются исключительно для работы приложения (например, для персонализации контента).',
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Отказ от ответственности',
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 18,
                color: Colors.yellowAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Разработчик не несёт ответственности за:\n'
                  '• Ментальное и физическое здоровье\n'
                  '• Использование приложения в незаконных целях\n'
                  '• Ущерб, возникший из-за нарушения пользователем правил безопасности (передача пароля третьим лицам и т.п.)\n'
                  '• Содержимое, которое пользователь создаёт или загружает через приложение\n'
                  '• Сбои в работе, вызванные действиями третьих лиц или обстоятельствами непреодолимой силы',
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Права пользователя',
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 18,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Вы можете удалить свои данные в профиле.',
              style: const TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 200,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'Закрыть',
                      style: TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}