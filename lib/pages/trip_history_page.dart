import 'package:flutter_projects/widgets/app_skeletons.dart';
import 'package:flutter_projects/currency.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'receipt_page.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  /// رحلات هذا الراكب وحده — بالاستعلام لا بتنزيل الجدول.
  ///
  /// كان `.child("tripRequests")` عارياً: كل رحلة لكل مستخدم في المنصّة تنزل
  /// إلى الهاتف، ثم يُرمى أكثرها في المرشّح أدناه. وهذا خطآن معاً — كلفةٌ
  /// تنمو مع المنصّة كلها لا مع سجلّ صاحبها، **وخصوصيةٌ مفقودة**: عناوين
  /// الغرباء وأسماؤهم وأرقامهم كانت تصل إلى جهاز لا يخصّهم.
  ///
  /// والقاعدة الآن تشترط هذا الشكل بالذات: القراءة مسموحة إن كان الاستعلام
  /// `orderByChild('userID').equalTo(uid)`. أي أنّ القراءة العارية لم تعد
  /// تُرفض بالذوق بل بالقاعدة — ولو أُعيدت لعادت الشاشة بخطأ صلاحية.
  final completedTripRequestOfCurrentUser = FirebaseDatabase.instance
      .ref()
      .child("tripRequests")
      .orderByChild("userID")
      .equalTo(FirebaseAuth.instance.currentUser!.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TaibahPalette.passenger.primary,
        title: Text(
          AppLocalizations.of(context)!.historyTitle,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: completedTripRequestOfCurrentUser.onValue,
        builder: (context, snapshotData) {
          if (snapshotData.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.errorOccurred,
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            );
          }
          // شرطان لا شرط واحد.
          //
          // كانا مدموجين، فكانت الشاشة تقول «لا يوجد سجلّ» **أثناء التحميل** —
          // أي أنّها تكذب على راكبٍ له عشرون رحلة، ثم تصحّح نفسها بعد لحظة.
          // ومن يفتح السجلّ ليتأكّد من رحلةٍ أُلغيت يقرأ الجملة ويخرج.
          if (!snapshotData.hasData) {
            return const TripCardSkeleton();
          }

          if (snapshotData.data!.snapshot.value == null) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noRecordFound,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }
          Map dataTrips = snapshotData.data!.snapshot.value as Map;
          List tripsList = [];
          dataTrips.forEach(
            (key, value) => tripsList.add({"key": key, ...value}),
          );
          
          // الملغاة رحلاتٌ أيضاً.
          //
          // كان المرشّح `status == "ended"` وحدها، فرحلةٌ أُلغيت تختفي من
          // السجلّ كأنّها لم تُطلَب. والراكب الذي أُلغيت عليه رحلة هو أوّل من
          // يفتح السجلّ ليتأكّد ممّا جرى — فيجده فارغاً، ويظنّ أن التطبيق
          // نسيها.
          var filteredTrips = tripsList.where((trip) =>
            (trip['status'] == "ended" || trip['status'] == "cancelled") &&
            trip['userID'] == FirebaseAuth.instance.currentUser!.uid
          ).toList();

          if (filteredTrips.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noRecordFound,
                style: const TextStyle(color: Colors.black),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredTrips.length,
            itemBuilder: ((context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    // The history already holds everything a receipt shows, so
                    // the row opens one instead of being a dead summary the
                    // passenger cannot drill into.
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReceiptPage(trip: filteredTrips[index]),
                        ),
                      ),
                      child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/initial.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  filteredTrips[index]['pickUpAddress'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                money(filteredTrips[index]['fareAmount']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Image.asset(
                                'assets/final.png',
                                height: 16,
                                width: 16,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  filteredTrips[index]['dropOffAddress'].toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      ),
                    ),
                  ),
                );
            }),
          );
        },
      ),
    );
  }
}
