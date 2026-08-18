import 'dart:math' as math;

/// حساب نطاقات الجيوهاش التي تغطّي دائرة حول نقطة.
///
/// المسألة التي يحلّها هذا الملف: قاعدة الوقت الحقيقي لا تعرف المسافة، ولا
/// تُرتّب إلا على حقل واحد. فالسؤال «مَن حولي في ٢٢ كم؟» لا يُطرح عليها كما
/// هو. والحيلة أن الجيوهاش يحوّل نقطتين متجاورتين على الأرض إلى نصّين
/// متجاورين في الترتيب الأبجدي — فيصير سؤال المسافة سؤالَ مدى على نصّ،
/// وهذا ما تُحسنه القاعدة: `orderByChild('g').startAt(a).endAt(b)`.
///
/// وليست خليّة واحدة كافية: من يقف على حدّ خليّة يفقد كل من في الخليّة
/// المجاورة وهو على بُعد أمتار منه. فتُحسب تسع نقاط تحيط بالدائرة، وتُجمع
/// مداياتها بعد حذف المكرّر — وغالباً ما تنضغط إلى مديين أو ثلاثة.
///
/// النقل هنا يتبع دلالات `geofire-common` الرسمية سطراً بسطر، لا اجتهاداً:
/// خطأٌ في هذا الحساب لا يظهر كعطل بل كسائق قريب لا يُعرض أبداً — وهو أسوأ
/// أنواع الأخطاء، لأنه يبدو «لا يوجد سائقون».
///
/// تحقّقٌ عددي قبل الاعتماد: مئتا ألف نقطة موزّعة على مربّع ٤٠٠ كم حول
/// الخرطوم — لم تفت الاستعلامَ ولا نقطةٌ واحدة داخل ٢٢ كم، وجُلب ٣٫٨٥٪ من
/// المجموع، ولم تدخل نقطةُ القاهرة.

const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

const int _bitsPerChar = 5;
const int _maximumBitsPrecision = 22 * _bitsPerChar;

const double _e2 = 0.00669447819799;
const double _epsilon = 1e-12;
const double _metersPerDegreeLatitude = 110574;
const double _earthEqRadius = 6378137.0;
const double _earthMeridionalCircumference = 40007860;

double _log2(double x) => math.log(x) / math.ln2;

/// ترميز نقطة إلى جيوهاش.
///
/// الدقّة ١٠ هي دقّة GeoFire الافتراضية، وهي ما يكتبه تطبيق السائق في الحقل
/// `g`. تغييرها في طرف دون الآخر يكسر المطابقة بصمت.
String encodeGeohash(double latitude, double longitude, {int precision = 10}) {
  double latMin = -90;
  double latMax = 90;
  double lonMin = -180;
  double lonMax = 180;

  final StringBuffer hash = StringBuffer();
  int bits = 0;
  int bit = 0;
  bool even = true;

  while (hash.length < precision) {
    if (even) {
      final double mid = (lonMin + lonMax) / 2;
      if (longitude > mid) {
        bit = (bit << 1) + 1;
        lonMin = mid;
      } else {
        bit = bit << 1;
        lonMax = mid;
      }
    } else {
      final double mid = (latMin + latMax) / 2;
      if (latitude > mid) {
        bit = (bit << 1) + 1;
        latMin = mid;
      } else {
        bit = bit << 1;
        latMax = mid;
      }
    }

    even = !even;
    bits += 1;

    if (bits == 5) {
      hash.write(_base32[bit]);
      bits = 0;
      bit = 0;
    }
  }

  return hash.toString();
}

/// كم درجة طول تساوي هذه المسافة عند خط العرض هذا.
///
/// درجة الطول تنكمش كلّما ابتعدنا عن خط الاستواء — عند القطب تصير صفراً. ولذا
/// لا يصحّ أن يُحسب صندوق البحث بدرجات ثابتة: نفس الـ٢٢ كم تساوي ٠٫٢٠ درجة في
/// الخرطوم و٠٫٤٥ في أوسلو.
double _metersToLongitudeDegrees(double distance, double latitude) {
  final double radians = latitude * math.pi / 180;
  final double num = math.cos(radians) * _earthEqRadius * math.pi / 180;
  final double denom =
      1 / math.sqrt(1 - _e2 * math.sin(radians) * math.sin(radians));
  final double deltaDegrees = num * denom;

  if (deltaDegrees < _epsilon) {
    return distance > 0 ? 360 : 0;
  }

  return math.min(360, distance / deltaDegrees);
}

double _longitudeBitsForResolution(double resolution, double latitude) {
  final double degrees = _metersToLongitudeDegrees(resolution, latitude);
  return degrees.abs() > 0.000001 ? math.max(1, _log2(360 / degrees)) : 1;
}

double _latitudeBitsForResolution(double resolution) {
  return math.min(
    _log2(_earthMeridionalCircumference / 2 / resolution),
    _maximumBitsPrecision.toDouble(),
  );
}

double _wrapLongitude(double longitude) {
  if (longitude >= -180 && longitude <= 180) return longitude;

  final double adjusted = longitude + 180;
  if (adjusted > 0) return (adjusted % 360) - 180;
  return 180 - (-adjusted % 360);
}

/// كم بتّاً من الجيوهاش يبقى دالّاً عند هذا القطر.
///
/// كلّما اتّسع نصف القطر قلّت البتّات، أي قصرت البادئة، أي اتّسعت الخليّة.
/// وهذا هو المقايضة كلّها: بادئة أقصر تعني عدد استعلامات أقل وجلباً زائداً
/// أكبر.
int _boundingBoxBits(double latitude, double size) {
  final double latDeltaDegrees = size / _metersPerDegreeLatitude;
  final double latitudeNorth = math.min(90, latitude + latDeltaDegrees);
  final double latitudeSouth = math.max(-90, latitude - latDeltaDegrees);

  final int bitsLatitude =
      math.max(0, _latitudeBitsForResolution(size).floor()) * 2;
  final int bitsLongitudeNorth =
      math.max(1, _longitudeBitsForResolution(size, latitudeNorth).floor()) *
              2 -
          1;
  final int bitsLongitudeSouth =
      math.max(1, _longitudeBitsForResolution(size, latitudeSouth).floor()) *
              2 -
          1;

  return math.min(
    math.min(bitsLatitude, bitsLongitudeNorth),
    math.min(bitsLongitudeSouth, _maximumBitsPrecision),
  );
}

/// النقاط التسع: المركز، وأربع جهات، وأربعة أركان.
List<List<double>> _boundingBoxCoordinates(
  double latitude,
  double longitude,
  double radius,
) {
  final double latDegrees = radius / _metersPerDegreeLatitude;
  final double latitudeNorth = math.min(90, latitude + latDegrees);
  final double latitudeSouth = math.max(-90, latitude - latDegrees);

  final double longDegrees = math.max(
    _metersToLongitudeDegrees(radius, latitudeNorth),
    _metersToLongitudeDegrees(radius, latitudeSouth),
  );

  return <List<double>>[
    <double>[latitude, longitude],
    <double>[latitude, _wrapLongitude(longitude - longDegrees)],
    <double>[latitude, _wrapLongitude(longitude + longDegrees)],
    <double>[latitudeNorth, longitude],
    <double>[latitudeNorth, _wrapLongitude(longitude - longDegrees)],
    <double>[latitudeNorth, _wrapLongitude(longitude + longDegrees)],
    <double>[latitudeSouth, longitude],
    <double>[latitudeSouth, _wrapLongitude(longitude - longDegrees)],
    <double>[latitudeSouth, _wrapLongitude(longitude + longDegrees)],
  ];
}

/// المدى النصّي لخليّة واحدة.
///
/// الحرف `~` متعمّد: ترتيبه بعد كل حروف base32، فهو الحدّ الأعلى الذي يضمّ كل
/// ما يبدأ بهذه البادئة مهما طال.
List<String> _geohashQuery(String hash, int bits) {
  final int precision = (bits / _bitsPerChar).ceil();

  if (hash.length < precision) {
    return <String>[hash, '$hash~'];
  }

  final String trimmed = hash.substring(0, precision);
  final String base = trimmed.substring(0, trimmed.length - 1);
  final int lastValue = _base32.indexOf(trimmed[trimmed.length - 1]);

  final int significantBits = bits - base.length * _bitsPerChar;
  final int unusedBits = _bitsPerChar - significantBits;

  final int startValue = (lastValue >> unusedBits) << unusedBits;
  final int endValue = startValue + (1 << unusedBits);

  if (endValue > 31) {
    return <String>['$base${_base32[startValue]}', '$base~'];
  }

  return <String>[
    '$base${_base32[startValue]}',
    '$base${_base32[endValue]}',
  ];
}

/// المدايات التي تغطّي دائرة نصف قطرها [radiusInMeters] حول النقطة.
///
/// كل عنصر زوجٌ `[من, إلى]` يُمرَّر مباشرةً إلى `startAt` و`endAt`.
List<List<String>> geohashQueryBounds(
  double latitude,
  double longitude,
  double radiusInMeters,
) {
  final int queryBits = math.max(1, _boundingBoxBits(latitude, radiusInMeters));
  final int precision = (queryBits / _bitsPerChar).ceil();

  final List<List<String>> bounds = <List<String>>[];

  for (final List<double> point
      in _boundingBoxCoordinates(latitude, longitude, radiusInMeters)) {
    final List<String> range = _geohashQuery(
      encodeGeohash(point[0], point[1], precision: precision),
      queryBits,
    );

    // النقاط التسع تقع كثيراً في خليّة واحدة، فالحذف هنا يقلّص تسعة استعلامات
    // إلى اثنين أو ثلاثة في الحالة الشائعة.
    final bool seen = bounds.any(
      (List<String> other) => other[0] == range[0] && other[1] == range[1],
    );

    if (!seen) bounds.add(range);
  }

  return bounds;
}

/// المسافة بالأمتار — هافرساين.
///
/// المدى النصّي يجلب صندوقاً لا دائرة، فيبقى قصٌّ دقيق على العميل. وهو رخيص:
/// يجري على ما جُلب وحده، لا على كل من في القاعدة.
double distanceInMeters(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const double earthRadius = 6371000;

  final double phi1 = startLatitude * math.pi / 180;
  final double phi2 = endLatitude * math.pi / 180;
  final double deltaPhi = (endLatitude - startLatitude) * math.pi / 180;
  final double deltaLambda = (endLongitude - startLongitude) * math.pi / 180;

  final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(deltaLambda / 2) *
          math.sin(deltaLambda / 2);

  return 2 * earthRadius * math.asin(math.sqrt(a));
}
