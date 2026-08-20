import 'package:flutter/material.dart';
// ببادئة صريحة: المكتبتان تصدّران `Marker` و`LatLngBounds` بالاسم نفسه،
// فبلا بادئة يرفض المترجم الملفّ كلّه.
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/market.dart';

/// خريطة واحدة للتطبيقات الثلاثة — بمحرّكين.
///
/// حين يوجد `MAPS_API_KEY` تُرسم بخرائط Google. وحين يغيب تُرسم ببلاطات
/// OpenStreetMap عبر `flutter_map` — وهو نهج zadgo2 — فتعمل الشاشة بدل أن
/// تعتذر.
///
/// **ولماذا محرّكان لا محرّك؟** لأنّ التحويل الكامل ليس بديلاً بل هجرةً
/// مزدوجة: تدفع ثمنها مرّةً للذهاب ومرّةً للعودة. والمفتاح قادم، فالصواب جسرٌ
/// يُعبَر ويُزال، لا بيتٌ يُبنى ثم يُهدم. والاختيار هنا شرطٌ واحد يُقرأ عند
/// البناء، فلحظة وصول المفتاح تعود Google بلا تعديل سطر.
///
/// **وحدٌّ يجب أن يُقال بوضوح:** مخدّم بلاطات OpenStreetMap العامّ مخدّمُ
/// تبرّعات، وسياسته تمنع الاستهلاك الثقيل من تطبيقٍ موزَّع. فهذا الفرع صالحٌ
/// للتطوير والتجربة على أجهزة معدودة، **ولا يُطلق به إلى ركّاب حقيقيّين**.
/// إمّا أن يصل مفتاح Google قبل الإطلاق، أو يُشترى مزوّد بلاطات مرخَّص.
/// ورخصة ODbL تُلزم بالإسناد، وهو مرسومٌ في الزاوية ولا يُزال.
class TaibahMap extends StatefulWidget {
  const TaibahMap({
    super.key,
    this.initial,
    this.markers = const <Marker>{},
    this.onReady,
    this.myLocation = false,
    this.padding = EdgeInsets.zero,
  });

  /// موضع الكاميرا الأوّل — ومركز السوق حين لا يُمرَّر.
  final CameraPosition? initial;

  /// العلامات بنوع Google — يبقى النوع المشترك بين المحرّكين فلا تتغيّر
  /// مواضع الاستدعاء حين يتبدّل المحرّك.
  final Set<Marker> markers;

  /// يُسلّم متحكّماً محايداً للمحرّكين.
  final void Function(TaibahMapController)? onReady;

  final bool myLocation;
  final EdgeInsets padding;

  @override
  State<TaibahMap> createState() => _TaibahMapState();
}

/// متحكّمٌ محايد — يخفي أيّ محرّك يعمل تحته.
///
/// مواضع الاستدعاء تريد شيئين لا غير: انتقل إلى نقطة، وأطّر مجموعة نقاط.
/// فلا داعي لأن تعرف أيّهما يرسم.
class TaibahMapController {
  TaibahMapController._(this._google, this._osm);

  final GoogleMapController? _google;
  final fm.MapController? _osm;

  Future<void> moveTo(LatLng target, double zoom) async {
    await _google?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
    _osm?.move(ll.LatLng(target.latitude, target.longitude), zoom);
  }

  Future<void> fitBounds(LatLngBounds bounds, double padding) async {
    await _google?.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));

    _osm?.fitCamera(
      fm.CameraFit.bounds(
        bounds: fm.LatLngBounds(
          ll.LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
          ll.LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
        ),
        padding: EdgeInsets.all(padding),
      ),
    );
  }

  void dispose() {
    _google?.dispose();
    _osm?.dispose();
  }
}

class _TaibahMapState extends State<TaibahMap> {
  final fm.MapController _osmController = fm.MapController();

  /// هل نملك مفتاحاً؟ يُقرأ عند البناء ولا يتغيّر أثناء التشغيل.
  static bool get _hasGoogleKey => googleMapKey.isNotEmpty;

  @override
  void dispose() {
    _osmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition start = widget.initial ?? market.camera;

    if (_hasGoogleKey) {
      return GoogleMap(
        initialCameraPosition: start,
        markers: widget.markers,
        onMapCreated: (GoogleMapController c) =>
            widget.onReady?.call(TaibahMapController._(c, null)),
        myLocationEnabled: widget.myLocation,
        myLocationButtonEnabled: widget.myLocation,
        padding: widget.padding,
        mapType: MapType.normal,
        // إيماءات الميل والدوران تُربك أكثر مما تفيد في شاشة يُنظر إليها
        // لحظةً أثناء القيادة.
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        zoomControlsEnabled: false,
      );
    }

    return Stack(
      children: <Widget>[
        fm.FlutterMap(
          mapController: _osmController,
          options: fm.MapOptions(
            initialCenter: ll.LatLng(start.target.latitude, start.target.longitude),
            initialZoom: start.zoom,
            interactionOptions: const fm.InteractionOptions(
              // نفس القرار: بلا ميلٍ ولا دوران.
              flags: fm.InteractiveFlag.drag |
                  fm.InteractiveFlag.pinchZoom |
                  fm.InteractiveFlag.doubleTapZoom,
            ),
            onMapReady: () =>
                widget.onReady?.call(TaibahMapController._(null, _osmController)),
          ),
          children: <Widget>[
            fm.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // مطلوبٌ في سياسة الاستعمال: مخدّم البلاطات يحقّ له أن يعرف من
              // يطلب، ويحجب ما لا يعرّف نفسه.
              userAgentPackageName: 'com.rididago.com',
              maxZoom: 19,
            ),
            fm.MarkerLayer(
              markers: widget.markers.map(_toOsmMarker).toList(),
            ),
          ],
        ),

        // الإسناد — شرطٌ في رخصة ODbL لا زينة، ولا يُزال.
        Positioned(
          bottom: widget.padding.bottom + 2,
          left: 4,
          child: const _Attribution(),
        ),

        // ولافتةٌ صريحة: هذه ليست الحالة النهائيّة.
        Positioned(
          top: widget.padding.top + 8,
          left: 12,
          right: 12,
          child: const _InterimBanner(),
        ),
      ],
    );
  }

  /// علامة Google → علامة flutter_map.
  ///
  /// الأخيرة لا تعرف أيقونات ولا نوافذ معلومات، فتُرسم دبّوساً ملوّناً بلون
  /// درجة العلامة الأصليّة — فيبقى الأخضر أخضر والأحمر أحمر.
  static fm.Marker _toOsmMarker(Marker m) {
    return fm.Marker(
      point: ll.LatLng(m.position.latitude, m.position.longitude),
      width: 34,
      height: 34,
      child: const Icon(Icons.location_on, size: 34, color: Color(0xFF0E7C5A)),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          child: Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 9.5, color: Colors.black87),
          ),
        ),
      );
}

class _InterimBanner extends StatelessWidget {
  const _InterimBanner();

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.amber.shade100,
        margin: EdgeInsets.zero,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            'خريطة مؤقّتة للتجربة — تعود خرائط Google تلقائياً عند ضبط '
            'MAPS_API_KEY.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.5),
          ),
        ),
      );
}

/// موضع سائق كما يُكتب في `onlineDrivers/$uid`.
///
/// الشكل المكتوب `{'g': geohash, 'l': [lat, lng]}`. لكنّ `l` تعود أحياناً
/// خريطةً `{0: lat, 1: lng}` لا قائمة: Firebase يحوّل المصفوفة إلى كائن حين
/// تكون مفاتيحها متفرّقة، ويعيدها كما خزّنها. قراءتها كقائمة وحدها تُسقط
/// السائق صامتاً — فيبدو غير متصل وهو متصل.
LatLng? driverLatLngFrom(Object? value) {
  if (value is! Map) return null;

  final Object? raw = value['l'];

  double? lat;
  double? lng;

  if (raw is List && raw.length >= 2) {
    lat = _asDouble(raw[0]);
    lng = _asDouble(raw[1]);
  } else if (raw is Map) {
    lat = _asDouble(raw[0] ?? raw['0']);
    lng = _asDouble(raw[1] ?? raw['1']);
  }

  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;

  return LatLng(lat, lng);
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
