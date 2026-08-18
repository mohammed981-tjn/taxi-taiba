import 'package:flutter_projects/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';

import '../l10n/app_localizations.dart';

/// What the passenger was charged, and why.
///
/// A single `fareAmount` is not something anyone can check — a disagreement
/// about it is one person's word against another's, with nothing between them.
/// This shows the parts, so the same number can be argued about with reference
/// to something.
///
/// It takes the trip map rather than an id: every caller already holds one, and
/// a receipt that re-fetched would show a row the passenger cannot see when the
/// connection is gone.
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key, required this.trip});

  final Map trip;

  // `final` لا `const`: حقلُ كائنٍ ثابت ليس تعبيراً ثابتاً في Dart وإن
  // كان الكائن نفسه ثابتاً. وليست متغيّرة ساكنة قابلة للتبديل.
  static final Color _navy = TibaPalette.passenger.primary;
  static const String _currency = currencySymbol;

  String _s(String key) => trip[key]?.toString() ?? '';

  /// Trips created before the breakdown was written carry only a total. They
  /// are shown honestly — total alone, with a line saying why — rather than
  /// back-filled with numbers nobody actually charged.
  Map? get _breakdown =>
      trip['fareBreakdown'] is Map ? trip['fareBreakdown'] as Map : null;

  /// `fareAmount` wins over the breakdown's own total.
  ///
  /// The breakdown is written when the trip is requested, from the estimate;
  /// `fareAmount` is what the driver app settles at the end. When they differ,
  /// the amount actually charged is the one the receipt must lead with — the
  /// parts explain it rather than override it.
  String get _total {
    final actual = _s('fareAmount');
    if (actual.isNotEmpty) return actual;

    final b = _breakdown;
    if (b != null && b['total'] != null) return b['total'].toString();
    return '0';
  }

  String _date(BuildContext context) {
    final raw = _s('publishDateTime');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final l = parsed.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}  ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final b = _breakdown;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        title: Text(l.receiptTitle, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  '$_currency $_total',
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.bold, color: _navy),
                ),
                const SizedBox(height: 4),
                Text(_date(context),
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _Section(title: l.receiptRoute, children: [
            _PlaceRow(
              asset: 'assets/initial.png',
              text: _s('pickUpAddress'),
            ),
            const SizedBox(height: 10),
            _PlaceRow(
              asset: 'assets/final.png',
              text: _s('dropOffAddress'),
            ),
          ]),

          const SizedBox(height: 18),

          _Section(
            title: l.receiptFareDetails,
            children: b == null
                ? [
                    _Line(label: l.receiptTotal, value: '$_currency $_total',
                        bold: true),
                    const SizedBox(height: 8),
                    Text(l.receiptNoBreakdown,
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.black45)),
                  ]
                : [
                    _Line(
                        label: l.receiptBaseFare,
                        value: '$_currency ${b['base']}'),
                    _Line(
                      label: '${l.receiptDistance}  ·  ${b['distanceKm']} km',
                      value: '$_currency ${b['distance']}',
                    ),
                    _Line(
                      label: '${l.receiptDuration}  ·  ${b['durationMin']} min',
                      value: '$_currency ${b['duration']}',
                    ),
                    const Divider(height: 22),
                    _Line(
                        label: l.receiptTotal,
                        value: '$_currency $_total',
                        bold: true),
                  ],
          ),

          const SizedBox(height: 18),

          _Section(title: l.receiptDriver, children: [
            _Line(label: l.receiptDriver, value: _s('driverName')),
            if (_s('carDetails').isNotEmpty)
              _Line(label: l.receiptCar, value: _s('carDetails')),
            _Line(label: l.receiptPayment, value: l.receiptPaymentCash),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14.5,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: bold ? TibaPalette.passenger.primary : Colors.black87,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.asset, required this.text});
  final String asset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(asset, height: 16, width: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
