import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/admin/admin_data.dart';

/// الرحلات — الجارية والمنتهية.
///
/// «الجارية» تعني ما لم يصل بعدُ إلى حالة نهائية. والتقسيم على الحالة لا على
/// الوقت لأنّ رحلة عالقة منذ ساعتين هي أهمّ ما على هذه الشاشة: لا تنتهي ولا
/// تُلغى، وراكبها ينتظر.
///
/// ملاحظة مسجَّلة في `dev-docs`: الإلغاء لا يُوسم في القاعدة اليوم —
/// `cancelRideRequest()` يعمل لكن لا يكتب `cancelled`. فما تراه هنا من إلغاء
/// أقلّ من الواقع، وهذا نقص في تطبيق الراكب لا في اللوحة.
class AdminTripsPage extends StatefulWidget {
  const AdminTripsPage({super.key});

  @override
  State<AdminTripsPage> createState() => _AdminTripsPageState();
}

class _AdminTripsPageState extends State<AdminTripsPage> {
  // التدفّق يُنشأ مرّةً واحدة.
  //
  // `AdminData.users` و`AdminData.trips` وأخواتها **دوالّ حصول**: كلّ نداء
  // يولّد كائن `Query` جديداً، و`Query.onValue` يعطي تدفّقاً جديداً معه. فالقيمة
  // التي يراها `StreamBuilder` لا تساوي نفسها بين بناءٍ وبناء، فيلغي الاشتراك
  // ويعيد إنشاءه مع كلّ إعادة رسم — ومع كلّ حرف يكتبه المشغّل في خانة البحث
  // تُفرَغ القائمة إلى دوّارة انتظار ثم يُعاد تحميل ثلاثمئة سجلّ.
  late final Stream<DatabaseEvent> _stream = AdminData.trips.onValue;

  static const Set<String> _finished = <String>{'ended', 'cancelled'};

  bool _showLive = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('جارية')),
              ButtonSegment<bool>(value: false, label: Text('الأرشيف')),
            ],
            selected: <bool>{_showLive},
            onSelectionChanged: (Set<bool> value) =>
                setState(() => _showLive = value.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<DatabaseEvent>(
            stream: _stream,
            builder:
                (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.hasError) {
                return _centered('تعذّرت القراءة.\n\n${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<MapEntry<String, Map<String, Object?>>> trips =
                  entriesOf(snapshot.data?.snapshot.value).where(
                (MapEntry<String, Map<String, Object?>> entry) {
                  final bool done = _finished
                      .contains(textOf(entry.value, 'status', fallback: ''));
                  return _showLive ? !done : done;
                },
              ).toList();

              if (trips.isEmpty) {
                return _centered(
                  _showLive ? 'لا رحلات جارية الآن' : 'الأرشيف فارغ',
                );
              }

              // الأحدث أولاً. مفاتيح push مرتّبة زمنياً بتصميمها، فالعكس يكفي
              // ولا حاجة إلى حقل وقت قد لا يكون مكتوباً.
              trips.sort((MapEntry<String, Map<String, Object?>> a,
                      MapEntry<String, Map<String, Object?>> b) =>
                  b.key.compareTo(a.key));

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) => _TripCard(
                  tripId: trips[index].key,
                  fields: trips[index].value,
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.tripId, required this.fields});

  final String tripId;
  final Map<String, Object?> fields;

  static const Map<String, String> _statusText = <String, String>{
    'new': 'جديدة',
    'accepted': 'قُبلت',
    'arrived': 'وصل السائق',
    'ontrip': 'جارية',
    'ended': 'انتهت',
    'cancelled': 'أُلغيت',
  };

  @override
  Widget build(BuildContext context) {
    final String status = textOf(fields, 'status', fallback: 'new');

    final Object? pickUp = fields['pickUpAddress'];
    final Object? dropOff = fields['dropOffAddress'];

    final double fare = numberOf(fields, 'fareAmount');
    final Object? rating = fields['rating'];

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
                    _statusText[status] ?? status,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (fare > 0)
                  Text(
                    fare.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _Line(icon: Icons.trip_origin, text: '${pickUp ?? '—'}'),
            _Line(icon: Icons.location_on_outlined, text: '${dropOff ?? '—'}'),
            const SizedBox(height: 8),
            Text(
              'الراكب: ${textOf(fields, 'userName')}'
              '   ·   السائق: ${textOf(fields, 'driverName')}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (rating is num)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '$rating',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                tripId,
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
