import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/driver/driver_service.dart';

/// ملفّ السائق ومركبته.
///
/// يُملأ مرّة واحدة بعد إنشاء الحساب. ولا يُسأل عن حالة الاعتماد: القاعدة
/// تفرض أن يبدأ الطلب `pending` — فالسائق لا يعتمد نفسه ولو عدّل الحزمة.
class DriverRegisterPage extends StatefulWidget {
  const DriverRegisterPage({super.key});

  @override
  State<DriverRegisterPage> createState() => _DriverRegisterPageState();
}

class _DriverRegisterPageState extends State<DriverRegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _color = TextEditingController();

  // الفئات الثلاث هي نفسها التي يعرفها منطق التسعير في
  // associate_methods.dart (×0.8 و×1.0 و×1.5) ولم تكن معروضة في أي شاشة.
  String _type = 'اقتصادي';
  static const List<String> _types = <String>['اقتصادي', 'عائلي', 'تنفيذي'];

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name,
      _phone,
      _model,
      _number,
      _color,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    final List<String> missing = <String>[
      if (_name.text.trim().length < 3) 'الاسم',
      if (_phone.text.trim().length < 7) 'الهاتف',
      if (_model.text.trim().isEmpty) 'نوع المركبة',
      if (_number.text.trim().isEmpty) 'رقم اللوحة',
    ];

    if (missing.isNotEmpty) {
      setState(() => _error = 'أكمل: ${missing.join('، ')}');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await DriverService.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        carModel: _model.text.trim(),
        carNumber: _number.text.trim(),
        carColor: _color.text.trim(),
        carType: _type,
      );
      // لا تنقّل من هنا: البوّابة تستمع إلى الملفّ، فتنتقل وحدها حين يُكتب.
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'تعذّر الحفظ: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل سائق'),
        actions: <Widget>[
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'بياناتك ومركبتك',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'تراجعها الإدارة قبل أن تستقبل أول رحلة.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _field(_name, 'الاسم الكامل'),
              _field(_phone, 'الهاتف', keyboard: TextInputType.phone),
              const Divider(height: 30),
              _field(_model, 'نوع المركبة — مثال: Toyota Corolla'),
              _field(_number, 'رقم اللوحة'),
              _field(_color, 'اللون'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                ),
                items: _types
                    .map((String t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (String? value) =>
                    setState(() => _type = value ?? _type),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
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
                      : const Text('إرسال الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
