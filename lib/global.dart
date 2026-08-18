import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_projects/methods/associate_methods.dart';

/// Shared state for the passenger app.
///
/// This file was removed in "Upload clean passenger app without secrets",
/// which took the Maps key out of the repository — and every global beside it.
/// Seven files import it, so the whole project stopped compiling: 67 analyzer
/// errors, almost all of them a symbol that used to live here. It is rebuilt
/// from those call sites.
///
/// The key is the one thing not restored as a literal. It now comes from the
/// build, so the repository keeps none:
///
///   flutter build apk --release --dart-define=MAPS_API_KEY=AIza...
///
/// Left unset, the app builds and runs; the map tiles and the geocoding and
/// directions calls are what fail, and they fail visibly rather than silently.

/// Read at compile time — empty when the define is absent.
const String googleMapKey = String.fromEnvironment('MAPS_API_KEY');

/// البلدان التي يبحث فيها الإكمال التلقائي — رموز ISO مفصولة بـ`|`.
///
/// كانت `NG` مكتوبةً في عنوان الطلب مباشرةً: نيجيريا، بلد القالب الأصلي. وأثر
/// ذلك أنّ الراكب يكتب اسم حيّه فلا تظهر نتيجة واحدة — لا رسالة خطأ ولا سبب،
/// فيبدو عطلاً في الشبكة وهو قيدٌ في سطر. وهو أخطر شكل يتّخذه افتراض قالب:
/// لا يفشل البناء، ولا يفشل الطلب — يعود فارغاً وينجح.
///
/// والافتراض السعودية — **مصرَّحاً به هذه المرّة لا مستنتَجاً**. كان `SD`
/// استنتاجاً من سياق مشروع آخر، وهو خطأٌ من الشكل نفسه الذي أصلحناه: لا
/// يفشل بناءٌ ولا طلب، ويعود الإكمال التلقائي فارغاً لكل راكب في الرياض.
///
/// وتقبل Places حتى خمسة بلدان:
///
///   --dart-define=PLACES_COUNTRIES=SA
///   --dart-define=PLACES_COUNTRIES=SA|SD
const String placesCountries = String.fromEnvironment(
  'PLACES_COUNTRIES',
  defaultValue: 'SA',
);

/// `SA|SD` ← ما يُكتب، `country:sa|country:sd` ← ما تفهمه Places.
String get placesComponents => placesCountries
    .split('|')
    .map((String code) => code.trim().toLowerCase())
    .where((String code) => code.isNotEmpty)
    .map((String code) => 'country:$code')
    .join('|');

/// Where the map sits for the instant before the user's location arrives.
/// Every path that shows the map immediately animates away from it.
///
/// كانت إحداثيات مقرّ Google في كاليفورنيا — قيمة `flutter create` الافتراضية
/// التي لم يمسّها أحد. لا تُرى طويلاً، لكنها تُرى: ومضة خريطة لمدينة بعيدة
/// قبل أن يصل الموقع.
///
/// والمدينة المنوّرة هي الافتراض: السوق الأول السعودية، و«طيبة» اسمُها الذي
/// عُرفت به. غيّرها إن كان الإطلاق في مدينة أخرى — ومضةٌ خاطئة لثانية أهون
/// من غيرها، لكنها تبقى خطأً.
const CameraPosition kGooglePlex = CameraPosition(
  target: LatLng(24.4686, 39.6142),
  zoom: 14.4746,
);

final AssociateMethods associateMethods = AssociateMethods();

/* ── the signed-in passenger ─────────────────────────────────────────────── */

String userName = '';
String userPhone = '';

/* ── the driver on the current trip ──────────────────────────────────────── */

String nameDriver = '';
String phoneNumberDriver = '';
String carDetailsDriver = '';

/// Server-side trip state: "accepted", "arrived", "ontrip", "ended".
String status = '';

/// The same state as the passenger reads it, already localised.
String tripStatusDisplay = '';

/// Seconds a driver is given to answer before the request moves on. Counted
/// down in home_page and reset to this value each time a new driver is asked.
int requestTimeoutDriver = 20;
