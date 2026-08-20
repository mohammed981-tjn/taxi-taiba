import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_projects/app_flavor.dart';
import 'package:flutter_projects/auth/signin_page.dart';
import 'package:flutter_projects/auth/signup_page.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/theme/app_theme.dart';

/// جلسة الضيف — الدخول يُطلب عند الحاجة إليه، لا عند فتح التطبيق.
///
/// **لماذا تغيّر هذا أصلاً.** كان أوّل ما يراه من ينزّل التطبيق شاشةَ دخول:
/// اسم وبريد وكلمة سرّ قبل أن يرى سيّارةً واحدة أو سعراً واحداً. وهو أسوأ
/// ترتيبٍ ممكن — يطلب الثقة قبل أن يعطي سبباً لها. والترتيب الصحيح معكوس:
/// افتح، وانظر السيّارات حولك، واعرف كم تكلّف رحلتك — ثمّ سجّل حين تطلبها.
///
/// **ولماذا جلسة مجهولة لا «بلا جلسة».** لأنّ قواعد القاعدة تشترط
/// `auth != null` لقراءة `onlineDrivers`، وهذا شرطٌ صحيح لا يُرخى: مواضع
/// السائقين الحيّة لا تُنشر للعالم. فالضيف يدخل بجلسة Firebase مجهولة —
/// معرّفٌ بلا بريد ولا كلمة سرّ — تكفي لرؤية الخريطة والسيّارات، ولا تكفي
/// لطلب رحلة. والقاعدة نفسها تمنع المجهول من إنشاء رحلة، فالبوّابة في الشاشة
/// ليست الحارس الوحيد.
///
/// **وحين يسجّل الضيف حساباً جديداً** تُربط جلسته المجهولة بالبريد وكلمة السرّ
/// (`linkWithCredential`) فيبقى المعرّف نفسه ولا يُخلَّف حسابٌ يتيم. أمّا من
/// يدخل بحسابٍ قائم فجلسته المجهولة تُترك — وتنظيفها إعدادٌ في Firebase:
/// **Authentication ← Settings ← حذف الحسابات المجهولة الخاملة تلقائياً**.
class GuestSession {
  const GuestSession._();

  static const String _introSeenKey = 'intro_seen';

  /// يُرفع حين ترفض Firebase الدخول المجهول — أي حين لم يُفعَّل المزوّد
  /// **Anonymous** في وحدة التحكّم. التطبيق حينها لا ينهار: الخريطة تعمل،
  /// والسيّارات القريبة وحدها لا تظهر لأن القراءة تُرفض.
  static bool anonymousUnavailable = false;

  static User? get _user => FirebaseAuth.instance.currentUser;

  /// ضيف = بلا حساب. وهما حالتان: جلسة مجهولة، أو لا جلسة أصلاً.
  static bool get isGuest {
    final User? user = _user;
    return user == null || user.isAnonymous;
  }

  static bool get isSignedIn => !isGuest;

  /// يُستدعى مرّةً عند الإقلاع — ولا يفعل شيئاً لمن جلسته قائمة.
  static Future<void> ensure() async {
    if (_user != null) return;
    try {
      await FirebaseAuth.instance.signInAnonymously();
      anonymousUnavailable = false;
    } on FirebaseAuthException catch (error) {
      anonymousUnavailable = true;
      debugPrint(
        'GuestSession: تعذّر إنشاء جلسة ضيف (${error.code}). '
        'فعّل مزوّد Anonymous في Firebase ← Authentication ← Sign-in method. '
        'حتى ذلك الحين تفتح الخريطة ولا تظهر السيّارات القريبة.',
      );
    } catch (error) {
      anonymousUnavailable = true;
      debugPrint('GuestSession: تعذّر إنشاء جلسة ضيف — $error');
    }
  }

  /// خروجٌ يعود بصاحب الجهاز **ضيفاً**، لا إلى العدم.
  ///
  /// `signOut()` وحدها تترك التطبيق بلا جلسة، وقواعد القاعدة تشترط
  /// `auth != null` لقراءة السيّارات القريبة — فتفرغ الخريطة بعد الخروج بلا
  /// سببٍ ظاهر، ويبدو الخروج عطلاً.
  static Future<void> dropToGuest() async {
    await FirebaseAuth.instance.signOut();
    await ensure();
  }

  /// شاشة التعريف تُعرض مرّةً في عمر التثبيت.
  ///
  /// كانت تُعرض لكلّ من ليس مسجّلاً — ومع جلسة الضيف صار ذلك يعني «لا أحد»،
  /// أو «كلّ مرّة» لو أُبقيت على الشرط القديم. فصار لها علمُها الخاصّ.
  static Future<bool> introSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markIntroSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
    } catch (_) {
      // علمُ عرضٍ لا بيانات: فقدانه يعيد شاشة التعريف مرّة، ولا يُفقد شيء.
    }
  }

  /// البوّابة: تُستدعى قبل أيّ فعلٍ يحتاج حساباً حقيقيّاً.
  ///
  /// تعيد `true` إن كان صاحب الجهاز مسجّلاً — أو صار مسجّلاً الآن. وتعيد
  /// `false` إن أغلق الورقة، ولا تُظهر خطأً: الرفض هنا اختيارٌ لا عطل.
  static Future<bool> requireAccount(BuildContext context) async {
    if (isSignedIn) return true;

    final bool? choice = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) => const _AccountSheet(),
    );

    if (choice != true) return false;
    return isSignedIn;
  }
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TaibahPalette palette = TaibahPalette.of(AppRole.passenger);

    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.signInToRide,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: 10),

            // السبب، لا الأمر. الفرق بين «سجّل دخولك» و«السائق يحتاج أن يعرف
            // من يستقبل» هو الفرق بين حاجزٍ وشرح.
            Text(
              l10n.signInWhy,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.6),
            ),
            const SizedBox(height: 22),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final bool? done = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => const SignUpPage(popOnSuccess: true),
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context, done == true);
              },
              child: Text(
                l10n.signUp,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final bool? done = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => const SigninPage(popOnSuccess: true),
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context, done == true);
              },
              child: Text(
                l10n.signIn,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.notNow,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
