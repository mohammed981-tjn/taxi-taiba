import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// شريط «لا يوجد اتصال» — يلتفّ حول التطبيق كلّه من `MaterialApp.builder`.
///
/// منقول من zadgo2 (`lib/widgets/connectivity_banner.dart`).
///
/// بدونه لا يوجد في هذا التطبيق أيّ معالجة لانقطاع الشبكة إطلاقاً. راكبٌ في
/// قبو مواقف يضغط «اطلب رحلة» فتتعلّق الكتابة ويبقى ينظر إلى دوّارة لا تنتهي.
/// والسائق أسوأ: شاشاته مستمعو قاعدة صرف، فعند الانقطاع تتجمّد الواجهة على
/// آخر إطار وتبدو حيّةً تماماً — لا فرق بين «لا طلبات» و«لا شبكة».
///
/// **والنصّ معامَل لا ثابت.** الأصل يقرأ الترجمة داخل الودجت، ولو نُقل كذلك
/// لكان عطلاً أسوأ ممّا يعالج: `AppLocalizations` مسجَّل في تطبيق الراكب
/// وحده، والشريط يسكن **فوق** الـNavigator، فقراءتُه في تطبيق السائق تعطي
/// `null` — فتستبدل الشاشةُ الرماديّةُ التطبيقَ كلّه في اللحظة التي تنقطع
/// فيها الشبكة عن سائق يقود.
///
/// **وحدٌّ مُصارَحٌ به**: `connectivity_plus` يقرأ **وجود الواجهة** لا الوصول
/// إليها. هاتفٌ على شبكة خلويّة بلا إنتاجيّة — وهو حال قبو المواقف بعينه —
/// يُبلِّغ «متّصل» فلا يظهر الشريط. يمسك وضع الطيران وانعدام التغطية وسقوط
/// الواي-فاي، ولا يمسك الإشارة الضعيفة ولا البوّابات الأسيرة.
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({
    super.key,
    required this.child,
    required this.message,
  });

  final Widget child;

  /// نصّ الشريط — يُمرَّر من نقطة الدخول لأنّ لكلّ نكهة ترجمتها.
  final String message;

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;

  @override
  void initState() {
    super.initState();

    // فحصٌ أوّليّ ثم متابعة حيّة. الإصدار السادس يعيد **قائمة** واجهات (قد
    // يكون الهاتف على واي-فاي وبيانات معاً)، فـ«غير متّصل» تعني ألّا واجهة
    // إطلاقاً.
    Connectivity().checkConnectivity().then(_update);
    _subscription = Connectivity().onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final bool offline = results.isEmpty ||
        results.every((ConnectivityResult r) => r == ConnectivityResult.none);

    if (offline != _offline && mounted) {
      setState(() => _offline = offline);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // الشريط يدفع المحتوى لأسفل ولا يغطّيه: لا يحجب زرّاً ولا حقلاً.
        if (_offline)
          Material(
            color: Colors.red.shade700,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
