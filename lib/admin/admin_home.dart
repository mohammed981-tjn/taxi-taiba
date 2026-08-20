import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/admin/admin_drivers_page.dart';
import 'package:flutter_projects/admin/admin_map_page.dart';
import 'package:flutter_projects/admin/admin_trips_page.dart';
import 'package:flutter_projects/admin/admin_users_page.dart';

/// هيكل اللوحة.
///
/// ثلاث شاشات فقط، وهي المختارة عمداً: بلا **اعتماد السائقين** لا يوجد نظام
/// نقل بل قائمة أشخاص، وبلا **حظر مستخدم** لا سبيل لإيقاف مسيء، وبلا
/// **متابعة الرحلات** لا تعرف ما يجري في خدمتك الآن. الباقي — التقارير
/// والشكاوى وأكواد الخصم — يُضاف فوق هذه لا قبلها.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    AdminMapPage(),
    AdminDriversPage(),
    AdminUsersPage(),
    AdminTripsPage(),
  ];

  static const List<String> _titles = <String>[
    'الخريطة',
    'السائقون',
    'المستخدمون',
    'الرحلات',
  ];

  @override
  Widget build(BuildContext context) {
    // شريط جانبي على الشاشات العريضة (الويب وسطح المكتب) وشريط سفلي على
    // الجوّال. الملف واحد والهدفان مبنيّان منه، فالتكيّف هنا لا في نسخة ثانية.
    final bool wide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            tooltip: 'خروج',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (int value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('الخريطة'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_taxi_outlined),
                      selectedIcon: Icon(Icons.local_taxi),
                      label: Text('السائقون'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('المستخدمون'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.route_outlined),
                      selectedIcon: Icon(Icons.route),
                      label: Text('الرحلات'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _pages[_index]),
              ],
            )
          : _pages[_index],
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (int value) =>
                  setState(() => _index = value),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'الخريطة',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_taxi_outlined),
                  selectedIcon: Icon(Icons.local_taxi),
                  label: 'السائقون',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'المستخدمون',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route),
                  label: 'الرحلات',
                ),
              ],
            ),
    );
  }
}
