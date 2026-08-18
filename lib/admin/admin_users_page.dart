import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/admin/admin_data.dart';

/// المستخدمون وحظرهم.
///
/// الحقل `blockStatus` كان موجوداً في القاعدة منذ اليوم الأول، ويقرأه تطبيق
/// الراكب عند الإقلاع ويغلق الشاشة عليه — ولم تكن هناك أيّ واجهة لضبطه. أي
/// أنّ الحظر كان مبنيّاً نصفه ومعطّلاً كلّه.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            onChanged: (String value) =>
                setState(() => _search = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'بحث بالاسم أو الهاتف أو البريد',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: AdminData.users.onValue,
            builder:
                (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.hasError) {
                return _centered(
                  'تعذّرت القراءة — غالباً أن الراية غير ممنوحة.\n\n'
                  '${snapshot.error}',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<MapEntry<String, Map<String, Object?>>> users =
                  entriesOf(snapshot.data?.snapshot.value);

              if (_search.isNotEmpty) {
                users = users.where(
                  (MapEntry<String, Map<String, Object?>> entry) {
                    final Map<String, Object?> f = entry.value;
                    return <String>['name', 'phone', 'email']
                        .map((String k) => textOf(f, k).toLowerCase())
                        .any((String v) => v.contains(_search));
                  },
                ).toList();
              }

              if (users.isEmpty) {
                return _centered(
                  _search.isEmpty ? 'لا مستخدمين' : 'لا نتيجة للبحث',
                );
              }

              // المحظورون أولاً — هم من يحتاج نظرك.
              users.sort((MapEntry<String, Map<String, Object?>> a,
                  MapEntry<String, Map<String, Object?>> b) {
                final bool ba = textOf(a.value, 'blockStatus') == 'yes';
                final bool bb = textOf(b.value, 'blockStatus') == 'yes';
                if (ba != bb) return ba ? -1 : 1;
                return textOf(a.value, 'name').compareTo(textOf(b.value, 'name'));
              });

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) => _UserTile(
                  uid: users[index].key,
                  fields: users[index].value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _centered(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.uid, required this.fields});

  final String uid;
  final Map<String, Object?> fields;

  @override
  Widget build(BuildContext context) {
    final bool blocked = textOf(fields, 'blockStatus', fallback: 'no') == 'yes';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: blocked ? Colors.red.shade50 : null,
          child: Icon(
            blocked ? Icons.block : Icons.person_outline,
            color: blocked ? Colors.red : null,
          ),
        ),
        title: Text(textOf(fields, 'name')),
        subtitle: Text(
          '${textOf(fields, 'phone')}\n${textOf(fields, 'email')}',
        ),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: () => _confirm(context, blocked),
          child: Text(
            blocked ? 'رفع الحظر' : 'حظر',
            style: TextStyle(color: blocked ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, bool blocked) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    // الحظر يقطع الخدمة عن شخص. تأكيدٌ واحد أرخص من اعتذار.
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(blocked ? 'رفع الحظر؟' : 'حظر المستخدم؟'),
        content: Text(
          blocked
              ? 'سيعود ${textOf(fields, 'name')} إلى استخدام التطبيق.'
              : 'لن يستطيع ${textOf(fields, 'name')} فتح التطبيق بعد الآن.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await AdminData.user(uid).update(<String, Object?>{
        'blockStatus': blocked ? 'no' : 'yes',
      });

      messenger.showSnackBar(
        SnackBar(content: Text(blocked ? 'رُفع الحظر' : 'حُظر')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('فشل: $error')));
    }
  }
}
