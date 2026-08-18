import 'dart:async';

import 'package:flutter_projects/currency.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_projects/auth/signin_page.dart';
import 'package:flutter_projects/global.dart';
import 'package:flutter_projects/locale_provider.dart';
import 'package:flutter_projects/methods/geo_query.dart';
import 'package:flutter_projects/methods/google_map_methods.dart';
import 'package:flutter_projects/methods/manage_drivers_methods.dart';
import 'package:flutter_projects/model/direction_details_model.dart';
import 'package:flutter_projects/model/online_nearby_drivers.dart';
import 'package:flutter_projects/pages/about_page.dart';
import 'package:flutter_projects/pages/choose_ride_page.dart';
import 'package:flutter_projects/pages/profile_page.dart';
import 'package:flutter_projects/pages/rating_screen.dart';
import 'package:flutter_projects/pages/select_destination_page.dart';
import 'package:flutter_projects/pages/trip_history_page.dart';
import 'package:flutter_projects/pushNotificationSystem/push_notification_system.dart';
import 'package:flutter_projects/widgets/information_dialog.dart';
import 'package:flutter_projects/widgets/loading_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../appinfo/app_info.dart';
import '../widgets/payment_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double bottomMapPadding = 0;
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  double searchContainerHeight = 220;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double rideDetailsContainerHeight = 0;
  bool isDrawerOpened = true;
  DirectionDetailsModel? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  String stateOfApp = "normal";
  DatabaseReference? tripRequestRef;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;

  String selectedCarType = "Taibah Go";

  getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position userPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation));
    currentPositionOfUser = userPosition;

    LatLng userLatLng = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

    CameraPosition positionCamera =
        CameraPosition(target: userLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(positionCamera));

    if (!mounted) return;
    await GoogleMapMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
        currentPositionOfUser!, context);

    await getUserInfoAndCheckBlockStatus();
    debugPrint('step :: 5');
    initializeCustomGeoListener();
  }

  getUserInfoAndCheckBlockStatus() async {
    DatabaseReference reference = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await reference.once().then((dataSnap) {
      if (!mounted) return;
      if (dataSnap.snapshot.value != null) {
        if ((dataSnap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (dataSnap.snapshot.value as Map)["name"];
            userPhone = (dataSnap.snapshot.value as Map)["phone"];
          });
        } else {
          FirebaseAuth.instance.signOut();
          Navigator.push(
              context, MaterialPageRoute(builder: (c) => const SigninPage()));
          associateMethods.showSnackBarMsg(
              AppLocalizations.of(context)!.blockedMsg,
              context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const SigninPage()));
      }
    });
  }

  displayUserRideDetailsContainer() async {
    ///Direction API
    await retrieveDirectionDetails();

    if (tripDirectionDetailsInfo == null) return;

    if (!mounted) return;
    var responseFromChooseRidePage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => ChooseRidePage(directionDetails: tripDirectionDetailsInfo),
      ),
    );

    if (responseFromChooseRidePage != null) {
      if (!mounted) return;
      setState(() {
        selectedCarType = responseFromChooseRidePage;
        searchContainerHeight = 0;
        bottomMapPadding = 250;
        rideDetailsContainerHeight = 255;
        isDrawerOpened = false;
      });
    }
  }

  retrieveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickUpGeoGraphicCoOrdinates = LatLng(
        pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(
        dropOffDestinationLocation!.latitudePosition!,
        dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
           LoadingDialog(messageTxt: AppLocalizations.of(context)!.gettingDirection),
    );

    ///Direction API
    var detailsFromDirectionAPI =
        await GoogleMapMethods.getDirectionDetailsFromAPI(
            pickUpGeoGraphicCoOrdinates,
            dropOffDestinationGeoGraphicCoOrdinates);
    if (!mounted) return;
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    ///Draw route from pickup to dropOffDestination
    List<PointLatLng> latlngPointsFromPickUpToDestination =
        PolylinePoints.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();
    if (latlngPointsFromPickUpToDestination.isNotEmpty) {
      for (var latLngpoint in latlngPointsFromPickUpToDestination) {
        polylineCoOrdinates
            .add(LatLng(latLngpoint.latitude, latLngpoint.longitude));
      }
    }

    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("polyLineID"),
        color: Colors.green,
        points: polylineCoOrdinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    //fit the polyline into the map
    LatLngBounds boundsLatLng;
    if (pickUpGeoGraphicCoOrdinates.latitude >
            dropOffDestinationGeoGraphicCoOrdinates.latitude &&
        pickUpGeoGraphicCoOrdinates.longitude >
            dropOffDestinationGeoGraphicCoOrdinates.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: dropOffDestinationGeoGraphicCoOrdinates,
        northeast: pickUpGeoGraphicCoOrdinates,
      );
    } else if (pickUpGeoGraphicCoOrdinates.longitude >
        dropOffDestinationGeoGraphicCoOrdinates.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(pickUpGeoGraphicCoOrdinates.latitude,
            dropOffDestinationGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
            pickUpGeoGraphicCoOrdinates.longitude),
      );
    } else if (pickUpGeoGraphicCoOrdinates.latitude >
        dropOffDestinationGeoGraphicCoOrdinates.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude,
            pickUpGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(pickUpGeoGraphicCoOrdinates.latitude,
            dropOffDestinationGeoGraphicCoOrdinates.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: pickUpGeoGraphicCoOrdinates,
        northeast: dropOffDestinationGeoGraphicCoOrdinates,
      );
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add markers to pickup and dropOffDestination points
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickUpGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: pickUpLocation.placeName, snippet: "Pickup Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: dropOffDestinationLocation.placeName,
          snippet: "Destination Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    //add circles to pickup and dropOffDestination points
    Circle pickUpPointCircle = Circle(
      circleId: const CircleId('pickupCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: pickUpGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    Circle dropOffDestinationPointCircle = Circle(
      circleId: const CircleId('dropOffDestinationCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: dropOffDestinationGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }

  makeDriverNearbyCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration =
          createLocalImageConfiguration(context, size: const Size(38, 38));
      BitmapDescriptor.asset(configuration, "assets/tracking.png")
          .then((iconImage) {
        carIconNearbyDriver = iconImage;

        // السائقون الذين وصلوا قبل الأيقونة تُخطّى رسمتهم. فبدون هذا السطر
        // يبقون غائبين عن الخريطة إلى أن يتحرّك أحدهم — وقد لا يتحرّك.
        if (mounted && ManageDriversMethods.nearbyOnlineDriversList.isNotEmpty) {
          updateAvailableNearbyOnlineDriversOnMap();
        }
      });
    }
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    // الأيقونة تُحمَّل بشكل غير متزامن في build، والأحداث الآن تصل أبكر من
    // قبل — فأول سائق قد يسبقها. و`carIconNearbyDriver!` أدناه كان سيرمي
    // عندئذٍ. لا ضرر في التخطّي: الحدث التالي للسائق نفسه يعيد الرسم.
    if (carIconNearbyDriver == null) {
      debugPrint('map: car icon not ready yet, skipping this redraw');
      return;
    }

    if (!mounted) return;

    setState(() {
      markerSet.clear();
    });

    debugPrint(
        'ManageDriversMethods.nearbyOnlineDriversList :: ${ManageDriversMethods.nearbyOnlineDriversList}');

    if (ManageDriversMethods.nearbyOnlineDriversList.isNotEmpty) {
      Set<Marker> markersTempSet = <Marker>{};
      for (OnlineNearbyDrivers eachOnlineNearbyDriver
          in ManageDriversMethods.nearbyOnlineDriversList) {
        LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!,
            eachOnlineNearbyDriver.lngDriver!);

        debugPrint("\n\n\ndriverCurrentPosition::\n\n");
        debugPrint(driverCurrentPosition.toString());

        Marker driverMarker = Marker(
          markerId: MarkerId(
              "driver_ID = ${eachOnlineNearbyDriver.uidDriver}"),
          position: driverCurrentPosition,
          icon: carIconNearbyDriver!,
        );

        markersTempSet.add(driverMarker);
      }
      setState(() {
        markerSet = markersTempSet;
      });
    }
  }

  // initializeGeoFireListener() {
  //   debugPrint('initializeGeoFireListener');
  //   Geofire.initialize("onlineDrivers");
  //
  //   _geoFireSubscription = Geofire.queryAtLocation(
  //           currentPositionOfUser!.latitude,
  //           currentPositionOfUser!.longitude,
  //           22)!
  //       .listen((driverEvent) {
  //     debugPrint('driverEvent :: ${driverEvent.resut}');
  //     try {
  //       if (driverEvent != null) {
  //         debugPrint('driverEvent :: ${driverEvent}');
  //         var onlineDriverChild = driverEvent["callBack"];
  //         debugPrint('onlineDriverChild :: ${onlineDriverChild}');
  //
  //         switch (onlineDriverChild) {
  //           case Geofire.onKeyEntered:
  //             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
  //             debugPrint('driverEvent["key"] :: ${driverEvent["key"]}');
  //             onlineNearbyDrivers.uidDriver = driverEvent["key"];
  //             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
  //             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
  //             ManageDriversMethods.nearbyOnlineDriversList
  //                 .add(onlineNearbyDrivers);
  //             debugPrint(
  //                 'onlineNearbyDrivers :: ${onlineNearbyDrivers.uidDriver}\n${onlineNearbyDrivers.latDriver}\n${onlineNearbyDrivers.lngDriver}');
  //
  //             if (nearbyOnlineDriversKeysLoaded == true) {
  //               //update drivers on google map
  //               updateAvailableNearbyOnlineDriversOnMap();
  //             }
  //             break;
  //
  //           case Geofire.onKeyExited:
  //             ManageDriversMethods.removeDriverFromList(driverEvent["key"]);
  //             //update drivers on google map
  //             updateAvailableNearbyOnlineDriversOnMap();
  //             break;
  //
  //           case Geofire.onKeyMoved:
  //             OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
  //             onlineNearbyDrivers.uidDriver = driverEvent["key"];
  //             onlineNearbyDrivers.latDriver = driverEvent["latitude"];
  //             onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
  //             ManageDriversMethods.updateOnlineNearbyDriversLocation(
  //                 onlineNearbyDrivers);
  //             //update drivers on google map
  //             updateAvailableNearbyOnlineDriversOnMap();
  //             break;
  //
  //           case Geofire.onGeoQueryReady:
  //             nearbyOnlineDriversKeysLoaded = true;
  //             //update drivers on google map
  //             updateAvailableNearbyOnlineDriversOnMap();
  //             break;
  //
  //           default:
  //             debugPrint('this is default case');
  //         }
  //       } else {
  //         debugPrint('else part run');
  //       }
  //     } catch (e, stacktrace) {
  //       debugPrint('GeoFire listener error: $e');
  //       debugPrint(stacktrace);
  //     }
  //   }) /*.onError((e) => debugPrint('error is :::: $e'))*/;
  // }

  final _driversRef = FirebaseDatabase.instance.ref().child('onlineDrivers');

  /// نصف قطر البحث — نفس الـ٢٢ كم التي كان يقصّ عندها المرشّح القديم.
  static const double _searchRadiusMeters = 22000;

  /// كل الاشتراكات المفتوحة على القاعدة، محفوظة لتُلغى.
  ///
  /// كانت واحداً، وصارت عدّة: لكل مدى جيوهاش ثلاثة أحداث. والقائمة هي ما يضمن
  /// أن الإغلاق يطال الجميع — اشتراكٌ منسيّ يبقى ينزّل ويُحاسَب عليه.
  final List<StreamSubscription<DatabaseEvent>> _driverSubscriptions =
      <StreamSubscription<DatabaseEvent>>[];

  void _cancelDriverSubscriptions() {
    for (final StreamSubscription<DatabaseEvent> subscription
        in _driverSubscriptions) {
      subscription.cancel();
    }
    _driverSubscriptions.clear();
  }

  /// الاستماع للسائقين القريبين — بالفروق لا بالشجرة، وبالجوار لا بالعالم.
  ///
  /// ما كان يجري قبل هذا السطر: `onValue` على `onlineDrivers` كلها. وهذان
  /// خطآن مركّبان في مكالمة واحدة.
  ///
  /// الأول أن `onValue` يعيد **العقدة كاملة عند كل تغيير**. سائق واحد يتحرّك
  /// متراً، فتنزل بيانات كل السائقين من جديد. مع ثلاثين سائقاً يحدّثون موقعهم
  /// كل ثانيتين، هذا ٩٠٠ رسالة في الثانية إلى كل هاتف بدل ١٥ — أي أن الكلفة
  /// تتناسب مع **مربّع** عدد السائقين، لا مع عددهم. وهنا ذهبت الغيغابايتات.
  ///
  /// والثاني أن النطاق كان الأرض كلها: كل سائق في كل مدينة يُنزَّل إلى كل
  /// هاتف، ثم يُرمى في السطر التالي لأن `distance <= 22` رفضه. دفعتَ ثمن
  /// نقله لتقرأ أنه بعيد.
  ///
  /// والبديل يعالج الاثنين: `onChildAdded/Changed/Removed` تنقل السائق الذي
  /// تغيّر وحده، و`orderByChild('g')` مع مدى جيوهاش تقصر ما يصل على الجوار.
  /// الفهرس الذي تحتاجه هذه المكالمة منشورٌ في `database.rules.json` تحت
  /// `.indexOn: ["g"]` — وبدونه ترفض القاعدة الاستعلام صراحةً.
  void initializeCustomGeoListener() {
    if (currentPositionOfUser == null) {
      debugPrint('initializeCustomGeoListener: no position yet');
      return;
    }

    // الإلغاء أولاً لا الإضافة فوق القائم: هذه الدالة تُستدعى ثانيةً بعد كل
    // رحلة، وبغير هذا السطر تتراكم مجموعة استعلامات جديدة على القديمة.
    _cancelDriverSubscriptions();
    ManageDriversMethods.nearbyOnlineDriversList.clear();

    final List<List<String>> bounds = geohashQueryBounds(
      currentPositionOfUser!.latitude,
      currentPositionOfUser!.longitude,
      _searchRadiusMeters,
    );

    debugPrint('geo listener: ${bounds.length} range(s) for '
        '${_searchRadiusMeters ~/ 1000}km');

    for (final List<String> range in bounds) {
      final Query query =
          _driversRef.orderByChild('g').startAt(range[0]).endAt(range[1]);

      _driverSubscriptions.add(query.onChildAdded.listen(_onDriverUpserted));
      _driverSubscriptions.add(query.onChildChanged.listen(_onDriverUpserted));
      _driverSubscriptions.add(query.onChildRemoved.listen(_onDriverRemoved));
    }

    nearbyOnlineDriversKeysLoaded = true;
  }

  /// سائق دخل النطاق أو تحرّك داخله.
  void _onDriverUpserted(DatabaseEvent event) {
    final String? driverId = event.snapshot.key;
    if (driverId == null) return;

    final LatLng? position = _readDriverPosition(event.snapshot.value);
    if (position == null) {
      // شكل غير متوقّع في القاعدة يُتجاهل بهدوء: صفٌّ واحد تالف لا يجوز أن
      // يُسقط بقيّة السائقين معه.
      debugPrint('geo listener: unreadable location for $driverId');
      return;
    }

    // المدى النصّي يجلب صندوقاً، والصندوق أوسع من الدائرة بنحو ٢٧٪ في أركانه.
    // فيبقى القصّ الدقيق هنا — على ما وصل وحده.
    final double distance = distanceInMeters(
      currentPositionOfUser!.latitude,
      currentPositionOfUser!.longitude,
      position.latitude,
      position.longitude,
    );

    if (distance > _searchRadiusMeters) {
      // خرج من الدائرة وهو ما يزال في الصندوق — يُزال إن كان معروضاً.
      ManageDriversMethods.removeDriverFromList(driverId);
    } else {
      ManageDriversMethods.updateOnlineNearbyDriversLocation(
        OnlineNearbyDrivers(
          uidDriver: driverId,
          latDriver: position.latitude,
          lngDriver: position.longitude,
        ),
      );
    }

    updateAvailableNearbyOnlineDriversOnMap();
  }

  /// سائق خرج من النطاق أو انقطع.
  void _onDriverRemoved(DatabaseEvent event) {
    final String? driverId = event.snapshot.key;
    if (driverId == null) return;

    ManageDriversMethods.removeDriverFromList(driverId);
    updateAvailableNearbyOnlineDriversOnMap();
  }

  /// قراءة `l` بشكليها.
  ///
  /// GeoFire يكتبها قائمة `[lat, lng]`، لكن قاعدة الوقت الحقيقي تعيد القائمة
  /// خريطةً `{0: lat, 1: lng}` متى كان فيها فراغ في الفهرسة. والشيفرة السابقة
  /// كانت تفترض القائمة وحدها — `value['l'][0]` — فترمي استثناءً يقتل المستمع
  /// كلّه عند أول صفّ مخالف.
  LatLng? _readDriverPosition(Object? value) {
    if (value is! Map) return null;

    final Object? location = value['l'];

    double? asDouble(Object? raw) => raw is num ? raw.toDouble() : null;

    if (location is List && location.length >= 2) {
      final double? lat = asDouble(location[0]);
      final double? lng = asDouble(location[1]);
      if (lat != null && lng != null) return LatLng(lat, lng);
      return null;
    }

    if (location is Map) {
      final double? lat = asDouble(location[0] ?? location['0']);
      final double? lng = asDouble(location[1] ?? location['1']);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    return null;
  }

  searchDriver() {
    if (availableNearbyOnlineDriversList!.isEmpty) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    var currentDriver = availableNearbyOnlineDriversList![0];

    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key);

    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    debugPrint("driver data :$tokenOfCurrentDriverRef");

    tokenOfCurrentDriverRef.once().then((dataSnapshot) {
      if (!mounted) return;
      if (dataSnapshot.snapshot.value != null) {
        String deviceToken = dataSnapshot.snapshot.value.toString();
        debugPrint('tripRequestRef :: $deviceToken');
        PushNotificationSystem.sendNotificationToSelectedDriver(
          deviceToken,
          context,
          tripRequestRef!.key.toString(),
        );
      } else {
        return;
      }

      const oneTickPerSec = Duration(seconds: 1);
      Timer.periodic(oneTickPerSec, (timer) {
        requestTimeoutDriver = requestTimeoutDriver - 1;

        if (stateOfApp != "requesting") {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }

        currentDriverRef.onValue.listen((dataSnapshot) {
          if (dataSnapshot.snapshot.value.toString() == "accepted") {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        if (requestTimeoutDriver == 0) {
          currentDriverRef.set("timeout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;

          searchDriver();
        }
      });
    });
  }

  cancelRideRequest() {
    tripRequestRef!.remove();

    setState(() {
      stateOfApp = "normal";
    });
  }

  resetAppNow() {
    setState(() {
      polylineCoOrdinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 301;
      isDrawerOpened = true;

      nameDriver = '';
      phoneNumberDriver = '';
      status = '';
      carDetailsDriver = '';
      tripStatusDisplay = AppLocalizations.of(context)!.driverIsArriving;
    });
  }

  noDriverAvailable() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>  InformationDialog(
        title: AppLocalizations.of(context)!.noDriverAvailable,
        description:
            AppLocalizations.of(context)!.noDriverFound,
      ),
    );
  }

  displayRequestContainer() {
    setState(() {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 190;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    });

    saveTripRequestInfoToDB();
  }

  saveTripRequestInfoToDB() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap = {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };
    Map dropOffDestinationCoOrdinatesMap = {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverOrdinates = {
      "latitude": "0.0",
      "longitude": "0.0",
    };

    Map dataMap = {
      "tripId": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": FirebaseAuth.instance.currentUser!.uid,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,
      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverOrdinates,
      "driverName": "",
      "driverPhone": "",
      // "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
      // Written now, from the directions this request was quoted against,
      // because a receipt is read long after those directions are gone. The
      // driver app still settles `fareAmount` at the end; these are the parts
      // that explain it, not a second source for the total.
      if (tripDirectionDetailsInfo != null)
        "fareBreakdown":
            associateMethods.fareBreakdown(tripDirectionDetailsInfo!).toMap(),
    };

    tripRequestRef!.set(dataMap);

    tripStreamSubscription =
        tripRequestRef!.onValue.listen((eventSnapshot) async {
      if (eventSnapshot.snapshot.value == null) {
        return;
      }

      if ((eventSnapshot.snapshot.value as Map)["driverName"] != null) {
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }
      if ((eventSnapshot.snapshot.value as Map)["carDetails"] != null) {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }
      if ((eventSnapshot.snapshot.value as Map)["status"] != null) {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }
      if ((eventSnapshot.snapshot.value as Map)["driverLocation"] != null &&
          (eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"] !=
              '0.0' &&
          (eventSnapshot.snapshot.value as Map)["driverLocation"]
                  ["longitude"] !=
              '0.0') {
        double driverLatitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverLongitude = double.parse(
            (eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());
        LatLng driverCurrentLocationLatLng =
            LatLng(driverLatitude, driverLongitude);

        if (status == "accepted") {
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        } else if (status == "arrived") {
          setState(() {
            tripStatusDisplay = AppLocalizations.of(context)!.driverHasArrived;
          });
        } else if (status == "ontrip") {
          updateFromDriverCurrentLocationToDropOffDestination(
              driverCurrentLocationLatLng);
        }

        if (status == "accepted") {
          displayTripDetailsContainer();

          // A driver is assigned, so the other cars are no longer of any use to
          // this screen — and these are the streams that are actually running.
          _cancelDriverSubscriptions();

          setState(() {
            markerSet.removeWhere(
              (element) => element.markerId.value.contains("driver"),
            );
          });
        }
        if (status == "ended") {
          if ((eventSnapshot.snapshot.value as Map)['fareAmount'] != null) {
            double fareAmount = double.parse(
                (eventSnapshot.snapshot.value as Map)['fareAmount'].toString());

            if (!mounted) return;
            var responseFromPaymentDialog = await showDialog(
              context: context,
              builder: (context) => PaymentDialog(fareAmount: '$fareAmount'),
            );

            if (responseFromPaymentDialog == "paid") {
              // Read before the reference is dropped: the rating needs to know
              // which trip and which driver it belongs to, and two lines below
              // there is nothing left to ask.
              final tripMap = eventSnapshot.snapshot.value as Map;
              final String ratedTripId =
                  tripMap['tripId']?.toString() ?? tripRequestRef!.key ?? '';
              final String ratedDriverId = tripMap['driverID']?.toString() ?? '';
              final String ratedDriverName =
                  tripMap['driverName']?.toString() ?? '';

              tripRequestRef!.onDisconnect();
              tripRequestRef = null;

              tripStreamSubscription!.cancel();
              tripStreamSubscription = null;

              resetAppNow();

              if (!mounted) return;
              // Asked here rather than on the next launch, because a rating
              // given now is about a trip the passenger still remembers. It is
              // awaited so the restart below does not tear the screen away
              // mid-answer; skipping returns immediately.
              if (ratedTripId.isNotEmpty) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatingScreen(
                      tripId: ratedTripId,
                      driverId: ratedDriverId,
                      driverName: ratedDriverName,
                    ),
                  ),
                );
              }

              if (!mounted) return;
              Phoenix.rebirth(context);
            }
          }
        }
      }
    });
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailPickup =
          await GoogleMapMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if (directionDetailPickup == null) {
        return;
      }
      setState(() {
        tripStatusDisplay =
            "${AppLocalizations.of(context)!.driverIsComing} - ${directionDetailPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(
      driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;
      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).dropOffLocation;

      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!,
          dropOffLocation.longitudePosition!);

      var directionDetailsPickup =
          await GoogleMapMethods.getDirectionDetailsFromAPI(
              driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if (directionDetailsPickup == null) {
        return;
      }
      setState(() {
        tripStatusDisplay =
            "${AppLocalizations.of(context)!.drivingToDropoff} - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  @override
  void dispose() {
    // Neither stream was released when this screen went away, so leaving the
    // map and coming back left the previous listeners running and added new
    // ones beside them — each abandoned copy kept costing bandwidth for as
    // long as the app stayed open.
    _cancelDriverSubscriptions();
    tripStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: SizedBox(
          width: 256,
          child: Drawer(
            child: ListView(
              children: [
                //header
                SizedBox(
                  height: 160,
                  child: DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/avatar.webp",
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfilePage(),
                                    ),
                                  );
                                  setState(() {});
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.myProfile,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      )),
                ),

                //body
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripHistoryPage(),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(
                      Icons.history,
                      color: Colors.black,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.myTrips,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: const Icon(
                      Icons.info,
                      color: Colors.black,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.aboutUs,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),

                //تبديل اللغة (عربي / إنجليزي)
                Consumer<LocaleProvider>(
                  builder: (context, localeProvider, child) {
                    final isArabic =
                        localeProvider.locale.languageCode == 'ar';
                    return GestureDetector(
                      onTap: () {
                        context.read<LocaleProvider>().toggleLocale();
                        Navigator.pop(context);
                      },
                      child: ListTile(
                        leading: const Icon(
                          Icons.language,
                          color: Colors.black,
                        ),
                        title: Text(
                          isArabic ? "English" : "العربية",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  },
                ),

                GestureDetector(
                  onTap: () {
                    FirebaseAuth.instance.signOut();

                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const SigninPage()));
                  },
                  child: ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.logout,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          )),
      body: Stack(
        children: [
          ///google map
          GoogleMap(
            padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: kGooglePlex,
            onMapCreated: (GoogleMapController mapController) {
              debugPrint('map create');
              controllerGoogleMap = mapController;

              googleMapCompleterController.complete(controllerGoogleMap);

              setState(() {
                bottomMapPadding = 301;
              });

              getCurrentLocation();
            },
          ),

          // خريطةٌ بلا مفتاح تُرسم رماديّةً صامتة، فيبدو العطل في الشبكة أو
          // في الجهاز ويُبحث عنه في غير مكانه. هذا الشريط يقول أين هو.
          if (googleMapKey.isEmpty)
            Positioned(
              top: 90,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.amber.shade100,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'الخريطة معطّلة في هذا البناء — لا مفتاح خرائط.\n'
                    'يُضبط MAPS_API_KEY في أسرار المستودع ثم يُعاد البناء.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

          ///drawer button
          Positioned(
            top: 37,
            left: 20,
            child: GestureDetector(
              onTap: () {
                if (isDrawerOpened == true) {
                  sKey.currentState!.openDrawer();
                } else {
                  resetAppNow();
                  Phoenix.rebirth(context);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                  ),
                ),
              ),
            ),
          ),

          ///search location container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.bounceInOut,
              duration: const Duration(milliseconds: 122),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(21),
                    topLeft: Radius.circular(21),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.blue,
                          ),
                          const SizedBox(
                            width: 13.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.from,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                Provider.of<AppInfo>(context, listen: true)
                                            .pickUpLocation ==
                                        null
                                    ? AppLocalizations.of(context)!.pleaseWait
                                    : "${Provider.of<AppInfo>(context,
                                                listen: false)
                                            .pickUpLocation!
                                            .placeName!}...",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.add_location_alt_outlined,
                            color: Colors.blue,
                          ),
                          const SizedBox(
                            width: 13.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => const SelectDestinationPage()));
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.to,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.addDropoffLocation,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () async {
                          var responseFromSelectDestinationPage =
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => const SelectDestinationPage()));

                          if (responseFromSelectDestinationPage ==
                              "placeSelected") {
                            displayUserRideDetailsContainer();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.searchDestination,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          ///ride details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: const BoxDecoration(
                image:  DecorationImage(
                  image: AssetImage("assets/background.jpg"), // Replace with your image path
                  fit: BoxFit.cover, // Ensures the image covers the whole container
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(.7, .7),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      selectedCarType == "Taibah Go" 
                          ? "assets/oagogo.png" 
                          : selectedCarType == "Taibah Executive" 
                              ? "assets/oagoexec.png" 
                              : "assets/oagoxl.png",
                      height: 80,
                      width: 140,
                      errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 80),
                    ),
                    Text(
                      (tripDirectionDetailsInfo != null)
                          ? money("${selectedCarType == "Taibah Go" ? (double.parse(associateMethods.calculateFareAmount(tripDirectionDetailsInfo!)) * 0.8).toStringAsFixed(1) : selectedCarType == "Taibah Executive" ? associateMethods.calculateFareAmount(tripDirectionDetailsInfo!) : (double.parse(associateMethods.calculateFareAmount(tripDirectionDetailsInfo!)) * 1.5).toStringAsFixed(1)}")
                          : "",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          (tripDirectionDetailsInfo != null)
                              ? tripDirectionDetailsInfo!.distanceTextString!
                              : "",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          (tripDirectionDetailsInfo != null)
                              ? tripDirectionDetailsInfo!.durationTextString!
                              : "",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      thickness: 2,
                      color: Colors.black,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          stateOfApp = 'requesting';
                        });

                        displayRequestContainer();
                        availableNearbyOnlineDriversList =
                            ManageDriversMethods.nearbyOnlineDriversList;

                        //find driver
                        searchDriver();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TaibahPalette.passenger.primary,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.getDriver,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ///request container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                      LoadingAnimationWidget.flickr(
                      leftDotColor: Colors.green,
                      rightDotColor: Colors.blue,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        resetAppNow();
                        cancelRideRequest();
                        Phoenix.rebirth(context);
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.black),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          ///trip detail container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Spacing inside the rectangle
                      decoration: BoxDecoration(
                        color: TaibahPalette.passenger.primary, // Background color
                        borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                      ),
                      child: Text(
                        tripStatusDisplay,
                        style: const TextStyle(
                          fontSize: 19,
                          color: Colors.white, // Text color for contrast
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                      height: 19,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            "assets/driver_avatar.webp",
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameDriver,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              carDetailsDriver,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 19,
                    ),
                    const Divider(
                      height: 1,
                      color: Colors.grey,
                      thickness: 1,
                    ),
                    const SizedBox(
                      height: 19,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.black,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.black,
                                ),
                              ),
                              // const SizedBox(
                              //   height: 11,
                              // ),
                              Text(
                                AppLocalizations.of(context)!.call,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
