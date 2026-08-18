import 'package:flutter/material.dart';
import 'package:flutter_projects/model/direction_details_model.dart';

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
    required this.distanceKm,
    required this.durationMin,
  });

  final double base;
  final double distance;
  final double duration;
  final double distanceKm;
  final double durationMin;

  double get total => base + distance + duration;

  /// Written onto the trip, because a receipt is read long after the directions
  /// that produced these numbers have gone.
  Map<String, String> toMap() => {
        'base': base.toStringAsFixed(1),
        'distance': distance.toStringAsFixed(1),
        'duration': duration.toStringAsFixed(1),
        'distanceKm': distanceKm.toStringAsFixed(2),
        'durationMin': durationMin.toStringAsFixed(0),
        'total': total.toStringAsFixed(1),
      };
}

class AssociateMethods {
  static const double _distancePerKmAmount = 0.4;
  static const double _durationPerMinuteAmount = 0.3;
  static const double _baseFareAmount = 200;

  /// أجرة تُستعمل حين لا تحمل الرحلة تفصيلاً — رحلة قديمة سبقت
  /// `fareBreakdown`. وهي الأساس وحده: إنهاء رحلة بصفر أسوأ من
  /// إنهائها بالحدّ الأدنى، وكلاهما يُراجَع من لوحة الإدارة.
  static const double fallbackFare = _baseFareAmount;

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
  FareBreakdown fareBreakdown(DirectionDetailsModel directionDetails) {
    final double distanceKm = (directionDetails.distanceValueDigits ?? 0) / 1000;
    final double durationMin = (directionDetails.durationValueDigits ?? 0) / 60;

    return FareBreakdown(
      base: _baseFareAmount,
      distance: distanceKm * _distancePerKmAmount,
      duration: durationMin * _durationPerMinuteAmount,
      distanceKm: distanceKm,
      durationMin: durationMin,
    );
  }

  calculateFareAmount(DirectionDetailsModel directionDetails) {
    return fareBreakdown(directionDetails).total.toStringAsFixed(1);
  }
}
