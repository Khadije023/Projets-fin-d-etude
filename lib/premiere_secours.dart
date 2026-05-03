import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gestes/arret_cardiaque_page.dart';
import 'gestes/etouffement_page.dart';
import 'gestes/brulures_page.dart';
import 'gestes/malaise_cardiaque_page.dart';
import 'gestes/noyade_page.dart';
import 'gestes/fracture_page.dart';
import 'gestes/electrocution_page.dart';
import 'gestes/accident_voie_publique_page.dart';
import 'gestes/inconscience_page.dart';
import 'gestes/saignement_page.dart';
import 'gestes/plaies_page.dart';
import 'package:pfe/dossier_medical.dart';
import 'package:pfe/trousse_medical.dart';
import 'package:pfe/Profil.dart';
import 'package:pfe/connectionpatient.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiereSecoursPage extends StatefulWidget {
  const PremiereSecoursPage({super.key});

  @override
  PremiereSecoursPageState createState() => PremiereSecoursPageState();
}

class PremiereSecoursPageState extends State<PremiereSecoursPage>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  bool isLoggedIn = true;
  String userName = '';
  int _selectedIndex = 1;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: const Offset(0.0, 0.0),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userName = prefs.getString('userName') ?? '';
    });
  }

  void _updateLoginState(bool status, String name) {
    setState(() {
      isLoggedIn = status;
      userName = name;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        break;

      case 2:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaTrousseDeSecoursPage(),
            ),
          );
        } else {
          _showLoginAlert(context);
        }
        break;
      case 3:
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DossierMedicalPage()),
          );
        } else {
          _showLoginAlert(context);
        }
        break;
      case 4:
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilPage(
                userName: '',
                userEmail: '',
                userId: '',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Connectionpatient(onLogin: _updateLoginState),
            ),
          );
        }
        break;
    }
  }

  void _showLoginAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('loginRequired'.tr(),
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('loginMessage'.tr(), style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr(), style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        Connectionpatient(onLogin: _updateLoginState),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('connect'.tr()),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> secoursList = [
    {
      'title': 'choking_title'.tr(),
      'subtitle': 'etouffement_subtitle'.tr(),
      'image': 'assets/img/etouffee.jpg',
      'page': EtouffementPage(),
    },
    {
      'title': 'bleeding_title'.tr(),
      'subtitle': 'saignement_subtitle'.tr(),
      'image': 'assets/img/hemo.jpeg',
      'page': SaignementPage(),
    },
    {
      'title': 'page_title'.tr(),
      'subtitle': 'perte_connaissance_subtitle'.tr(),
      'image': 'assets/img/inco.jpeg',
      'page': InconsciencePage(),
    },
    {
      'title': 'cardiac_arrest.title'.tr(),
      'subtitle': 'arret_cardiaque_subtitle'.tr(),
      'image': 'assets/img/arret-cardiaque.jpg',
      'page': ArretCardiaquePage(),
    },
    {
      'title': 'malaise_title '.tr(),
      'subtitle': 'malaise_subtitle'.tr(),
      'image': 'assets/img/malaise cardiaque.jpeg',
      'page': MalaiseCardiaquePage(),
    },
    {
      'title': 'wounds_title'.tr(),
      'subtitle': 'plaies_subtitle'.tr(),
      'image': 'assets/img/plaies.jpg',
      'page': PlaiesPage(),
    },
    {
      'title': 'burns.page_title'.tr(),
      'subtitle': 'brulures_superficielles_subtitle'.tr(),
      'image': 'assets/img/brulures.jpg',
      'page': BruluresPage(),
    },
    {
      'title': 'noyade_title'.tr(),
      'subtitle': 'noyade_subtitle'.tr(),
      'image': 'assets/img/noyadee.jpg',
      'page': NoyadePage(),
    },
    {
      'title': 'fracture_title'.tr(),
      'subtitle': 'fracture_subtitle'.tr(),
      'image': 'assets/img/fracture.jpg',
      'page': FracturePage(),
    },
    {
      'title': 'electrocution.page_title'.tr(),
      'subtitle': 'electrocution_subtitle'.tr(),
      'image': 'assets/img/elect.jpeg',
      'page': ElectrocutionPage(),
    },
    {
      'title': 'accident_page.title'.tr(),
      'subtitle': 'accident_voie_publique_subtitle'.tr(),
      'image': 'assets/img/choc.jpg',
      'page': AccidentVoiePubliquePage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = secoursList.where((item) {
      final title = item['title'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text('app_title'.tr()),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: [
              FadeTransition(
                opacity: _opacityAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'loadingg'.tr(),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (searchQuery.isEmpty)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'learn_first_aid'.tr(),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              if (searchQuery.isNotEmpty && filteredList.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'no_results'.tr(),
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(height: 16),
              GridView.count(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,

                // 👇 يخلي حجم الكارد يتكيف مع الشاشة
                childAspectRatio:
                    MediaQuery.of(context).size.width > 600 ? 0.9 : 0.75,

                children: filteredList.map((item) {
                  return buildSecoursCard(
                    context,
                    imagePath: item['image'],
                    title: item['title'],
                    subtitle: item['subtitle'],
                    page: item['page'],
                  );
                }).toList(),
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "emergency_call_fab",
        backgroundColor: Colors.red[600],
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('emergency_numbers'.tr()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.local_hospital),
                      title: Text('samu'.tr()),
                      trailing: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:101'));
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.local_fire_department),
                      title: Text('firefighters'.tr()),
                      trailing: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:118'));
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.local_police),
                      title: Text('police'.tr()),
                      trailing: IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () {
                          launchUrl(Uri.parse('tel:190'));
                        },
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('close'.tr()),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.phone),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.health_and_safety),
                label: 'secours'.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'map'.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_special),
                label: 'medicalFolder'.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(isLoggedIn ? Icons.person : Icons.login),
                label: isLoggedIn ? 'Profile'.tr() : 'login'.tr(),
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.redAccent,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget buildSecoursCard(BuildContext context,
      {required String imagePath,
      required String title,
      required String subtitle,
      required Widget page}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double imageSize = screenWidth * 0.26; //  حجم تلقائي

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imagePath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center),
              SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.03, //  خط يتغير حسب الشاشة
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget? page,
    String subtitle,
  ) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Card(
        color: color.withAlpha((0.1 * 255).round()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
              SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
