import 'package:mindall/ui/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Заполни все поля');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'Пароль минимум 6 символов');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: newPass))
          .timeout(const Duration(seconds: 5));
      TextInput.finishAutofillContext(shouldSave: true);

      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          AppRoute(page: const AuthScreen()),
          (_) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль обновлён — войди заново')),
        );
      }
    } catch (_) {
      setState(() => _error = 'Проверьте подключение к интернету или VPN');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1511),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Новый пароль',
          style: TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 16),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            const Text(
              'Придумай\nновый пароль',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DotGothic',
                fontSize: 28,
                color: Colors.white,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            AutofillGroup(
              child: Column(
                children: [
                  _field(_newCtrl, 'новый пароль', AutofillHints.newPassword),
                  const SizedBox(height: 16),
                  _field(_confirmCtrl, 'повтори пароль', AutofillHints.newPassword),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'DotGothic',
                  color: Color(0xFFFF6B6B),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'сохранить',
                          style: TextStyle(
                            fontFamily: 'DotGothic',
                            fontSize: 16,
                            color: Colors.black,
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

  Widget _field(TextEditingController ctrl, String hint, String autofillHint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      autofillHints: [autofillHint],
      style: const TextStyle(fontFamily: 'DotGothic', color: Colors.white, fontSize: 16),
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
