import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/taibah_mark.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/guest_session.dart';
import 'package:flutter_projects/auth/signup_page.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key, this.popOnSuccess = false});

  /// `true` حين تُفتح هذه الشاشة من داخل التطبيق — من بوّابة الضيف أو من زرّ
  /// الركن — فتعود بعد النجاح إلى ما كان يفعله المستخدم بدل أن تبني شاشةً
  /// رئيسيّةً ثانية فوق الأولى.
  final bool popOnSuccess;

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateSignInForm() {
    if (!emailTextEditingController.text.contains("@")) {
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.invalidEmail, context);
    } else {
      signInUserNow();
    }
  }

  /// يُغلق حوار الانتظار مرّةً واحدة.
  ///
  /// كان مسار النجاح لا يغلقه أصلاً: يدفع الشاشة الرئيسيّة **فوقه**، فيبقى
  /// الحوار في المكدّس، ورجعةٌ واحدة تُظهر «الرجاء الانتظار» على شاشةٍ لا
  /// تنتظر شيئاً.
  bool _waitOpen = false;

  void _closeWait() {
    if (!_waitOpen || !mounted) return;
    _waitOpen = false;
    Navigator.pop(context);
  }

  /// بعد الدخول: إمّا العودة إلى ما كان يفعله المستخدم، وإمّا بناء الشاشة
  /// الرئيسيّة **بديلاً** لا فوق الشاشات السابقة — فزرّ الرجوع لا يعيده إلى
  /// شاشة دخولٍ سجّل منها للتوّ.
  void _leaveAfterSuccess() {
    if (widget.popOnSuccess) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  signInUserNow() async {
    _waitOpen = true;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) =>
            LoadingDialog(messageTxt: AppLocalizations.of(context)!.pleaseWait));

    try {
      final User? firebaseUser = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                  email: emailTextEditingController.text.trim(),
                  password: passwordTextEditingController.text))
          .user;

      if (firebaseUser != null) {
        DatabaseReference ref = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(firebaseUser.uid);
        await ref.once().then((dataSnapshot) {
          if (!mounted) return;
          _closeWait();
          if (dataSnapshot.snapshot.value != null) {
            if ((dataSnapshot.snapshot.value as Map)["blockStatus"] == "no") {
              userName = (dataSnapshot.snapshot.value as Map)["name"] ?? '';
              userPhone = (dataSnapshot.snapshot.value as Map)["phone"] ?? '';

              associateMethods.showSnackBarMsg(
                  AppLocalizations.of(context)!.loggedInSuccess, context);
              _leaveAfterSuccess();
            } else {
              GuestSession.dropToGuest();
              associateMethods.showSnackBarMsg(
                  AppLocalizations.of(context)!.blockedMsg,
                  context);
            }
          } else {
            GuestSession.dropToGuest();
            associateMethods.showSnackBarMsg(
                AppLocalizations.of(context)!.userNotFound, context);
          }
        });
      } else {
        _closeWait();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _closeWait();
      associateMethods.showSnackBarMsg(e.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // ترويسة العلامة بدل صورة القالب.
              //
              // كانت `assets/signin.jpg` تملأ ٤٠٪ من الشاشة بصورة مخزون لا تخصّ
              // المشروع — وهي أوضح ما يبقى من القالب في وجه المستخدم. وبدلها
              // العلامة نفسها على تدرّج هويّة النكهة: أصغر وزناً، ويتلوّن مع
              // كل نكهة بلا صورة ثانية.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      TaibahPalette.passenger.primary,
                      TaibahPalette.passenger.primaryDeep,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: const TaibahMark(
                  role: AppRole.passenger,
                  onDark: true,
                  size: 54,
                ),
              ),
              const SizedBox(height: 26),

              Text(
                AppLocalizations.of(context)!.loginToAccount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: TaibahPalette.passenger.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          labelStyle: const TextStyle(fontSize: 14)),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.password,
                        labelStyle: const TextStyle(fontSize: 14),
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        validateSignInForm();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 10)),
                      child: Text(
                        AppLocalizations.of(context)!.login,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const SignUpPage()));
                },
                child: Text(
                  AppLocalizations.of(context)!.dontHaveAccount,
                  style: const TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

      ),
    );
  }
}
