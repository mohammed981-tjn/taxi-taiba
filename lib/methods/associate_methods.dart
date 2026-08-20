import 'package:flutter/material.dart';
import 'package:flutter_projects/model/direction_details_model.dart';
import 'package:flutter_projects/pricing.dart';

/// A fare split into the parts that produced it.
///
/// The receipt needs the parts, not just the sum, and the estimate shown before
/// booking must be the same arithmetic — so both read this one object rather
/// than each computing a total of their own.
class FareBreakdown {
  const FareBreakdown({
    required this.base,
    required this.distance,
    required this.duration,
    required this.fee,
    required this.distanceKm,
    required this.durationMin,
  });

  /// أجرة المسافة المشمولة — تسعة ريالات لأوّل خمسة كيلومترات.
  final double base;

  /// ما زاد على المشمولة، بريالٍ للكيلومتر.
  final double distance;

  /// الشقّ الزمنيّ — **صفرٌ في التعرفة الحاليّة**.
  ///
  /// يبقى الحقل ولا يُحذف: إيصالات الرحلات التي سبقت هذه التعرفة تحمله بقيمة،
  /// وقواعد القاعدة تجمّده بالاسم. وحذفه يكسر قراءة الماضي لتوفير سطر.
  final double duration;

  /// عمولة المنصّة الثابتة — يدفعها الراكب فوق الأجرة، ولا تدخل نصيب السائق.
  final double fee;

  final double distanceKm;
  final double durationMin;

  /// ما يدفعه الراكب.
  double get total => base + distance + duration + fee;

  /// وما يبقى للسائق بعد عمولة المنصّة.
  ///
  /// الفرق بين الرقمين هو الفرق بين «ما حصّلتُ» و«ما ربحتُ»، وخلطهما في شاشة
  /// أرباح السائق يجعل الرقم الذي يبني عليه دخله أكبر من الحقيقة بخمسة ريالات
  /// في كلّ رحلة.
  double get driverShare => total - fee;

  /// Written onto the trip, because a receipt is read long after the directions
  /// that produced these numbers have gone.
  Map<String, String> toMap() => {
        'base': base.toStringAsFixed(1),
        'distance': distance.toStringAsFixed(1),
        'duration': duration.toStringAsFixed(1),
        'fee': fee.toStringAsFixed(1),
        'distanceKm': distanceKm.toStringAsFixed(2),
        'durationMin': durationMin.toStringAsFixed(0),
        'total': total.toStringAsFixed(1),
      };
}

class AssociateMethods {
  /// أجرة تُستعمل حين لا تحمل الرحلة تفصيلاً — رحلة قديمة سبقت
  /// `fareBreakdown`. وهي الأساس وحده: إنهاء رحلة بصفر أسوأ من
  /// إنهائها بالحدّ الأدنى، وكلاهما يُراجَع من لوحة الإدارة.
  static const double fallbackFare = FareRates.minimum;

  showSnackBarMsg(String msg, BuildContext cxt) {
    var snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(cxt).showSnackBar(snackBar);
  }

  /// Splits the fare into base, distance and time.
  ///
  /// The time component was derived from `distanceValueDigits` — the same field
  /// the distance component uses — so a trip that crawled through traffic was
  /// charged exactly like one that ran clear, and `durationValueDigits` sat in
  /// the model unread. Nothing revealed it, because a single total is not a
  /// number anyone can check. It now uses the duration, which is what the field
  /// holds and what the receipt line will claim it is.
  ///
  /// Google returns metres and seconds, hence the /1000 and /60.
  /// المعامل يضرب **المكوّنات** لا المجموع.
  ///
  /// لو ضُرب المجموع وحده لما جمعت أسطر الإيصال إلى ما دُفع: يقرأ الراكب
  /// أساساً ومسافةً وزمناً تحتها إجماليٌّ لا يساوي جمعها. والإيصال الذي لا
  /// يُجمَع هو أوّل ما يُشكَّك فيه.
  FareBreakdown fareBreakdown(
    DirectionDetailsModel directionDetails, {
    VehicleTier tier = VehicleTier.go,
  }) {
    final double distanceKm = (directionDetails.distanceValueDigits ?? 0) / 1000;
    final double durationMin = (directionDetails.durationValueDigits ?? 0) / 60;

    final double m = tier.multiplier;

    // ما زاد على المسافة المشمولة — ولا يكون سالباً: رحلةُ كيلومترين تدفع
    // التسعة كاملةً ولا تُخصم منها.
    final double extraKm =
        (distanceKm - FareRates.includedKm).clamp(0, double.infinity);

    return FareBreakdown(
      base: FareRates.includedFare * m,
      distance: extraKm * FareRates.perExtraKm * m,

      // لا شقّ زمنيّ في التعرفة الحاليّة — راجع lib/pricing.dart.
      duration: 0,

      // ولا تُضرب العمولة بمعامل الفئة: «ثابتة» تعني ثابتة.
      fee: FareRates.platformFee,

      distanceKm: distanceKm,
      durationMin: durationMin,
    );
  }

  calculateFareAmount(
    DirectionDetailsModel directionDetails, {
    VehicleTier tier = VehicleTier.go,
  }) {
    return fareBreakdown(directionDetails, tier: tier).total.toStringAsFixed(1);
  }
}
