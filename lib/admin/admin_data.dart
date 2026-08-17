import 'package:firebase_database/firebase_database.dart';

/// قراءات اللوحة، في مكان واحد.
///
/// السبب في تجميعها أنّ كل شاشة هنا تقرأ عقدة كاملة، وهذا هو النمط نفسه الذي
/// كلّفنا في تطبيق الراكب. الفرق أنّ اللوحة مقبول فيها: مشغّل واحد على شاشة
/// واحدة، لا آلاف الهواتف. لكن القبول له حدّ، ولذلك `limitToLast` أدناه ليست
/// زينة — عقدة تكبر بلا حدّ تُنزَّل بلا حدّ.
class AdminData {
  const AdminData._();

  static DatabaseReference get _root => FirebaseDatabase.instance.ref();

  /// سقفٌ يمنع اللوحة من تنزيل قاعدة كاملة يوم تكبر.
  static const int pageSize = 300;

  static Query get drivers => _root.child('drivers').limitToLast(pageSize);

  static Query get users => _root.child('users').limitToLast(pageSize);

  /// مرتّبة بالحالة كي يعمل الفهرس المنشور `.indexOn: ["status"]`.
  static Query get trips =>
      _root.child('tripRequests').limitToLast(pageSize);

  static DatabaseReference driver(String uid) =>
      _root.child('drivers').child(uid);

  static DatabaseReference user(String uid) => _root.child('users').child(uid);

  static DatabaseReference onlineDriver(String uid) =>
      _root.child('onlineDrivers').child(uid);
}

/// تحويل ما تعيده القاعدة إلى قائمة مرتّبة.
///
/// القاعدة تعيد `Map<Object?, Object?>`، والقيم المتداخلة كذلك. تمريرها كما
/// هي إلى الواجهة يعني `as Map` في كل سطر — وأول قيمة غير متوقّعة تُسقط
/// الشاشة. فالتحويل هنا مرّة واحدة، ودفاعياً.
List<MapEntry<String, Map<String, Object?>>> entriesOf(Object? raw) {
  if (raw is! Map) return <MapEntry<String, Map<String, Object?>>>[];

  final List<MapEntry<String, Map<String, Object?>>> out =
      <MapEntry<String, Map<String, Object?>>>[];

  raw.forEach((Object? key, Object? value) {
    if (key is! String) return;
    if (value is! Map) return;

    final Map<String, Object?> fields = <String, Object?>{};
    value.forEach((Object? k, Object? v) {
      if (k is String) fields[k] = v;
    });

    out.add(MapEntry<String, Map<String, Object?>>(key, fields));
  });

  return out;
}

String textOf(Map<String, Object?> fields, String key, {String fallback = '—'}) {
  final Object? value = fields[key];
  if (value == null) return fallback;
  final String text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double numberOf(Map<String, Object?> fields, String key) {
  final Object? value = fields[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
