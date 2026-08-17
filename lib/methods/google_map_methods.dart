import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/model/address_model.dart';
import 'package:flutter_projects/model/direction_details_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class GoogleMapMethods {
  static sendRequestToApi(String apiUrl) async {
    http.Response responseFromAPI = await http.get(Uri.parse(apiUrl));

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      debugPrint("\n\nError Occurred::\n$errorMsg\n\n");
      return "error";
    }
  }

  ///Reverse GeoCoding
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";
    String geoCodingApiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

    var responseFromApi = await sendRequestToApi(geoCodingApiUrl);

    if (!context.mounted) return humanReadableAddress;
    if (responseFromApi != "error") {
      humanReadableAddress = responseFromApi["results"][0]["formatted_address"];
      debugPrint("humanReadableAddress = $humanReadableAddress");

      AddressModel addressModel = AddressModel();
      addressModel.humanReadableAddress = humanReadableAddress;
      addressModel.placeName = humanReadableAddress;
      addressModel.placeID = responseFromApi["results"][0]["place_id"];
      addressModel.latitudePosition = position.latitude;
      addressModel.longitudePosition = position.longitude;

      Provider.of<AppInfo>(context, listen: false)
          .updatePickupLocation(addressModel);
    } else {
      debugPrint("\n\nError Occurred\n\n");
    }

    return humanReadableAddress;
  }

  ///Direction API
  static Future<DirectionDetailsModel?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    String urlDirectionAPI =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${source.latitude},${source.longitude}&key=$googleMapKey";

    var responseFromDirectionAPI = await sendRequestToApi(urlDirectionAPI);

    if (responseFromDirectionAPI == "error") {
      return null;
    }

    DirectionDetailsModel detailsModel = DirectionDetailsModel();
    detailsModel.distanceTextString =
        responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["text"];
    detailsModel.distanceValueDigits =
        responseFromDirectionAPI["routes"][0]["legs"][0]["distance"]["value"];

    detailsModel.durationTextString =
        responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["text"];
    detailsModel.durationValueDigits =
        responseFromDirectionAPI["routes"][0]["legs"][0]["duration"]["value"];

    detailsModel.encodedPoints =
        responseFromDirectionAPI["routes"][0]["overview_polyline"]["points"];

    return detailsModel;
  }
}
