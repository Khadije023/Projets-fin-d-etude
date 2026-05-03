import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_docteur.dart';
import 'Docteur.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InscriptionDocteur extends StatefulWidget {
  final Function(bool, String) onLogin;

  const InscriptionDocteur({super.key, required this.onLogin});

  @override
  InscriptionDocteurState createState() => InscriptionDocteurState();
}

class InscriptionDocteurState extends State<InscriptionDocteur>
    with TickerProviderStateMixin {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController specialiteController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeSecretController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCode = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> inscrireDocteur() async {
    setState(() => isLoading = true);

    final String url = "http://192.168.1.122:8000/api/register-docteur/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nomController.text,
          'email': emailController.text,
          'specialite': specialiteController.text,
          'phone': phoneController.text,
          'password': passwordController.text,
          'code_secret': codeSecretController.text,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userName', data['name']);
        widget.onLogin(true, data['name']);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Bienvenue Dr. ${data['name']} !"),
              ],
            ),
            backgroundColor: Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardDocteur(name: data['name'])),
          (Route<dynamic> route) => false,
        );
      } else {
        final error = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text("Erreur : ${error['error']}")),
              ],
            ),
            backgroundColor: Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Text("Erreur de connexion au serveur."),
            ],
          ),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.8,
            colors: [
              Color(0xFFFF7F7F),
              Color(0xFFFF4C4C),
              Color(0xFFFF9999),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Row(
                          children: [
                            _buildBackButton(),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFB6C1).withAlpha(
                                    (0.2 * 255).round()), // Rose pâle
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Color(0xFFFFB6C1)
                                        .withAlpha((0.3 * 255).round())),
                              ),
                              child: Text(
                                "Étape 1/1",
                                style: GoogleFonts.inter(
                                  color: Color(0xFFFFB6C1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFFFF5F5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF8B0000)
                                    .withAlpha((0.3 * 255).round()),
                                blurRadius: 30,
                                offset: Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildPulsingIcon(),
                                SizedBox(height: 32),

                                Text(
                                  "Rejoignez-nous",
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B0000),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Créez votre profil médical professionnel",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Color(0xFF696969),
                                    fontWeight: FontWeight.w400,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 40),

                                // Form fields
                                _buildModernTextField(
                                  controller: nomController,
                                  label: "Nom complet",
                                  hintText: "Dr. Ahmed Amar",
                                  icon: Icons.person_outline_rounded,
                                ),
                                SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: emailController,
                                  label: "Email professionnel",
                                  hintText: "Ahmed.Amar@hopital.mr",
                                  icon: Icons.email_outlined,
                                ),
                                SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: specialiteController,
                                  label: "Spécialité",
                                  hintText: "Cardiologie, Neurologie...",
                                  icon: Icons.medical_services_outlined,
                                ),
                                SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: phoneController,
                                  label: "Téléphone",
                                  hintText: "+222 36123456 ",
                                  icon: Icons.phone_outlined,
                                ),
                                SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: passwordController,
                                  label: "Mot de passe",
                                  hintText: "••••••••",
                                  icon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  isObscure: _obscurePassword,
                                  onToggle: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                SizedBox(height: 20),

                                _buildModernTextField(
                                  controller: codeSecretController,
                                  label: "Code d'autorisation",
                                  hintText: "Code médical secret",
                                  icon: Icons.security_outlined,
                                  isPassword: true,
                                  isObscure: _obscureCode,
                                  onToggle: () => setState(
                                      () => _obscureCode = !_obscureCode),
                                ),
                                SizedBox(height: 40),

                                _buildSubmitButton(),
                                SizedBox(height: 24),

                                _buildLoginLink(),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCard(int index) {
    final positions = [
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.bottomRight,
      Alignment.topCenter,
      Alignment.centerRight,
      Alignment.bottomLeft,
    ];

    return Positioned.fill(
      child: Align(
        alignment: positions[index],
        child: Container(
          margin: EdgeInsets.all(20 + (index * 10).toDouble()),
          width: 60 + (index * 15).toDouble(),
          height: 60 + (index * 15).toDouble(),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB6C1).withValues(
              alpha: ((0.05 + index * 0.01).clamp(0.0, 1.0) * 255).toDouble(),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFFFB6C1).withAlpha((0.15 * 255).round()),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(0xFFFFB6C1).withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Color(0xFFFFB6C1).withAlpha((0.3 * 255).round())),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B0000).withAlpha((0.2 * 255).round()),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFFFFB6C1),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPulsingIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF3D3D),
            Color(0xFFEA2C2C),
            Color(0xFFD32F2F),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFDC143C).withAlpha((0.4 * 255).round()),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/img/PFE logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B0000),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFF8F8),
                Color(0xFFFFFAFA),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFFFFB6C1).withAlpha((0.4 * 255).round()),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFDC143C).withAlpha((0.08 * 255).round()),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Color(0xFF2F1B14),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                color: Color(0xFF696969).withAlpha((0.7 * 255).round()),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFDC143C).withAlpha((0.1 * 255).round()),
                      Color(0xFFFFB6C1).withAlpha((0.2 * 255).round()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFFDC143C),
                  size: 20,
                ),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isObscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Color(0xFFDC143C),
                        size: 20,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF3D3D),
            Color(0xFFEA2C2C),
            Color(0xFFD32F2F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withAlpha((0.4 * 255).round()),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : inscrireDocteur,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Créer mon compte",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CnxDocteur(
              onLogin: (bool isLoggedIn, String name) {},
            ),
          ),
        );
      },
      child: RichText(
        text: TextSpan(
          text: "Vous avez déjà un compte ? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Color(0xFF696969),
            fontWeight: FontWeight.w400,
          ),
          children: [
            TextSpan(
              text: "Se connecter",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Color(0xFFDC143C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
