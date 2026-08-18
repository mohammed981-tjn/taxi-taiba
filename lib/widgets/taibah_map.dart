import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/market.dart';

/// خريطة واحدة للتطبيقات الثلاثة.
///
/// وأهمّ ما فيها ليس الخريطة بل الحالة التي **بلا** خريطة.
///
/// مفتاح الخرائط يُحقن عند البناء ولا يُخزَّن في المستودع. وحين يغيب، لا يفشل
/// البناء ولا يعتذر Google: تُرسم مساحة رماديّة فارغة وتبقى. وهذا أسوأ أشكال
/// العطل — يبدو خطأً في الشيفرة أو في الشبكة أو في الجهاز، ويُبحث عنه في كل
/// مكان إلا مكانه. وقد وقع هنا فعلاً: بُنيت أربعون نسخة و`API_KEY` فيها سلسلة
/// فارغة، ولم يقل ذلك أحد.
///
/// فإن غاب المفتاح تقول الشاشة ما الذي غاب وأين يُضبط. سطرٌ يُقرأ أهون من
/// يومٍ يُبحث فيه.
class TaibahMap extends StatelessWidget {
  const TaibahMap({
    super.key,
    this.initial,
    this.markers = const <Marker>{},
    this.onMapCreated,
    this.myLocation = false,
    this.padding = EdgeInsets.zero,
  });

  /// موضع الكاميرا الأول — ومركز السوق حين لا يُمرَّر.
  final CameraPosition? initial;

  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;

  /// النقطة الزرقاء وزرّ «موقعي». تحتاج إذن الموقع، فلا تُرفع إلا حيث طُلب.
  final bool myLocation;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (googleMapKey.isEmpty) return const _MapKeyMissing();

    return GoogleMap(
      initialCameraPosition: initial ?? market.camera,
      markers: markers,
      onMapCreated: onMapCreated,
      myLocationEnabled: myLocation,
      myLocationButtonEnabled: myLocation,
      padding: padding,
      mapType: MapType.normal,
      // إيماءات الميل والدوران تُربك أكثر مما تفيد في شاشة يُنظر إليها لحظةً
      // أثناء القيادة.
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

class _MapKeyMissing extends StatelessWidget {
  const _MapKeyMissing();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.map_outlined,
                size: 52,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 14),
              Text(
                'الخريطة معطّلة في هذا البناء',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'لا مفتاح خرائط. يُضبط مرّةً واحدة في:\n'
                'GitHub ← Settings ← Secrets ← Actions\n'
                'باسم MAPS_API_KEY، ثم يُعاد البناء.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
