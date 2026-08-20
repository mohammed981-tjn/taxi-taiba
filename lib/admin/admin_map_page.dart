import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_projects/admin/admin_data.dart';
import 'package:flutter_projects/widgets/taibah_map.dart';

/// أين سائقوك الآن.
///
/// قائمة السائقين تقول من اعتمدته، ولا تقول أين هم. والفرق عمليّ: مدينةٌ فيها
/// عشرة سائقين مجتمعين في حيّ واحد وعشرة موزّعين ليست الحالة نفسها، وواحدةٌ
/// منهما تُخدَم والأخرى لا. هذا ما تُريه الخريطة ولا تُريه القائمة.
///
/// وتقرأ `onlineDrivers` مباشرةً لا `drivers`: الأولى تُمحى تلقائياً حين ينقطع
/// السائق (`onDisconnect`)، فما تراه هنا متّصلٌ الآن لا «كان متّصلاً».
class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  TaibahMapController? _controller;

  // التدفّقان يُنشآن مرّةً واحدة — راجع التعليق في admin_users_page.dart.
  // وهنا الأثر أشدّ: كلّ نبضة موقع من أيّ سائق كانت تعيد بناء الشجرة، فيتبدّل
  // التدفّقان، فيُلغى الاشتراكان ويُعاد إنشاؤهما — عشرات المرّات في الدقيقة.
  final Stream<DatabaseEvent> _onlineStream =
      FirebaseDatabase.instance.ref('onlineDrivers').onValue;
  late final Stream<DatabaseEvent> _profilesStream = AdminData.drivers.onValue;

  /// يُرفع بعد أوّل ضبط للكاميرا، فلا تقفز الخريطة كلّما تحرّك سائق.
  bool _framed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: _onlineStream,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> online) {
        // أسماء السائقين ولوحاتهم من العقدة الأخرى: `onlineDrivers` تحمل
        // الموضع وحده عمداً — تُكتب مع كل عشرين متراً، فكلّ حقل فيها يُدفع
        // ثمنه مرّات في الدقيقة.
        return StreamBuilder<DatabaseEvent>(
          stream: _profilesStream,
          builder:
              (BuildContext context, AsyncSnapshot<DatabaseEvent> profiles) {
            final Map<String, Map<String, Object?>> byUid =
                <String, Map<String, Object?>>{
              for (final MapEntry<String, Map<String, Object?>> e
                  in entriesOf(profiles.data?.snapshot.value))
                e.key: e.value,
            };

            final Set<Marker> markers = <Marker>{};
            final List<LatLng> points = <LatLng>[];

            final Object? raw = online.data?.snapshot.value;
            if (raw is Map) {
              raw.forEach((Object? key, Object? value) {
                if (key is! String) return;

                final LatLng? at = driverLatLngFrom(value);
                if (at == null) return;

                final Map<String, Object?> profile =
                    byUid[key] ?? const <String, Object?>{};

                final Object? car = profile['car_details'];
                final String plate =
                    car is Map ? '${car['number'] ?? ''}'.trim() : '';

                markers.add(
                  Marker(
                    markerId: MarkerId(key),
                    position: at,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                    infoWindow: InfoWindow(
                      title: textOf(profile, 'name', fallback: 'سائق'),
                      snippet: plate.isEmpty
                          ? textOf(profile, 'phone', fallback: '')
                          : '$plate · ${textOf(profile, 'phone', fallback: '')}',
                    ),
                  ),
                );
                points.add(at);
              });
            }

            _frame(points);

            return Stack(
              children: <Widget>[
                TaibahMap(
                  markers: markers,
                  onReady: (TaibahMapController c) {
                    _controller = c;
                    _frame(points);
                  },
                  padding: const EdgeInsets.only(top: 64),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _Count(
                    loading: !online.hasData,
                    count: markers.length,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ضبطُ الكاميرا مرّةً على أوّل دفعة تصل.
  ///
  /// ولو أُعيد مع كل تحديث لصارت الخريطة تقفز كلّما تحرّك سائق — والمشغّل الذي
  /// يقرّب على حيّ يجده يعود إلى المدينة كلّها كلّ عشرين متراً.
  void _frame(List<LatLng> points) {
    if (_framed || _controller == null || points.isEmpty) return;
    _framed = true;

    if (points.length == 1) {
      _controller!.moveTo(points.first, 14);
      return;
    }

    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final LatLng p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    _controller!.fitBounds(
      LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      ),
      64,
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.loading, required this.count});

  final bool loading;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 3,
      child: ListTile(
        dense: true,
        leading: Icon(
          count == 0 ? Icons.wifi_off : Icons.wifi_tethering,
          color: count == 0 ? theme.colorScheme.outline : Colors.green,
        ),
        title: Text(
          loading
              ? 'جارٍ القراءة…'
              : count == 0
                  ? 'لا سائق متّصل الآن'
                  : '$count سائقاً متّصلاً',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: count == 0 && !loading
            ? const Text('الخريطة تُحدَّث وحدها لحظة اتصال أوّلهم.')
            : null,
      ),
    );
  }
}
