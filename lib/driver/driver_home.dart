import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/driver/driver_earnings_page.dart';
import 'package:flutter_projects/driver/driver_service.dart';
import 'package:flutter_projects/driver/driver_trip_panel.dart';
import 'package:flutter_projects/widgets/taibah_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// شاشة السائق.
///
/// حالتان لا أكثر: متصل وغير متصل. وبينهما رحلة إن وُجدت.
class DriverHome extends StatefulWidget {
  const DriverHome({super.key, required this.profile});

  final Map<String, Object?> profile;

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _online = false;
  bool _busy = false;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DatabaseEvent>? _tripOfferSubscription;

  /// معرّف الرحلة المعروضة أو الجارية.
  String? _tripId;

  /// آخر موقع — يُعرض ويُبثّ.
  Position? _position;

  @override
  void initState() {
    super.initState();
    _listenForOffers();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tripOfferSubscription?.cancel();
    super.dispose();
  }

  /* ── الطلبات الواردة ───────────────────────────────────────────────── */

  /// الراكب يكتب معرّف الرحلة في `drivers/$uid/newTripStatus`.
  ///
  /// وهذه هي القناة الوحيدة التي يملكها الراكب إلى السائق، والقاعدة تسمح بها
  /// صراحةً: `newTripStatus` وحدها مفتوحة لأي مستخدم مسجَّل، وما عداها في
  /// ملفّ السائق مغلق عليه.
  void _listenForOffers() {
    _tripOfferSubscription =
        DriverService.me.child('newTripStatus').onValue.listen(
      (DatabaseEvent event) {
        final String value = '${event.snapshot.value ?? 'idle'}';

        if (value == 'idle' || value.isEmpty) {
          // لا تمسح رحلةً جارية: `idle` تُكتب أيضاً لحظة القبول.
          if (_tripId != null && !_tripStarted) {
            setState(() => _tripId = null);
          }
          return;
        }

        if (!mounted) return;
        setState(() {
          _tripId = value;
          _tripStarted = false;
        });
      },
    );
  }

  /// تُرفع حين يُقبل الطلب، فلا يمحو `idle` الرحلةَ الجارية.
  bool _tripStarted = false;

  /* ── الاتصال ───────────────────────────────────────────────────────── */

  Future<void> _toggleOnline(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      if (value) {
        await _goOnline();
      } else {
        await _goOffline();
      }
    } catch (error) {
      _say('تعذّر: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goOnline() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _say('بلا صلاحية الموقع لا يمكن الاتصال — موقعك هو ما يراه الراكب.');
      return;
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );

    // يُسجَّل قبل أول كتابة: لو مات التطبيق بعدها مباشرةً، يمحو الخادمُ
    // السائقَ من القائمة بدل أن يبقى ظاهراً لا يجيب.
    await DriverService.clearOnDisconnect();
    await DriverService.goOnline(position);

    // عشرون متراً لا كل متر: تحديثٌ لكل خطوة يكتب في القاعدة عشرات المرات في
    // الدقيقة ويُحاسَب عليه — وهو نفس نمط الكلفة الذي أُصلح في تطبيق الراكب،
    // من الطرف الآخر.
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 20,
      ),
    ).listen((Position p) {
      _position = p;
      DriverService.publishLocation(p);
    });

    if (!mounted) return;
    setState(() {
      _online = true;
      _position = position;
    });
  }

  Future<void> _goOffline() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await DriverService.goOffline();

    if (!mounted) return;
    setState(() => _online = false);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /* ── البناء ────────────────────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final Object? car = widget.profile['car_details'];
    final String carText = car is Map
        ? '${car['model'] ?? ''} · ${car['number'] ?? ''}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.profile['name'] ?? 'السائق'}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'الأرباح',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DriverEarningsPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'خروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (_online) await _goOffline();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _StatusCard(
            online: _online,
            busy: _busy,
            carText: carText,
            position: _position,
            onChanged: _toggleOnline,
          ),
          Expanded(
            child: _tripId == null
                ? _Idle(online: _online, position: _position)
                : DriverTripPanel(
                    tripId: _tripId!,
                    profile: widget.profile,
                    onAccepted: () => setState(() => _tripStarted = true),
                    onFinished: () => setState(() {
                      _tripId = null;
                      _tripStarted = false;
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.online,
    required this.busy,
    required this.carText,
    required this.position,
    required this.onChanged,
  });

  final bool online;
  final bool busy;
  final String carText;
  final Position? position;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    online ? 'متصل' : 'غير متصل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: online ? Colors.green : Colors.black54,
                    ),
                  ),
                  if (carText.isNotEmpty)
                    Text(
                      carText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  if (online && position != null)
                    Text(
                      '${position!.latitude.toStringAsFixed(4)}, '
                      '${position!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(value: online, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// الانتظار — على خريطة لا على فراغ.
///
/// كانت الشاشة بين الطلبات مساحةً بيضاء فيها سطران. وهي الشاشة التي يقضي
/// السائق أمامها أطول وقته، ولا تقول له شيئاً يحتاجه: أين هو، وأين يقف، وهل
/// موقعه الذي تراه الخدمة هو موقعه فعلاً.
///
/// والسؤال الأخير هو الجوهر. إحداثيّتان مكتوبتان بالأرقام لا تُقرآن — أمّا
/// دبّوسٌ في الحيّ الخطأ فيُرى فوراً. فالخريطة هنا ليست زينة بل أداة تحقّق:
/// السائق أوّل من يكتشف أنّ موقعه غلط، قبل أن يُرسَل إليه راكب من حيّ آخر.
class _Idle extends StatefulWidget {
  const _Idle({required this.online, required this.position});

  final bool online;
  final Position? position;

  @override
  State<_Idle> createState() => _IdleState();
}

class _IdleState extends State<_Idle> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant _Idle oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Position? now = widget.position;
    if (now == null || _controller == null) return;

    // أوّل موقع يستدعي قفزةً إلى مكانه؛ وما بعده تتبُّعٌ ناعم. ولولا الشرط
    // لعادت الكاميرا إلى السائق كلّما تحرّك عشرين متراً، فلا يستطيع أن ينظر
    // إلى شارعٍ مجاور.
    if (oldWidget.position == null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(now.latitude, now.longitude),
          15.5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Position? at = widget.position;

    final Set<Marker> markers = <Marker>{
      if (at != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(at.latitude, at.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'موقعك كما تراه الخدمة'),
        ),
    };

    return Stack(
      children: <Widget>[
        TaibahMap(
          initial: at == null
              ? null
              : CameraPosition(
                  target: LatLng(at.latitude, at.longitude),
                  zoom: 15.5,
                ),
          markers: markers,
          myLocation: widget.online,
          onMapCreated: (GoogleMapController c) => _controller = c,
          padding: const EdgeInsets.only(bottom: 96),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _IdleBanner(online: widget.online),
        ),
      ],
    );
  }
}

class _IdleBanner extends StatelessWidget {
  const _IdleBanner({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(
          online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
          size: 32,
          color: online ? Colors.green : Colors.black26,
        ),
        title: Text(
          online ? 'بانتظار طلب' : 'أنت غير متصل',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          online
              ? 'موقعك يُحدَّث تلقائياً. أبقِ الشاشة مفتوحة لتصلك الطلبات.'
              : 'لن تصلك طلبات ولن يراك أحد حتى تتصل.',
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
