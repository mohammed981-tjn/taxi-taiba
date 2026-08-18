import 'package:flutter_projects/currency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final String fareAmount;
  const PaymentDialog({super.key, required this.fareAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  saveFareAmountToDriverTotalEarnings(String fareAmount) async {
    DatabaseReference driverEarnigsRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    await driverEarnigsRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        double previousTotalEarnings =
            double.parse(snap.snapshot.value.toString());
        double fareAmountForTrip = double.parse(fareAmount);
        double newTotalEarnings = previousTotalEarnings + fareAmountForTrip;
        driverEarnigsRef.set(newTotalEarnings);
      } else {
        driverEarnigsRef.set(fareAmount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
      ),
      backgroundColor: Colors.white,
      child: Container(
        margin: const EdgeInsets.all(5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 21,
            ),
            const Text(
              "ARRIVED DESTINATION",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 21,
            ),
            const Divider(
              height: 1.5,
              color: Colors.grey,
              thickness: 1,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              money(widget.fareAmount),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 36,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              "You will pay ( ${money(widget.fareAmount)} ) for this trip.",
              style: const TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
        const SizedBox(height: 31),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spaces the buttons evenly
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, "paid");
              },
              style: ElevatedButton.styleFrom(backgroundColor: TaibahPalette.passenger.primary),
              child: const Text(
                "PAY CASH",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: TaibahPalette.passenger.primary),
              child: const Text(
                "PAY ONLINE",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 21),
        ],
      ),
    ),
    );
  }
}
