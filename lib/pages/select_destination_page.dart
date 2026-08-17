import 'package:flutter/material.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/methods/google_map_methods.dart';
import 'package:flutter_projects/model/prediction_model.dart';
import 'package:flutter_projects/widgets/prediction_places_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';

class SelectDestinationPage extends StatefulWidget {
  const SelectDestinationPage({super.key});

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController = TextEditingController();
  List<PredictionModel> dropOffPredictionsPlacesList = [];

  searchPlace(String userInput) async {
    if (userInput.length > 1) {
      // البلد من `placesComponents` لا مكتوباً هنا — راجع lib/global.dart.
      // والمدخل يُرمَّز: اسم حيّ فيه مسافة أو `&` كان يقطع العنوان ويُفسد
      // الطلب كلّه، وهو أمرٌ يقع مع أول اسم عربي مركّب.
      String placesAPIurl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=${Uri.encodeQueryComponent(userInput)}"
          "&key=$googleMapKey"
          "&components=$placesComponents"
          "&language=ar";
      var responseFromPlacesAPI = await GoogleMapMethods.sendRequestToApi(placesAPIurl);

      if (responseFromPlacesAPI == "error") {
        return;
      }
      if (responseFromPlacesAPI["status"] == "OK") {
        var predictionResultInJson = responseFromPlacesAPI["predictions"];
        var predictionResultInNormalFormat = (predictionResultInJson as List)
            .map((eachPredictedPlace) => PredictionModel.fromJson(eachPredictedPlace))
            .toList();

        setState(() {
          dropOffPredictionsPlacesList = predictionResultInNormalFormat;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String pickUpAddressOfUser =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation?.placeName ?? "";
    pickUpTextEditingController.text = pickUpAddressOfUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF010E4C),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          AppLocalizations.of(context)!.searchDestination,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Input Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF010E4C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Pickup Field
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: pickUpTextEditingController,
                          enabled: false,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.pickupAddress,
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Destination Field
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent, width: 1.5),
                        ),
                        child: TextField(
                          controller: destinationTextEditingController,
                          autofocus: true,
                          onChanged: (userInput) => searchPlace(userInput),
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterDestinationAddress,
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Predictions List
          Expanded(
            child: dropOffPredictionsPlacesList.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: dropOffPredictionsPlacesList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                    itemBuilder: (context, index) {
                      return PredictionPlacesUi(
                        predictionPlacesData: dropOffPredictionsPlacesList[index],
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_searching, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.searchDestination,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
