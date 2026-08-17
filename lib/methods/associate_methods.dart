import 'package:flutter/material.dart';
import 'package:flutter_projects/model/direction_details_model.dart';

class AssociateMethods {
  showSnackBarMsg(String msg, BuildContext cxt) {
    var snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(cxt).showSnackBar(snackBar);
  }

  calculateFareAmount(DirectionDetailsModel directionDetails) {
    double distancePerKmAmount = 0.4;
    double durationPerMinuteAmount = 0.3;
    double baseFareAmount = 200;

    double totalDistanceTravelFareAmount =
        (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmount;
    double totalDurationSpendFareAmount =
        (directionDetails.distanceValueDigits! / 60) * durationPerMinuteAmount;

    double overAllTotalFareAmount = baseFareAmount +
        totalDistanceTravelFareAmount +
        totalDurationSpendFareAmount;
    return overAllTotalFareAmount.toStringAsFixed(1);
  }
}
