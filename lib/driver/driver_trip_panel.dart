import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/currency.dart';
import 'package:flutter_projects/driver/driver_service.dart';
import 'package:flutter_projects/methods/associate_methods.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// الرحلة من العرض إلى التقييم.
///
/// الترتيب: عرض ← قبول ← وصلت ← بدأت ← انتهت ← تقييم الراكب. وكل انتقال
/// كتابةٌ واحدة في `tripRequests/$tripId/status` يقرأها الراكب فوراً.
class DriverTripPanel extends StatefulWidget {
  const DriverTripPanel({
    super.key,
    required this.tripId,
    required this.profile,
    required this.onAccepting,
    required this.onAcceptFailed,
    required this.onFinished,
    this.position,
  });

  final String tripId;
  final Map<String, Object?> profile;

  /// يُستدعى **قبل** كتابة القبول، لا بعدها — راجع driver_home.dart.
  final VoidCallback onAccepting;

  /// ويُتراجَع عنه إن رفضت القاعدة المطالبة.
  final VoidCallback onAcceptFailed;

  final VoidCallback onFinished;

  /// آخر موقع للسائق — يُكتب مع القبول ويقيس بُعد نقطة الانطلاق.
  final Position? position;

  @override
  State<DriverTripPanel> createState() => _DriverTripPanelState();
}

class _DriverTripPanelState extends State<DriverTripPanel> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: DriverService.trip(widget.tripId).onValue,
      builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final Object? raw = snapshot.data?.snapshot.value;

        if (raw is! Map) {
          // الرحلة اختفت — ألغاها الراكب أو انتقلت إلى سائق آخر.
          return _Gone(onDismiss: widget.onFinished);
        }

        final Map<String, Object?> trip = <String, Object?>{};
        raw.forEach((Object? k, Object? v) {
          if (k is String) trip[k] = v;
        });

        final String status = '${trip['status'] ?? 'new'}';
        final String driverId = '${trip['driverID'] ?? 'waiting'}';

        // سائق آخر سبقنا. القاعدة رفضت مطالبتنا أو لم نطالب أصلاً.
        if (driverId != 'waiting' && driverId != DriverService.uid) {
          return _Gone(onDismiss: widget.onFinished);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: <Widget>[
            _TripCard(
              trip: trip,
              status: status,
              driverAt: widget.position,
            ),
            const SizedBox(height: 14),
            ..._actionsFor(status, trip),
          ],
        );
      },
    );
  }

  List<Widget> _actionsFor(String status, Map<String, Object?> trip) {
    switch (status) {
      case 'new':
        return <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _decline,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('رفض'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : _accept,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('قبول الرحلة'),
                  ),
                ),
              ),
            ],
          ),
        ];

      case 'accepted':
        return <Widget>[
          _navigateButton('التوجّه إلى الراكب', trip['pickUpLatLng']),
          const SizedBox(height: 4),
          _bigButton('وصلتُ إلى الراكب',
              () => _setStatus('arrived'), Icons.location_on),
          const SizedBox(height: 4),
          _cancelButton('إلغاء الرحلة', 'driverCancelled'),
        ];

      case 'arrived':
        return <Widget>[
          _bigButton('بدء الرحلة', () => _setStatus('ontrip'), Icons.play_arrow),
          const SizedBox(height: 4),
          // «الراكب لم يحضر» ليست إلغاءً عادياً: هي الحالة التي يقف فيها
          // السائق عند العنوان بلا أحد، وهي التي تُبنى عليها رسوم الانتظار
          // لاحقاً. فتُسجَّل بسببها لا مدموجةً في إلغاءٍ مجهول.
          _cancelButton('الراكب لم يحضر', 'noShow'),
        ];

      case 'ontrip':
        return <Widget>[
          _navigateButton('التوجّه إلى الوجهة', trip['dropOffLatLng']),
          const SizedBox(height: 4),
          _bigButton('إنهاء الرحلة', () => _end(trip), Icons.flag),
        ];

      case 'ended':
        return <Widget>[
          _RatePassenger(
            tripId: widget.tripId,
            passengerId: '${trip['userID'] ?? ''}',
            passengerName: '${trip['userName'] ?? 'الراكب'}',
            alreadyRated: trip['driverRating'] != null,
            onDone: widget.onFinished,
          ),
        ];

      default:
        return <Widget>[
          _bigButton('إغلاق', widget.onFinished, Icons.close),
        ];
    }
  }

  /// زرٌّ يسلّم الوجهة إلى خرائط Google.
  ///
  /// السائق كان يقرأ عنواناً نصّاً ثم يكتبه بيده في تطبيق آخر وهو خلف المقود.
  Widget _navigateButton(String label, Object? latLng) {
    if (latLng is! Map) return const SizedBox.shrink();

    final double? lat = double.tryParse('${latLng['latitude']}');
    final double? lng = double.tryParse('${latLng['longitude']}');
    if (lat == null || lng == null) return const SizedBox.shrink();

    return OutlinedButton.icon(
      onPressed: () => _TripCard._navigateTo(lat, lng),
      icon: const Icon(Icons.navigation_outlined),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _bigButton(String label, VoidCallback onTap, IconData icon) {
    return FilledButton.icon(
      onPressed: _busy ? null : onTap,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept() => _guard(() async {
        final Object? car = widget.profile['car_details'];
        final String carText = car is Map
            ? <String>[
                '${car['model'] ?? ''}',
                '${car['number'] ?? ''}',
                '${car['color'] ?? ''}',
              ].where((String s) => s.trim().isNotEmpty).join(' · ')
            : '';

        widget.onAccepting();

        try {
          await DriverService.acceptTrip(
            tripId: widget.tripId,
            name: '${widget.profile['name'] ?? ''}',
            phone: '${widget.profile['phone'] ?? ''}',
            carDetails: carText,
            position: widget.position,
          );
        } catch (error) {
          // سبقنا سائق آخر فرفضت القاعدة المطالبة. يُخفض العلم كي لا يبقى
          // السائق محبوساً في رحلة ليست له.
          widget.onAcceptFailed();
          rethrow;
        }
      });

  /// إلغاء بعد القبول.
  ///
  /// لم يكن لأيّ من الطرفين سبيل إلى الإلغاء بعد القبول: عطلٌ في السيّارة أو
  /// راكبٌ لا يظهر يترك الرحلة معلّقةً إلى الأبد، وليس أمام السائق إلا أن
  /// يضغط «إنهاء» فتُحسب رحلةً تمّت وتدخل الأرباح.
  Future<void> _cancel(String reason) => _guard(() async {
        await DriverService.cancelTrip(widget.tripId, reason: reason);
        widget.onFinished();
      });

  Widget _cancelButton(String label, String reason) => TextButton.icon(
        onPressed: _busy ? null : () => _confirmCancel(label, reason),
        icon: const Icon(Icons.close, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
      );

  void _confirmCancel(String label, String reason) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(label),
        content: const Text(
          'سيُبلَّغ الراكب فوراً، وتُسجَّل الرحلة ملغاةً في سجلّك.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(context);
              _cancel(reason);
            },
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _decline() => _guard(() async {
        await DriverService.declineTrip();
        widget.onFinished();
      });

  Future<void> _setStatus(String status) =>
      _guard(() => DriverService.setTripStatus(widget.tripId, status));

  /// الأجرة من تفصيلها المكتوب وقت الطلب، لا من حساب جديد.
  ///
  /// `fareBreakdown` كُتب في الرحلة لحظة طلبها، من نفس الاتجاهات التي سُعِّرت
  /// عليها. فاستعماله هنا يعني أن ما يدفعه الراكب هو ما عُرض عليه — ولو
  /// حُسبت الأجرة الآن من جديد لاختلفت مع تغيّر حركة المرور، وهو ما لا يقبله
  /// أحد في نهاية رحلة.
  Future<void> _end(Map<String, Object?> trip) => _guard(() async {
        double fare = 0;

        final Object? breakdown = trip['fareBreakdown'];
        if (breakdown is Map) {
          fare = double.tryParse('${breakdown['total']}') ?? 0;
        }

        if (fare <= 0) {
          // رحلة قديمة بلا تفصيل — لا تُنهَ بصفر.
          fare = AssociateMethods.fallbackFare;
        }

        await DriverService.endTrip(widget.tripId, fare);
      });
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.status,
    this.driverAt,
  });

  final Map<String, Object?> trip;
  final String status;

  /// موقع السائق الآن — به يُقاس بُعد نقطة الانطلاق.
  final Position? driverAt;

  static const Map<String, String> _label = <String, String>{
    'new': 'طلب جديد',
    'accepted': 'في الطريق إلى الراكب',
    'arrived': 'وصلتَ — بانتظار الراكب',
    'ontrip': 'الرحلة جارية',
    'ended': 'انتهت',
  };

  @override
  Widget build(BuildContext context) {
    final Object? breakdown = trip['fareBreakdown'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _label[status] ?? status,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 22),
            _row(Icons.person_outline, '${trip['userName'] ?? '—'}'),
            _row(Icons.phone_outlined, '${trip['userPhone'] ?? '—'}'),
            const SizedBox(height: 10),
            _row(Icons.trip_origin, '${trip['pickUpAddress'] ?? '—'}'),
            _row(Icons.location_on_outlined, '${trip['dropOffAddress'] ?? '—'}'),

            // كم يبعد الراكب عنّي؟
            //
            // السؤال الأوّل الذي يسأله سائق أمام عرضٍ جديد، ولم تكن الشاشة
            // تجيبه: عنوانان نصّاً، والمسافة المعروضة تحتهما هي طول **الرحلة**
            // لا بُعد نقطة الانطلاق — وهو ما يُقرأ خطأً فيُقبَل عرضٌ بعيد
            // ويُرفض قريب.
            //
            // ويُحسب هنا بالإحداثيّات الموجودة في العقدة أصلاً، بلا نداء
            // Directions لكلّ عرض — نداءٌ مدفوع لسؤالٍ تكفيه هندسةٌ بسيطة.
            if (_pickupDistanceText != null)
              _row(Icons.straighten, _pickupDistanceText!),
            if (breakdown is Map) ...<Widget>[
              const Divider(height: 22),
              Text(
                '${breakdown['distanceKm']} كم · '
                '${breakdown['durationMin']} دقيقة',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              // رقمان لا رقم واحد.
              //
              // السائق يقبض الأجرة كاملةً نقداً من الراكب، وفيها عمولة
              // المنصّة. فعرضُ الإجمالي وحده تحت كلمة «الأجرة» يجعله يقرأ
              // نصيبه أكبر ممّا هو — ويكتشف الفرق يوم المحاسبة.
              Text(
                'يُحصَّل من الراكب: ${money(breakdown['total'])}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'لك: ${money(_driverShare(breakdown))}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// نصيب السائق من هذه الرحلة — الإجمالي ناقص عمولة المنصّة.
  ///
  /// والعمولة تُقرأ من الرحلة لا من ثابتٍ في الشيفرة، فرحلةٌ سُعِّرت قبل فرض
  /// العمولة لا تُخصم منها.
  static String _driverShare(Map breakdown) {
    final double total = double.tryParse('${breakdown['total']}') ?? 0;
    final double fee = double.tryParse('${breakdown['fee']}') ?? 0;
    return (total - fee).toStringAsFixed(1);
  }

  /// بُعد نقطة الانطلاق عن السائق.
  String? get _pickupDistanceText {
    final Position? me = driverAt;
    if (me == null) return null;

    final Object? pickUp = trip['pickUpLatLng'];
    if (pickUp is! Map) return null;

    final double? lat = double.tryParse('${pickUp['latitude']}');
    final double? lng = double.tryParse('${pickUp['longitude']}');
    if (lat == null || lng == null) return null;

    final double metres = Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      lat,
      lng,
    );

    return metres < 1000
        ? 'يبعد عنك ${metres.round()} م'
        : 'يبعد عنك ${(metres / 1000).toStringAsFixed(1)} كم';
  }

  /// فتح الملاحة إلى نقطة الانطلاق أو الوجهة.
  ///
  /// رابط `https` لا مخطّط `google.navigation:` — الأوّل يسمح به بيان
  /// أندرويد أصلاً، والثاني يحتاج إعلاناً صريحاً وقد لا يُوجَد له تطبيق.
  static Future<void> _navigateTo(double lat, double lng) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // لا شيء يُفعَل: السائق يرى العنوان نصّاً على أيّ حال.
    }
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// تقييم الراكب — النصف المفقود من التقييم المتبادل.
class _RatePassenger extends StatefulWidget {
  const _RatePassenger({
    required this.tripId,
    required this.passengerId,
    required this.passengerName,
    required this.alreadyRated,
    required this.onDone,
  });

  final String tripId;
  final String passengerId;
  final String passengerName;
  final bool alreadyRated;
  final VoidCallback onDone;

  @override
  State<_RatePassenger> createState() => _RatePassengerState();
}

class _RatePassengerState extends State<_RatePassenger> {
  int _stars = 0;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (widget.alreadyRated) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              const Icon(Icons.check_circle_outline,
                  size: 44, color: Colors.green),
              const SizedBox(height: 10),
              const Text('انتهت الرحلة وسُجِّل تقييمك.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onDone,
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              'كيف كان ${widget.passengerName}؟',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(5, (int index) {
                final int star = index + 1;
                return IconButton(
                  onPressed: _busy ? null : () => setState(() => _stars = star),
                  icon: Icon(
                    star <= _stars ? Icons.star : Icons.star_border,
                    size: 34,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : widget.onDone,
                    child: const Text('تخطٍّ'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: (_stars == 0 || _busy) ? null : _submit,
                    child: const Text('إرسال'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _busy = true);

    try {
      await DriverService.ratePassenger(
        tripId: widget.tripId,
        passengerId: widget.passengerId,
        stars: _stars,
      );
    } catch (error) {
      // الرحلة انتهت والأجرة سُوّيت؛ تقييمٌ لم يُحفظ لا يستحقّ حبس السائق هنا.
      debugPrint('ratePassenger failed — $error');
    }

    if (mounted) widget.onDone();
  }
}

class _Gone extends StatelessWidget {
  const _Gone({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.timer_off_outlined, size: 52, color: Colors.black38),
            const SizedBox(height: 14),
            const Text(
              'لم تعد الرحلة متاحة',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ألغاها الراكب أو قبلها سائق آخر.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onDismiss, child: const Text('حسناً')),
          ],
        ),
      ),
    );
  }
}
