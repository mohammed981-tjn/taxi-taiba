import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/taibah_logo.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/signin_page.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/pages/home_page.dart';
import 'package:flutter_projects/widgets/loading_dialog.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

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

  signUpUserNow() async
  {
    showDialog(
        context: context,
        builder: (BuildContext context) => LoadingDialog(messageTxt: AppLocalizations.of(context)!.pleaseWait)
    );

    try {
      final User? firebaseUser = (
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailTextEditingController.text.trim(),
            password: passwordTextEditingController.text.trim()
          )
      ).user;

      Map userDataMap = {
        "name": userNameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": userPhoneTextEditingController.text.trim(),
        "id": firebaseUser!.uid,
        "blockStatus": "no",
      };
      FirebaseDatabase.instance.ref().child("users").child(firebaseUser.uid).set(userDataMap);

      if (!mounted) return;
      Navigator.pop(context);
      associateMethods.showSnackBarMsg(AppLocalizations.of(context)!.accountCreatedSuccess, context);
      Navigator.push(context, MaterialPageRoute(builder: (c)=> const HomePage()));
    }
    on FirebaseAuthException catch(e) {
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
                child: const TaibahWordmark(
                  role: AppRole.passenger,
                  onDark: true,
                  logoSize: 68,
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
