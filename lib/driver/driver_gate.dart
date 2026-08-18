import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/driver/driver_home.dart';
import 'package:flutter_projects/driver/driver_register_page.dart';
import 'package:flutter_projects/driver/driver_service.dart';

/// دخول السائق، ثم الحالة.
///
/// السائق يمرّ بأربع حالات لا اثنتين، وخلطها هو ما يجعل التطبيق يبدو معطّلاً:
///
///   غير مسجَّل دخول   →  شاشة دخول
///   دخل ولا ملفّ له   →  شاشة تسجيل سائق
///   ملفّه معلَّق        →  شاشة انتظار — وهي ليست خطأً
///   معتمَد            →  الشاشة الرئيسة
///
/// الحالة الثالثة هي المهمّة: سائقٌ يرى «بانتظار الاعتماد» يعرف أنّ عليه
/// الانتظار. وسائقٌ يرى شاشة فارغة يظنّ التطبيق خرباً ويحذفه.
class DriverGate extends StatefulWidget {
  const DriverGate({super.key});

  @override
  State<DriverGate> createState() => _DriverGateState();
}

class _DriverGateState extends State<DriverGate> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  bool _registering = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_registering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _error = error.code == 'weak-password'
            ? 'كلمة المرور قصيرة — ثمانية محارف فأكثر.'
            : error.code == 'email-already-in-use'
                ? 'هذا البريد مسجَّل — ادخل بدل أن تسجّل.'
                : 'تعذّر — راجع البريد وكلمة المرور.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) return _buildAuth();

        return const _DriverProfileCheck();
      },
    );
  }

  Widget _buildAuth() {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(Icons.drive_eta_outlined, size: 64),
                const SizedBox(height: 14),
                const Text(
                  'طيبة — السائق',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 26),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_registering ? 'إنشاء حساب' : 'دخول'),
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _registering = !_registering;
                            _error = null;
                          }),
                  child: Text(
                    _registering ? 'لديّ حساب — دخول' : 'سائق جديد؟ أنشئ حساباً',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// الملفّ وحالة اعتماده.
class _DriverProfileCheck extends StatelessWidget {
  const _DriverProfileCheck();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: DriverService.me.onValue,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final Object? value = snapshot.data?.snapshot.value;

        if (value is! Map) return const DriverRegisterPage();

        final String approval =
            '${value['approvalStatus'] ?? 'pending'}';
        final bool blocked = '${value['blockStatus'] ?? 'no'}' == 'yes';

        if (blocked) {
          return const _Waiting(
            icon: Icons.block,
            color: Colors.red,
            title: 'حسابك محظور',
            detail: 'تواصل مع الإدارة.',
          );
        }

        if (approval == 'pending') {
          return const _Waiting(
            icon: Icons.hourglass_top,
            color: Colors.blueGrey,
            title: 'بانتظار الاعتماد',
            detail: 'وصل طلبك. لن تستقبل رحلات قبل أن تعتمده الإدارة —\n'
                'وهذه الشاشة تتغيّر وحدها لحظة اعتماده.',
          );
        }

        if (approval == 'suspended') {
          return const _Waiting(
            icon: Icons.pause_circle_outline,
            color: Colors.orange,
            title: 'حسابك موقوف',
            detail: 'أوقفته الإدارة مؤقتاً. تواصل معها لمعرفة السبب.',
          );
        }

        return DriverHome(profile: Map<String, Object?>.from(value));
      },
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 26),
              OutlinedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('خروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
