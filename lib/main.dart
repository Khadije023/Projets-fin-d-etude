import 'package:flutter/material.dart';
import 'package:pfe/premiere_secours.dart';
import 'package:pfe/signaler_urgence.dart';
import 'package:pfe/connectionpatient.dart';
import 'package:pfe/Profil.dart';
import 'package:pfe/dossier_medical.dart';
import 'package:pfe/dashboard_docteur.dart';
import 'package:pfe/carte_patient_page.dart';
import 'package:provider/provider.dart';
import 'services/map_data_service.dart';
import 'package:pfe/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pfe/trousse_medical.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pfe/aide_support.dart';
import 'package:pfe/inscription_Docteur.dart';
import 'package:logging/logging.dart';
import 'package:easy_localization/easy_localization.dart';

final Logger log = Logger('AuthCheck');

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final name = prefs.getString('userName') ?? 'doctor'.tr();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      // Rediriger vers Dashboard Docteur
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardDocteur(name: name)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => InscriptionDocteur(
                  onLogin: (isLoggedIn, token) {},
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: ChangeNotifierProvider(
        create: (context) => MapDataService(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_title'.tr(),
      theme: ThemeData(
        fontFamily: 'Helvetica',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          primary: Colors.pinkAccent,
          secondary: Colors.teal,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      //  هنا تضيف Directionality تلقائي حسب اللغة
      // builder: (context, child) {
      //   return Directionality(
      //     textDirection: Localizations.localeOf(context).languageCode == 'ar'
      //         ? TextDirection.rtl
      //         : TextDirection.ltr,
      //     child: child!,
      //   );
      // },

      home: const SplashScreen(nextScreen: HomePage()),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool isLoggedIn = false;
  String userName = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userName = prefs.getString('userName') ?? '';
    });
  }

  Future<void> _updateLoginState(bool status, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
    await prefs.setString('userName', name);

    setState(() {
      isLoggedIn = status;
      userName = name;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PremiereSecoursPage()),
        );
        break;
      case 2:
        // Discussion or Login
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartePatientPage(),
            ),
          );
        } else {
          _showLoginAlert(context);
        }
        break;
      case 3:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DossierMedicalPage()),
          );
        } else {
          _showLoginAlert(context);
        }
        break;
      case 4:
        if (isLoggedIn) {
          Navigator.push(
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
          Navigator.push(
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

  Widget _buildProfileDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: Colors.redAccent,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              color: Colors.redAccent,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isLoggedIn ? Icons.person : Icons.person_outline,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoggedIn)
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Connectionpatient(onLogin: _updateLoginState),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text('connect'.tr()),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (isLoggedIn)
                      _buildDrawerItem(
                        icon: Icons.person,
                        title: 'profile'.tr(),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilPage(
                                userName: '',
                                userEmail: '',
                                userId: '',
                              ),
                            ),
                          );
                        },
                      ),
                    _buildDrawerItem(
                      icon: Icons.health_and_safety,
                      title: 'firstAid'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PremiereSecoursPage()),
                        );
                      },
                    ),
                    // MODIFIÉ : Couleur pour "Kit Secours" dans le tiroir
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.suitcaseMedical,
                      title: 'kit'.tr(),
                      textColor: Colors
                          .pink, // Couleur rose pour le texte de l'élément du tiroir
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MaTrousseDeSecoursPage()),
                        );
                      },
                    ),
                    if (isLoggedIn)
                      _buildDrawerItem(
                        icon: Icons.folder_special,
                        title: 'medicalRecord'.tr(),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DossierMedicalPage()),
                          );
                        },
                      ),

                    _buildDrawerItem(
                      icon: Icons.help,
                      title: 'helpSupport'.tr(),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AideSupportPage()),
                        );
                      },
                    ),
                    if (isLoggedIn)
                      _buildDrawerItem(
                        icon: Icons.logout,
                        title: 'logout'.tr(),
                        textColor: Colors.redAccent,
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);
                          await prefs.remove('userName');
                          setState(() {
                            isLoggedIn = false;
                            userName = '';
                          });
                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.redAccent,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
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
                Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      endDrawer: _buildProfileDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.redAccent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'app_title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.redAccent.shade700,
                          Colors.redAccent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor:
                          Colors.white.withAlpha((0.1 * 255).round()),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor:
                          Colors.white.withAlpha((0.1 * 255).round()),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 20,
                    child: isLoggedIn
                        ? Text(
                            '${'hello'.tr()}, $userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Text(
                            'welcome'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              //  زر الترجمة (أيقونة الكرة الأرضية)
              IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.language, // أيقونة الكرة الأرضية
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('choose_language'.tr()),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.flag, color: Colors.blue),
                            title: Text('english'.tr()),
                            onTap: () {
                              // تغيير اللغة إلى الإنجليزية
                              context.setLocale(const Locale('en'));
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.flag, color: Colors.blue),
                            title: Text('arabic'.tr()),
                            onTap: () {
                              // تغيير اللغة إلى الإنجليزية
                              context.setLocale(const Locale('ar'));
                              Navigator.of(context).pop();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.flag, color: Colors.blue),
                            title: Text('french'.tr()),
                            onTap: () {
                              // تغيير اللغة إلى الفرنسية
                              context.setLocale(const Locale('fr'));
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                  // هنا تضع كود تغيير اللغة (مثلاً فتح Dialog أو تبديل Locale)
                },
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InscriptionDocteur(
                        onLogin: (isLoggedIn, token) {
                          print('Connecte: $isLoggedIn, token: $token');
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              const SizedBox(width: 10),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildListDelegate([
                // 1. Premiers Secours
                _buildFeatureCard(
                  context,
                  'app_title'.tr(),
                  Icons.health_and_safety,
                  Colors.redAccent,
                  PremiereSecoursPage(),
                  'learnLifeSaving'.tr(),
                ),
                _buildFeatureCard(
                  context,
                  'myFirstAidKit'.tr(),
                  FontAwesomeIcons.suitcaseMedical,
                  Colors.pink,
                  MaTrousseDeSecoursPage(),
                  'manageKit'.tr(),
                ),
                _buildFeatureCard(
                  context,
                  'medicalRecord'.tr(),
                  Icons.folder_special,
                  Colors.teal,
                  isLoggedIn ? DossierMedicalPage() : null,
                  'accessInfo'.tr(),
                  isImportant: true,
                ),
                _buildFeatureCard(
                  context,
                  'reportEmergency'.tr(),
                  Icons.warning_amber,
                  Colors.redAccent,
                  isLoggedIn ? SignalerUrgencePage() : null,
                  'askHelpQuickly'.tr(),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'emergencyServices'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyContact('samu'.tr(), '101', Colors.red),
                  _buildEmergencyContact(
                      'police'.tr(), '117', Colors.blue.shade800),
                  _buildEmergencyContact(
                      'firefighters'.tr(), '118', Colors.orange.shade800),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignalerUrgencePage()),
            );
          } else {
            _showLoginAlert(context);
          }
        },
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: Text('report'.tr(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget? page,
    String subtitle, {
    bool isImportant = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (page == null) {
          _showLoginAlert(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.2 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isImportant
              ? Border.all(color: color, width: 2)
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String service, String number, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((0.2 * 255).round()),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          service,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.phone, color: color),
        onTap: () {
          // Afficher la boîte de dialogue de confirmation
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('confirmCall'.tr()),
                content: Text(
                  'callMessage'.tr(namedArgs: {
                    'service': service,
                    'number': number,
                  }),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('cancel'.tr()),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Fermer la boîte de dialogue
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      final Uri launchUri = Uri.parse('tel:$number');

                      log.info(
                          '--- Démarrage de l\'appel depuis HomePage (via confirmation) ---');
                      log.info(
                          'Tentative d\'appeler $service au numéro: $number');
                      log.info('URI construite: $launchUri');

                      try {
                        await launchUrl(launchUri);
                        log.info('URL lancée avec succès: $launchUri');
                      } catch (e) {
                        log.info('Erreur lors du lancement de l\'appel : $e');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'callFailed'.tr(namedArgs: {
                                'number': number,
                              }),
                            ),
                          ),
                        );
                      }

                      log.info(
                          '--- Fin de l\'appel depuis HomePage (via confirmation) ---');
                    },
                    child: Text(
                      'call'.tr(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
