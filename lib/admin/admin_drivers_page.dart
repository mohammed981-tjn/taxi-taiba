import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/admin/admin_data.dart';

/// اعتماد السائقين وحظرهم.
///
/// وهذه الشاشة ليست عرضاً: `approvalStatus` مربوط بقاعدة تمنع أيّ سائق غير
/// معتمَد من الكتابة في `onlineDrivers`. أي أنّ السائق الذي لا تعتمده هنا لا
/// يظهر لراكب أبداً — لا لأن التطبيق يخفيه، بل لأن القاعدة ترفض إدراجه.
///
/// بلا هذه الشاشة، من ينزّل تطبيق السائق يوم يجهز يصير سائقاً في الخدمة
/// فوراً. فهي أول ما تحتاجه خدمة نقل حقيقية، لا آخره.
class AdminDriversPage extends StatelessWidget {
  const AdminDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: AdminData.drivers.onValue,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.error_outline,
            title: 'تعذّرت القراءة',
            detail: 'غالباً أن الراية غير ممنوحة لهذا الحساب.\n\n'
                '${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<MapEntry<String, Map<String, Object?>>> drivers =
            entriesOf(snapshot.data?.snapshot.value);

        if (drivers.isEmpty) {
          return const _Message(
            icon: Icons.local_taxi_outlined,
            title: 'لا سائقين',
            detail: 'شغّل Actions ← Test accounts ← seed لإنشاء سائقي تجربة.',
          );
        }

        // المعلَّقون أولاً: ما ينتظر قراراً يجب أن يُرى قبل ما لا ينتظر.
        drivers.sort((MapEntry<String, Map<String, Object?>> a,
            MapEntry<String, Map<String, Object?>> b) {
          int rank(Map<String, Object?> f) {
            switch (textOf(f, 'approvalStatus', fallback: 'pending')) {
              case 'pending':
                return 0;
              case 'suspended':
                return 1;
              default:
                return 2;
            }
          }

          final int byRank = rank(a.value).compareTo(rank(b.value));
          if (byRank != 0) return byRank;
          return textOf(a.value, 'name').compareTo(textOf(b.value, 'name'));
        });

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: drivers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) => _DriverCard(
            uid: drivers[index].key,
            fields: drivers[index].value,
          ),
        );
      },
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.uid, required this.fields});

  final String uid;
  final Map<String, Object?> fields;

  @override
  Widget build(BuildContext context) {
    final String approval =
        textOf(fields, 'approvalStatus', fallback: 'pending');
    final bool blocked = textOf(fields, 'blockStatus', fallback: 'no') == 'yes';

    final Object? car = fields['car_details'];
    final String carText = car is Map
        ? <String>[
            '${car['model'] ?? ''}',
            '${car['number'] ?? ''}',
            '${car['color'] ?? ''}',
          ].where((String s) => s.trim().isNotEmpty).join(' · ')
        : '—';

    final Object? ratings = fields['ratings'];
    final String ratingText = ratings is Map && (ratings['count'] as num? ?? 0) > 0
        ? '${ratings['average']} (${ratings['count']})'
        : 'بلا تقييم';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    textOf(fields, 'name'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(approval: approval, blocked: blocked),
              ],
            ),
            const SizedBox(height: 6),
            Text('${textOf(fields, 'phone')} · ${textOf(fields, 'email')}'),
            Text(carText),
            const SizedBox(height: 4),
            Text(
              'الأرباح: ${numberOf(fields, 'earnings').toStringAsFixed(0)}'
              '   ·   التقييم: $ratingText',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Divider(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (approval != 'approved')
                  FilledButton.icon(
                    onPressed: () => _setApproval(context, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('اعتماد'),
                  ),
                if (approval == 'approved')
                  OutlinedButton.icon(
                    onPressed: () => _setApproval(context, 'suspended'),
                    icon: const Icon(Icons.pause, size: 18),
                    label: const Text('إيقاف'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _setBlocked(context, !blocked),
                  icon: Icon(blocked ? Icons.lock_open : Icons.block, size: 18),
                  label: Text(blocked ? 'رفع الحظر' : 'حظر'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setApproval(BuildContext context, String value) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await AdminData.driver(uid).update(<String, Object?>{
        'approvalStatus': value,
      });

      // الإيقاف لا يكتمل بتغيير حقل: السائق الموقوف قد يكون معروضاً على
      // خرائط الركّاب الآن. القاعدة تمنعه من العودة، وهذا السطر يُخرجه فوراً.
      if (value != 'approved') {
        await AdminData.onlineDriver(uid).remove();
      }

      messenger.showSnackBar(
        SnackBar(content: Text(value == 'approved' ? 'اعتُمد' : 'أُوقف')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('فشل: $error')));
    }
  }

  Future<void> _setBlocked(BuildContext context, bool blocked) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await AdminData.driver(uid).update(<String, Object?>{
        'blockStatus': blocked ? 'yes' : 'no',
      });

      if (blocked) await AdminData.onlineDriver(uid).remove();

      messenger.showSnackBar(
        SnackBar(content: Text(blocked ? 'حُظر' : 'رُفع الحظر')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('فشل: $error')));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.approval, required this.blocked});

  final String approval;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (blocked) {
      label = 'محظور';
      color = Colors.red;
    } else {
      switch (approval) {
        case 'approved':
          label = 'معتمَد';
          color = Colors.green;
          break;
        case 'suspended':
          label = 'موقوف';
          color = Colors.orange;
          break;
        default:
          label = 'بانتظار الاعتماد';
          color = Colors.blueGrey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: Colors.black38),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
