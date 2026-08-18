import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    nameController.text = userName;
    phoneController.text = userPhone;
    emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
  }

  updateProfile() async {
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    Map<String, Object?> userDataMap = {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
    };

    await userRef.update(userDataMap);

    setState(() {
      userName = nameController.text.trim();
      userPhone = phoneController.text.trim();
      isEditing = false;
    });

    if (!mounted) return;
    associateMethods.showSnackBarMsg(
        AppLocalizations.of(context)!.accountCreatedSuccess, context); // Reuse success message
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: TibaPalette.passenger.primary,
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
            icon: Icon(isEditing ? Icons.close : Icons.edit, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage("assets/avatar.webp"),
              backgroundColor: Colors.blue,
            ),
            const SizedBox(height: 30),
            buildInfoField(l10n.name, nameController, Icons.person, isEditing),
            const SizedBox(height: 20),
            buildInfoField(l10n.phone, phoneController, Icons.phone, isEditing),
            const SizedBox(height: 20),
            buildInfoField(l10n.email, emailController, Icons.email, false), // Email not editable
            const SizedBox(height: 40),
            if (isEditing)
              ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TibaPalette.passenger.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  l10n.saveButton,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoField(String label, TextEditingController controller, IconData icon, bool enabled) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: TibaPalette.passenger.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
