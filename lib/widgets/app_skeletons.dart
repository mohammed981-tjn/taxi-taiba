import 'package:flutter/material.dart';

/// هياكل تحميل نابضة — بدل الدوّارة المجرّدة.
///
/// منقول من zadgo2 (`lib/widgets/app_skeletons.dart`)، وهو **بلا حزمة**: نبض
/// شفافيّة مكتوب يدوياً، فلا اعتماديّة جديدة تُضاف لأجل تأثير بصريّ.
///
/// والفائدة ليست جمالاً: الدوّارة لا تقول شيئاً عمّا سيأتي، فيبدو الانتظار
/// أطول ممّا هو ثمّ يقفز المحتوى فجأةً في مكانٍ لم يكن محجوزاً له. والهيكل
/// يحجز الشكل، فيصل المحتوى إلى موضعه بلا قفزة.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      );
}

/// صندوق هيكليّ واحد.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// هيكل بطاقة رحلة — أيقونة، وعنوانان، ومبلغ.
///
/// وهو مرسومٌ على شكل البطاقة الحقيقيّة في هذا التطبيق لا على شكل بطاقة
/// zadgo2: هيكلٌ لا يطابق ما سيحلّ محلّه يعيد القفزة التي جاء يمنعها.
class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (BuildContext context, int _) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const SkeletonBox(width: 34, height: 34, radius: 17),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SkeletonBox(height: 13),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        height: 11,
                        width: MediaQuery.of(context).size.width * 0.32,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const SkeletonBox(width: 52, height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
