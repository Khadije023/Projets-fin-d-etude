import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pfe/inscription_patient.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfe/page_reset_password.dart';
import 'package:easy_localization/easy_localization.dart';

class Connectionpatient extends StatefulWidget {
  final Function(bool, String) onLogin;

  const Connectionpatient({super.key, required this.onLogin});

  @override
  ConnectionpatientState createState() => ConnectionpatientState();
}

class ConnectionpatientState extends State<Connectionpatient> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? _userPassword;

  //////////react
  // Future<void> openFrontendWithToken() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString('token');

  //   if (token != null) {
  //     final Uri url =
  //         Uri.parse('http://127.0.0.1:3000/?token=$token'); // ton React local
  //     if (await canLaunchUrl(url)) {
  //       await launchUrl(url);
  //     } else {
  //       throw 'Impossible d\'ouvrir $url';
  //     }
  //   } else {
  //     print('Token introuvable');
  //   }
  // }

  // Keeping the original login logic intact
  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });

    final String url = "http://192.168.1.122:8000/api/login/";

    // 🟦 التنسيق قبل الإرسال
    String input = emailController.text.trim();
    String emailToSend;

    if (RegExp(r'^[0-9]{8}$').hasMatch(input)) {
      // إذا فقط 8 أرقام، نضيف +222
      emailToSend = '+222$input';
    } else {
      // في باقي الحالات، نرسل الرقم كما هو
      emailToSend = input;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailToSend,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String name = responseData['name'];
        final String token = responseData['token'];
        final int patientId = responseData['id'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('loggedInPatientId', patientId);
        await prefs.setString('user_password', passwordController.text);
        await prefs.setString('user_contact', emailController.text);
        await prefs.setString('user_name', name);
        _userPassword = passwordController.text;

        widget.onLogin(true, name);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('welcome_message', namedArgs: {'name': name})),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context); // revenir à la page principale
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                tr('error_prefix', namedArgs: {'error': errorData['error']})),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('general_error')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<Map<String, dynamic>> simulateApiCall(String endpoint,
      {Map<String, dynamic>? data}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    if (endpoint.contains('/verify-password')) {
      // Vérifier que le mot de passe fourni correspond au mot de passe stocké
      final bool isCorrect = data?['password'] == _userPassword;
      return {
        'success': isCorrect,
        'message':
            isCorrect ? tr('correct_password') : tr('incorrect_password'),
      };
    }

    // D'autres simulations si besoin...

    return {'success': false, 'message': tr('unsupported_endpoint')};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEBF4FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withAlpha((0.05 * 255).round()),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back,
                            color: Color.fromARGB(255, 232, 26, 26)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/img/PFE logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    tr('welcome'),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 232, 26, 43),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tr('login_subtitle'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildInputLabel(tr('email_phone_label')),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: emailController,
                    hintText: tr('email_phone_hint'),
                    prefixIcon: Icons.person_outline,
                  ),
                  SizedBox(height: 24),
                  _buildInputLabel(tr('password_label')),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: passwordController,
                    hintText: tr('password_hint'),
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PageResetPassword()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        tr('forgot_password'),
                        style: GoogleFonts.poppins(
                          color: Color.fromARGB(255, 232, 26, 26),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildLoginButton(),
                  SizedBox(height: 40),
                  _buildSignUpOption(),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Color(0xFFFF6B6B),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFB22222),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Color(0xFFFF6B6B).withAlpha((0.5 * 255).round()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                tr('login_button'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpOption() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tr('no_account'),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InscriptionPatient(onLogin: widget.onLogin),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              tr('sign_up'),
              style: GoogleFonts.poppins(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
