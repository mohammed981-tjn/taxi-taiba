import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/admin/admin_home.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/theme/taibah_logo.dart';

/// بوّابة اللوحة: دخول، ثم تحقّق من الراية.
///
/// **التحقّق هنا للعرض لا للحماية.** من يبني نسخة الإدارة بنفسه يستطيع حذف
/// هذا الفحص، وشاشات اللوحة ستُفتح له. وهذا مقبول لأنها لن **تُظهر** له شيئاً
/// ولن **تكتب** شيئاً: كل قراءة وكل كتابة في `database.rules.json` مشروطة
/// بـ`auth.token.admin === true`، والراية موقّعة من Firebase لا يزوّرها عميل.
///
/// فالفحص يمنع مستخدماً عادياً من رؤية شاشات فارغة ورسائل صلاحية، لا أكثر.
/// الحارس الحقيقي في القاعدة.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException {
      // لا تُفصّل: «البريد غير موجود» مقابل «كلمة المرور خاطئة» تخبر المهاجم
      // أيّ البريدين مسجَّل. رسالة واحدة للحالتين.
      setState(() => _error = 'تعذّر الدخول — راجع البريد وكلمة المرور.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// إعادة تعيين كلمة المرور — وهي **طريق الدخول الأولى** لا الاستثناء.
  ///
  /// لا تسجيل ذاتيّ في لوحة الإدارة: زرّ «أنشئ حساباً» هنا يعني أنّ من يملك
  /// الحزمة يصير مديراً، وهو ما تمنعه القاعدة لكنّه يفتح شاشاتٍ لا ينبغي أن
  /// تُفتح. فالحساب يُنشَأ من الخادم:
  ///
  ///   Actions ← Admin claim ← invite ← البريد
  ///
  /// ثم يضبط صاحبه كلمة مروره من هنا. وبهذا لا تُكتب كلمة مرور في مستودع ولا
  /// في سجلّ تشغيل ولا في محادثة — يعرفها صاحبها وحده، وهو الوضع الصحيح.
  Future<void> _resetPassword() async {
    if (_busy) return;

    final String email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'اكتب البريد أوّلاً.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _notice =
          'أُرسلت رسالة إلى $email.\nافتح الرابط فيها واضبط كلمة مرورك، '
          'ثم ادخل بها.');
    } on FirebaseAuthException {
      // كسابقتها: لا يُكشف أيّ بريد مسجَّل. والرسالة صحيحة في الحالتين — من
      // لا حساب له لن تصله رسالة، ولن يعرف السبب من هنا.
      if (!mounted) return;
      setState(() => _notice =
          'إن كان $email مسجَّلاً فستصلك رسالة إعادة تعيين.\nراجع بريدك — '
          'وتفقّد «الرسائل غير المرغوبة».');
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
          return const _Centered(child: CircularProgressIndicator());
        }

        final User? user = snapshot.data;
        if (user == null) return _buildSignIn();

        return _AdminClaimCheck(user: user);
      },
    );
  }

  Widget _buildSignIn() {
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
                const TaibahWordmark(role: AppRole.admin),
                const SizedBox(height: 30),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'البريد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const <String>[AutofillHints.password],
                  onSubmitted: (_) => _signIn(),
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
                if (_notice != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    _notice!,
                    style: const TextStyle(color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('دخول'),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// قراءة الراية من رمز الهويّة.
class _AdminClaimCheck extends StatelessWidget {
  const _AdminClaimCheck({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      // `true` يفرض تجديد الرمز. بدونه يبقى الرمز القديم — بلا راية — إلى
      // ساعة بعد المنح، فيبدو أن المنح لم يعمل وهو عامل.
      future: user.getIdTokenResult(true),
      builder: (BuildContext context, AsyncSnapshot<IdTokenResult> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Centered(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _Denied(
            title: 'تعذّر قراءة الصلاحية',
            detail: '${snapshot.error}',
          );
        }

        final bool isAdmin = snapshot.data?.claims?['admin'] == true;

        if (!isAdmin) {
          return _Denied(
            title: 'هذا الحساب ليس مديراً',
            detail: 'البريد: ${user.email ?? '—'}\n\n'
                'الحساب يُنشأ وتُمنح صفته من:\n'
                'Actions ← Admin claim ← invite ← البريد',
          );
        }

        return const AdminHome();
      },
    );
  }
}

class _Denied extends StatelessWidget {
  const _Denied({required this.title, required this.detail});

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
              const Icon(Icons.lock_outline, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(detail, textAlign: TextAlign.center),
              const SizedBox(height: 24),
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

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: child));
}
