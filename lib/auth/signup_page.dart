import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/taibah_mark.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/signin_page.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/pages/home_page.dart';
import 'package:flutter_projects/widgets/loading_dialog.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.popOnSuccess = false});

  /// راجع `SigninPage.popOnSuccess`.
  final bool popOnSuccess;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
{
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateSignUpForm() {
    if (userNameTextEditingController.text.trim().length < 3) {
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.nameTooShort, context);
    }
    else if (userPhoneTextEditingController.text.trim().length < 7) {
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.phoneTooShort, context);
    }
    else if (!emailTextEditingController.text.contains("@")) {
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.invalidEmail, context);
    }
    else if (passwordTextEditingController.text.trim().length < 8) {
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.passwordTooShort, context);
    }
    else {
      signUpUserNow();
    }
  }

  /// ينشئ الحساب — ويربطه بجلسة الضيف حين توجد.
  ///
  /// **لماذا الربط لا الإنشاء المجرّد.** من فتح التطبيق ضيفاً يحمل جلسةً
  /// مجهولة بمعرّفٍ قائم. و`createUserWithEmailAndPassword` تُنشئ معرّفاً
  /// **ثانياً** وتترك الأوّل يتيماً في قائمة المستخدمين. و`linkWithCredential`
  /// تُلبس الجلسة نفسها بريداً وكلمة سرّ: المعرّف واحد، ولا يُخلَّف شيء.
  ///
  /// وإن لم تكن هناك جلسة ضيف — لأنّ مزوّد Anonymous غير مفعّل مثلاً —
  /// فالمسار القديم كما هو.
  Future<User?> _createAccount(String email, String password) async {
    final User? guest = FirebaseAuth.instance.currentUser;

    if (guest != null && guest.isAnonymous) {
      final UserCredential linked = await guest.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return linked.user;
    }

    final UserCredential created =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return created.user;
  }

  signUpUserNow() async
  {
    bool waitOpen = true;
    void closeWait() {
      if (!waitOpen || !mounted) return;
      waitOpen = false;
      Navigator.pop(context);
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(messageTxt: AppLocalizations.of(context)!.pleaseWait)
    );

    try {
      final User? firebaseUser = await _createAccount(
        emailTextEditingController.text.trim(),
        passwordTextEditingController.text.trim(),
      );

      if (firebaseUser == null) {
        if (!mounted) return;
        closeWait();
        return;
      }

      userName = userNameTextEditingController.text.trim();
      userPhone = userPhoneTextEditingController.text.trim();

      Map userDataMap = {
        "name": userName,
        "email": emailTextEditingController.text.trim(),
        "phone": userPhone,
        "id": firebaseUser.uid,
        "blockStatus": "no",
      };
      // يُنتظر: الشاشة التالية تقرأ هذا السجلّ فوراً، وبلا انتظارٍ قد تصل
      // القراءة قبل الكتابة فيبدو الحساب الجديد غير موجود.
      await FirebaseDatabase.instance.ref().child("users").child(firebaseUser.uid).set(userDataMap);

      if (!mounted) return;
      closeWait();
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.accountCreatedSuccess, context);

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
    on FirebaseAuthException catch(e) {
      if (!mounted) return;
      closeWait();
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
              // ترويسة العلامة بدل صورة القالب — راجع signin_page.dart.
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
                AppLocalizations.of(context)!.rideWithUs,
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
                          labelStyle: const TextStyle(fontSize: 14)
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22,),
                    TextField(
                      controller: userNameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.name,
                          labelStyle: const TextStyle(fontSize: 14)
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22,),
                    TextField(
                      controller: userPhoneTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.phone,
                          labelStyle: const TextStyle(fontSize: 14)
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22,),
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
                    const SizedBox(height: 32,),
                    ElevatedButton(
                      onPressed: () {
                        validateSignUpForm();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10)
                      ),
                      child: Text(AppLocalizations.of(context)!.signUp, style: const TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12,),

              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> const SigninPage()));
                },
                child: Text(
                  AppLocalizations.of(context)!.alreadyHaveAccount,
                  style: const TextStyle(
                    color: Colors.grey,
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
