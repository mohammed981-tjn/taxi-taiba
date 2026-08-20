import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/currency.dart';
import 'package:flutter_projects/widgets/app_skeletons.dart';
import 'package:flutter_projects/driver/driver_service.dart';

/// الأرباح — **مشتقّة من الرحلات، لا مقروءة من عدّاد**.
///
/// وهذا قرار أمني لا أسلوب برمجة. الشيفرة الأصلية كانت تجمع في
/// `drivers/$uid/earnings` من تطبيق **الراكب** — حيث `currentUser.uid` هو
/// الراكب لا السائق، فكان كل راكب يكتب في سجلّ أرباح مفتاحه معرّفه هو. ولو
/// نُقلت تلك الجمعة إلى هنا لصار السائق يكتب أرباح نفسه، وهو أوضح إغراءً.
///
/// فالقاعدة تجمّد الحقل على الطرفين، وهذه الشاشة تجمع من `tripRequests`:
/// رقمٌ يُشتقّ لا يكذب إلا إذا كذبت الرحلات، ويقابله ما يراه المدير في لوحته
/// من المصدر نفسه.
///
/// والاستعلام `orderByChild('driverID').equalTo(uid)` ليس اختياراً: القاعدة
/// لا تسمح بقراءة `tripRequests` إلا بهذا الشكل بالضبط. فالسائق لا يقدر على
/// تنزيل جدول الرحلات ليصفّيه بنفسه، ولا على رؤية رحلة ليست له.
class DriverEarningsPage extends StatelessWidget {
  const DriverEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرباحي')),
      body: StreamBuilder<DatabaseEvent>(
        stream: DriverService.myTrips.onValue,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return _centered('تعذّرت القراءة.\n\n${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TripCardSkeleton();
          }

          final Object? raw = snapshot.data?.snapshot.value;
          if (raw is! Map) return _centered('لا رحلات بعد.');

          final List<MapEntry<String, Map<String, Object?>>> trips =
              <MapEntry<String, Map<String, Object?>>>[];

          raw.forEach((Object? key, Object? value) {
            if (key is! String || value is! Map) return;
            final Map<String, Object?> fields = <String, Object?>{};
            value.forEach((Object? k, Object? v) {
              if (k is String) fields[k] = v;
            });
            trips.add(MapEntry<String, Map<String, Object?>>(key, fields));
          });

          final List<MapEntry<String, Map<String, Object?>>> ended = trips
              .where((MapEntry<String, Map<String, Object?>> e) =>
                  '${e.value['status']}' == 'ended')
              .toList()
            ..sort((MapEntry<String, Map<String, Object?>> a,
                    MapEntry<String, Map<String, Object?>> b) =>
                b.key.compareTo(a.key));

          double collected = 0;
          double commission = 0;
          for (final MapEntry<String, Map<String, Object?>> e in ended) {
            collected += _fareOf(e.value);
            commission += _feeOf(e.value);
          }
          final double net = collected - commission;

          if (ended.isEmpty) return _centered('لا رحلات منتهية بعد.');

          // `ListView.builder` لا `ListView(children: [...])`.
          //
          // الثانية تبني كلّ عنصر في القائمة دفعةً واحدة — كلّ رحلة في مهنة
          // السائق — سواء رآها أم لا. والأولى تبني ما يظهر على الشاشة وحده.
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ended.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: <Widget>[
                      // العنوان يقول ما يُعرَض فعلاً.
                      //
                      // الاستعلام مقيَّد بآخر خمسين رحلة، فتسميته «إجمالي
                      // الأرباح» تجعل الرقم كاذباً على سائق أتمّ أكثر منها —
                      // وأسوأ من رقمٍ ناقص رقمٌ ناقصٌ يُقدَّم كاملاً.
                      const Text('أرباح آخر الرحلات',
                          style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),

                      // **الصافي هو الرقم الكبير، لا المحصَّل.**
                      //
                      // الراكب يدفع الأجرة وعمولة المنصّة معاً، والعمولة ليست
                      // للسائق. فعرضُ المحصَّل رقماً كبيراً يجعل السائق يبني
                      // دخله على مبلغٍ يزيد خمسة ريالات عن كلّ رحلة أتمّها —
                      // ويكتشف الفرق يوم المحاسبة لا يوم العمل.
                      Text(
                        money(net.toStringAsFixed(1)),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'من ${ended.length} رحلة منتهية',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                      if (commission > 0) ...<Widget>[
                        const Divider(height: 26),
                        _Row(label: 'المحصَّل من الركّاب', value: collected),
                        const SizedBox(height: 4),
                        _Row(label: 'عمولة المنصّة (مخصومة)', value: commission),
                      ],
                    ],
                  ),
                ),
              );
              }

              final MapEntry<String, Map<String, Object?>> e =
                  ended[index - 1];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                  title: Text('${e.value['dropOffAddress'] ?? '—'}'),
                  subtitle: Text('${e.value['userName'] ?? '—'}'),
                  trailing: Text(
                    money((_fareOf(e.value) - _feeOf(e.value))
                        .toStringAsFixed(1)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// `fareAmount` نصّ في القاعدة لا رقم — كتبه القالب هكذا، وتغييره الآن يعني
  /// صفوفاً قديمة لا تُقرأ. فيُقبل الشكلان.
  /// عمولة المنصّة على هذه الرحلة.
  ///
  /// تُقرأ من تفصيل الرحلة لا من ثابتٍ في الشيفرة: رحلةٌ أُتمّت قبل أن تُفرض
  /// العمولة لا عمولة عليها، وتطبيق ثابت اليوم عليها يخصم من سائقٍ خمسةً لم
  /// يدفعها راكبه قطّ. وأيّ تغييرٍ للعمولة لاحقاً لا يعيد كتابة الماضي.
  double _feeOf(Map<String, Object?> trip) {
    final Object? breakdown = trip['fareBreakdown'];
    if (breakdown is! Map) return 0;
    return double.tryParse('${breakdown['fee']}') ?? 0;
  }

  double _fareOf(Map<String, Object?> trip) {
    final Object? value = trip['fareAmount'];
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
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

/// سطر «عنوان ← مبلغ» في بطاقة الإجمالي.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        Text(
          money(value.toStringAsFixed(1)),
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }
}
