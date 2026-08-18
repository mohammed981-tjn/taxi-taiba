import 'package:flutter_projects/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/methods/associate_methods.dart';
import 'package:flutter_projects/model/direction_details_model.dart';
import 'package:provider/provider.dart';

class ChooseRidePage extends StatefulWidget {
  final DirectionDetailsModel? directionDetails;

  const ChooseRidePage({super.key, this.directionDetails});

  @override
  State<ChooseRidePage> createState() => _ChooseRidePageState();
}

class _ChooseRidePageState extends State<ChooseRidePage> {
  String selectedCarType = "Taibah Go";
  AssociateMethods associateMethods = AssociateMethods();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: TaibahPalette.passenger.primary,
        title: Text(
          AppLocalizations.of(context)!.chooseRide,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Locations Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset("assets/initial.png", height: 16, width: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Provider.of<AppInfo>(context).pickUpLocation?.placeName ?? "",
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Image.asset("assets/final.png", height: 16, width: 16),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Provider.of<AppInfo>(context).dropOffLocation?.placeName ?? "",
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Car List
          Expanded(
            child: ListView(
              children: [
                buildCarItem(
                  context,
                  AppLocalizations.of(context)!.oagoGo,
                  "assets/oagogo.png",
                  0.4,
                ),
                buildCarItem(
                  context,
                  AppLocalizations.of(context)!.oagoExecutive,
                  "assets/oagoexec.png",
                  0.7,
                ),
                buildCarItem(
                  context,
                  AppLocalizations.of(context)!.oagoXL,
                  "assets/oagoxl.png",
                  1.0,
                ),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedCarType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TaibahPalette.passenger.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                AppLocalizations.of(context)!.confirmRide,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCarItem(BuildContext context, String title, String imagePath, double factor) {
    bool isSelected = selectedCarType == title;
    
    // Custom fare calculation based on factor
    double baseFare = 200;
    double distFare = (widget.directionDetails!.distanceValueDigits! / 1000) * factor * 100; // Arbitrary multiplier
    double fare = baseFare + distFare;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCarType = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, height: 60, width: 80, fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 60),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.directionDetails?.durationTextString ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              money(fare.toStringAsFixed(1)),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
