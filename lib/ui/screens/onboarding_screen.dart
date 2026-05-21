import '../../domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:mindall_offline/ui/app_route.dart';
import 'package:mindall_offline/ui/screens/policy_screen.dart';
import 'package:mindall_offline/ui/screens/main_nav_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _accentGreen = Color(0xFF83F483);
const _accentYellow = Color(0xFFFFEB89);
const _accentPurple = Color(0xFF9B7BFF);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0: welcome, 1: имя, 2: пол
  final TextEditingController _nameController = TextEditingController();
  Gender? _gender;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndProceed() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Введите имя');
        return;
      }
      setState(() {
        _error = null;
        _step = 2;
      });
      return;
    }
    if (_step == 2) {
      if (_gender == null) {
        setState(() => _error = 'Выберите пол');
        return;
      }
      // Сохраняем данные локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _nameController.text.trim());
      await prefs.setString('user_gender', _gender!.name);
      // Переход на главный экран
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AppRoute(page: const MainNavScaffold()),
              (_) => false,
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _step = 0;
      _nameController.clear();
      _gender = null;
      _error = null;
    });
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              // Заголовок в зависимости от шага
              if (_step == 0)
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Добро\n'),
                      TextSpan(
                        text: 'пожаловать!',
                        style: TextStyle(color: _accentGreen),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              else if (_step == 1)
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Как тебя\n'),
                      TextSpan(
                        text: 'зовут?',
                        style: TextStyle(color: _accentYellow),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'DotGothic',
                      fontSize: 32,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Твой\n'),
                      TextSpan(
                        text: 'пол',
                        style: TextStyle(color: _accentPurple),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 48),

              // Описание (только на шаге Welcome)
              if (_step == 0) ...[
                const Text(
                  'SafeRoom — личный дневник настроения, '
                      'основанный на циркумплексной модели эмоций Рассела.\n\n'
                      'Все эмоции располагаются в двумерном пространстве: '
                      'от негативных к позитивным и от спокойных к активным. '
                      'Это помогает точнее фиксировать эмоциональное состояние '
                      'и замечать изменения настроения со временем.\n\n'
                      'Вы можете отмечать эмоции, добавлять контекст, '
                      'заметки и отслеживать связь между настроением, '
                      'сном, активностью, погодой и другими факторами.\n\n'
                      'Все данные хранятся локально только на вашем устройстве '
                      'и не передаются в облачные сервисы.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 80),
              ],

              // Поле ввода имени (шаг 1)
              if (_step == 1) ...[
                _PixelField(
                  controller: _nameController,
                  hint: 'твоё имя',
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: 24),
              ],

              // Выбор пола (шаг 2)
              if (_step == 2) ...[
                const Text(
                  'ПОЛ',
                  style: TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 11,
                    color: Colors.white38,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GenderButton(
                      label: 'женщина',
                      selected: _gender == Gender.female,
                      accent: _accentPurple,
                      onTap: () => setState(() => _gender = Gender.female),
                    ),
                    const SizedBox(width: 8),
                    _GenderButton(
                      label: 'мужчина',
                      selected: _gender == Gender.male,
                      accent: _accentGreen,
                      onTap: () => setState(() => _gender = Gender.male),
                    ),
                    const SizedBox(width: 8),
                    _GenderButton(
                      label: '—',
                      selected: _gender == Gender.preferNotToSay,
                      accent: Colors.white,
                      onTap: () => setState(() => _gender = Gender.preferNotToSay),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Сообщение об ошибке
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 20),

              // Кнопка "Далее" / "Начать"
              GestureDetector(
                onTap: _saveAndProceed,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _step == 2 ? 'начать' : 'далее',
                      style: const TextStyle(
                        fontFamily: 'DotGothic',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Политика конфиденциальности (на всех шагах, но в конце)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                  children: [
                    const TextSpan(text: 'Нажимая «далее», ты соглашаешься с '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _showPrivacyPolicy,
                        child: Text(
                          'политикой конфиденциальности',
                          style: TextStyle(
                            color: _accentYellow,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}


class _PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType keyboardType;
  final List<String>? autofillHints;

  const _PixelField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(
        fontFamily: 'DotGothic',
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'DotGothic',
          color: Colors.white54,
          fontSize: 16,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? accent : Colors.white24),
          color: selected ? accent.withOpacity(0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 13,
            color: selected ? accent : Colors.white38,
          ),
        ),
      ),
    );
  }
}


