import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/taibah_mark.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/signup_page.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

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

  signInUserNow() async {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            LoadingDialog(messageTxt: AppLocalizations.of(context)!.pleaseWait));

    try {
      final User? firebaseUser = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                  email: emailTextEditingController.text,
                  password: passwordTextEditingController.text))
          .user;

      if (firebaseUser != null) {
        DatabaseReference ref = FirebaseDatabase.instance
            .ref()
            .child("users")
            .child(firebaseUser.uid);
        await ref.once().then((dataSnapshot) {
          if (!mounted) return;
          if (dataSnapshot.snapshot.value != null) {
            if ((dataSnapshot.snapshot.value as Map)["blockStatus"] == "no") {
              userName = (dataSnapshot.snapshot.value as Map)["name"];
              userPhone = (dataSnapshot.snapshot.value as Map)["phone"];

              Navigator.push(
                  context, MaterialPageRoute(builder: (c) => const HomePage()));
              associateMethods.showSnackBarMsg(
                  AppLocalizations.of(context)!.loggedInSuccess, context);
            } else {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              associateMethods.showSnackBarMsg(
                  AppLocalizations.of(context)!.blockedMsg,
                  context);
            }
          } else {
            Navigator.pop(context);
            FirebaseAuth.instance.signOut();
            associateMethods.showSnackBarMsg(
                AppLocalizations.of(context)!.userNotFound, context);
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context);
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
