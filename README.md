# flutter_projects

OAGO Mobile APp

> **مرحلة تجريبية.** هذا المستودع مأخوذ عن تطبيق ركّاب جاهز ويُدرس ويُبنى عليه.
> سجلّ ما أُنجز وما بقي في [`dev-docs/notes-ar.md`](dev-docs/notes-ar.md).

## ⚠️ خطوة مؤجَّلة: التطبيق موصول بـFirebase مالكه الأصلي

```
lib/main.dart:23              databaseURL: ".../rdidago-default-rtdb.firebaseio.com"
android/app/google-services.json   project_id: rdidago
```

كل تسجيل مستخدم وكل طلب رحلة وكل إحداثيّة سائق تُكتب في مشروع لا نملكه. مقبول
أثناء التجربة، **وغير مقبول قبل أي استخدام حقيقي** — لأن مالك المشروع يقرأ
البيانات، وإغلاقه يوقف التطبيق في اللحظة نفسها، ولا لوحة تحكّم لدينا.

الخطوات كاملة في [`dev-docs/notes-ar.md`](dev-docs/notes-ar.md#️-الخطوة-المؤجَّلة-الأهم-الهجرة-من-firebase-المالك-الأصلي).

## البناء

كل دفعة على فرع تنتج APK عبر GitHub Actions — التبويب **Actions ← Artifacts**.

```bash
flutter build apk --release --split-per-abi \
  --dart-define=MAPS_API_KEY=AIza... \
  -Pmaps.api.key=AIza...
```

بلا مفاتيح يبني ويعمل: الخريطة فارغة ولا إشعار يُرسل، وكلاهما يُسجَّل في السجل
بدل أن يفشل بصمت.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
