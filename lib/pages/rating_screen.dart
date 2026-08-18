import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';

import '../l10n/app_localizations.dart';

/// Asked once, immediately after a trip ends.
///
/// This is the only place the platform learns whether a driver should get
/// another passenger. Without it every driver looks identical from the outside,
/// there is nothing to act on when one behaves badly, and nothing to point to
/// when one behaves well — so it is shown rather than buried in a menu, and
/// skipping is one tap so that the ask never blocks the next trip.
class RatingScreen extends StatefulWidget {
  const RatingScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    required this.driverName,
  });

  final String tripId;
  final String driverId;
  final String driverName;

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static final Color _navy = TibaPalette.passenger.primary;

  int _stars = 0;
  final Set<String> _tags = {};
  final TextEditingController _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  /// Which chips to offer depends on the score, because "polite" and "reckless"
  /// are not answers to the same question. Four and up asks what went right;
  /// three and below asks what went wrong.
  List<_Tag> _tagsForScore(AppLocalizations l) => _stars >= 4
      ? [
          _Tag('clean_car', l.tagCleanCar),
          _Tag('safe_driving', l.tagSafeDriving),
          _Tag('polite', l.tagPolite),
          _Tag('on_time', l.tagOnTime),
        ]
      : [
          _Tag('late', l.tagLate),
          _Tag('rude', l.tagRude),
          _Tag('unsafe', l.tagUnsafe),
          _Tag('dirty_car', l.tagDirtyCar),
        ];

  Future<void> _submit() async {
    if (_stars == 0 || _sending) return;
    setState(() => _sending = true);

    final db = FirebaseDatabase.instance.ref();

    try {
      await db.child('tripRequests').child(widget.tripId).update({
        'rating': _stars,
        'ratingTags': _tags.toList(),
        'ratingComment': _comment.text.trim(),
        'ratedAt': DateTime.now().toIso8601String(),
      });

      // A transaction, not a read-then-write: two passengers rating the same
      // driver at once would each read the same total and the second would
      // overwrite the first, quietly losing a rating.
      if (widget.driverId.isNotEmpty && widget.driverId != 'waiting') {
        await db
            .child('drivers')
            .child(widget.driverId)
            .child('ratings')
            .runTransaction((Object? current) {
          final Map<String, dynamic> data = current is Map
              ? Map<String, dynamic>.from(current)
              : <String, dynamic>{};

          final int count = (data['count'] as num?)?.toInt() ?? 0;
          final double sum = (data['sum'] as num?)?.toDouble() ?? 0;

          final int newCount = count + 1;
          final double newSum = sum + _stars;

          return Transaction.success({
            'count': newCount,
            'sum': newSum,
            // Stored as well as derivable, so a list of drivers can be sorted
            // without every row doing arithmetic.
            'average': double.parse((newSum / newCount).toStringAsFixed(2)),
          });
        });
      }

      if (!mounted) return;
      Navigator.pop(context, _stars);
    } catch (error) {
      debugPrint('RatingScreen: submit failed — $error');
      if (!mounted) return;
      setState(() => _sending = false);
      // The trip is over and the fare is settled; a rating that failed to save
      // is not worth trapping anyone on this screen.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tags = _tagsForScore(l);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _navy,
        automaticallyImplyLeading: false,
        title: Text(l.rateTripTitle,
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.pop(context),
            child: Text(l.rateSkip,
                style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 34,
                backgroundColor: _navy.withValues(alpha: 0.08),
                child: const Icon(Icons.person, size: 38, color: _navy),
              ),
              const SizedBox(height: 12),
              Text(
                widget.driverName.isEmpty ? l.receiptDriver : widget.driverName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 4),
              Text(
                l.rateTripSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _stars;
                  return IconButton(
                    iconSize: 40,
                    onPressed: _sending
                        ? null
                        : () => setState(() {
                              _stars = i + 1;
                              // The chips belong to the previous question once
                              // the score crosses the line, so they are dropped
                              // rather than carried onto a different list.
                              _tags.clear();
                            }),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled ? Color(0xFFF5A623) : Colors.black26,
                    ),
                  );
                }),
              ),

              if (_stars > 0) ...[
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) {
                    final on = _tags.contains(t.key);
                    return FilterChip(
                      label: Text(t.label),
                      selected: on,
                      onSelected: _sending
                          ? null
                          : (v) => setState(
                              () => v ? _tags.add(t.key) : _tags.remove(t.key)),
                      selectedColor: _navy.withValues(alpha: 0.12),
                      checkmarkColor: _navy,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _comment,
                  enabled: !_sending,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: l.rateCommentHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: (_stars == 0 || _sending) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l.rateSubmit,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag {
  const _Tag(this.key, this.label);
  final String key;
  final String label;
}
