// lib/main_navigation_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/map_data_service.dart';
import 'full_screen_map_page.dart';
import 'mes_ambulances_page.dart';
import 'hopitaux_page.dart';
import 'historique_page.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  MainNavigationScaffoldState createState() => MainNavigationScaffoldState();
}

class MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final mapDataService = Provider.of<MapDataService>(context, listen: false);

    _pages = <Widget>[
      FullScreenMapPage(
        key: const PageStorageKey('accueilMap'),
        ambulanceTypeColors: mapDataService.ambulanceTypeColors,
        ambulanceTypeIcons: mapDataService.ambulanceTypeIcons,
      ),
      MesAmbulancesPage(key: const PageStorageKey('mesAmbulances')),
      HopitauxPage(key: const PageStorageKey('hopitaux')),
      HistoriquePage(key: const PageStorageKey('historique')),
    ];
  }

  void _onItemTapped(int index, MapDataService service) {
    service.setCurrentMainScreenTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final mapDataService = Provider.of<MapDataService>(context);
    final selectedIndex = mapDataService.currentMainScrenTabIndex;
    print("DEBUG MainNavigationScaffold build: selectedIndex = $selectedIndex");
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_filled_outlined),
              label: 'Mes Ambulances'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined), label: 'Hôpitaux'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined), label: 'Historique'),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: Colors.red.shade800,
        unselectedItemColor: Colors.grey.shade700,
        onTap: (index) => _onItemTapped(index, mapDataService),
      ),
    );
  }
}
