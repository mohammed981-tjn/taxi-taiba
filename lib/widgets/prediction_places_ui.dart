import 'package:flutter/material.dart';
import 'package:flutter_projects/appinfo/app_info.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/methods/google_map_methods.dart';
import 'package:flutter_projects/methods/places_session.dart';
import 'package:flutter_projects/model/address_model.dart';
import 'package:flutter_projects/model/prediction_model.dart';
import 'package:flutter_projects/widgets/loading_dialog.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';

class PredictionPlacesUi extends StatefulWidget {
  final PredictionModel? predictionPlacesData;

  const PredictionPlacesUi({super.key, this.predictionPlacesData});

  @override
  State<PredictionPlacesUi> createState() => _PredictionPlacesUiState();
}

class _PredictionPlacesUiState extends State<PredictionPlacesUi> {
  fetchClickedPlaceDetails(String placeID) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(
        messageTxt: AppLocalizations.of(context)!.pleaseWait,
      ),
    );

    // `fields` ليست تقليصاً للرد بل للفاتورة.
    //
    // بلا هذه المعاملة تعيد Google كلّ ما تعرفه عن المكان — ساعات العمل
    // والهاتف والتقييمات والصور — وتُحاسِب على أغلى فئة. والشاشة تستعمل
    // حقلين: الاسم والإحداثيّتين. فطُلبا وحدهما، وهما في الفئة الأساسيّة
    // الأرخص.
    //
    // ورمز الجلسة نفسه المرسَل مع أحرف البحث: به يصير البحث كلّه واختياره
    // وحدةً واحدة عند المحاسبة.
    String urlPlaceDetailsAPI =
        "https://maps.googleapis.com/maps/api/place/details/json"
        "?place_id=$placeID"
        "&key=$googleMapKey"
        "&fields=name,geometry/location"
        "&sessiontoken=${PlacesSession.token}"
        "&language=ar";

    var responseFromPlaceDetailsAPI = await GoogleMapMethods.sendRequestToApi(urlPlaceDetailsAPI);

    // انتهت الجلسة باختيار، فيُجدَّد الرمز. ورمزٌ لا يُجدَّد يجعل بحث اليوم
    // كلّه جلسةً واحدة — ترفضه Google وتعود إلى المحاسبة بالطلب، فيضيع
    // المكسب كلّه بسطر لم يُكتب.
    PlacesSession.renew();

    if (!mounted) return;
    Navigator.pop(context);

    if (responseFromPlaceDetailsAPI == "error") {
      return;
    }

    if (responseFromPlaceDetailsAPI["status"] == "OK") {
      AddressModel dropOffLocation = AddressModel();
      dropOffLocation.placeName = responseFromPlaceDetailsAPI["result"]["name"];
      dropOffLocation.latitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lat"];
      dropOffLocation.longitudePosition = responseFromPlaceDetailsAPI["result"]["geometry"]["location"]["lng"];
      dropOffLocation.placeID = placeID;

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(dropOffLocation);

      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        fetchClickedPlaceDetails(widget.predictionPlacesData!.placeId.toString());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.blueAccent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.predictionPlacesData?.mainText ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.predictionPlacesData?.secondaryText ?? "",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
