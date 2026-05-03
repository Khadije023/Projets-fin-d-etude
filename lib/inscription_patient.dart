import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'connectionpatient.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InscriptionPatient extends StatefulWidget {
  final Function(bool, String) onLogin;
  const InscriptionPatient({super.key, required this.onLogin});

  @override
  _InscriptionPatientState createState() => _InscriptionPatientState();
}

class _InscriptionPatientState extends State<InscriptionPatient> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  String selectedOption = 'email'; // Choix entre email ou téléphone
  bool isLoading = false;
  bool _obscurePassword = true;
  String? passwordError;
  String? identifierError;
  String? _userPassword;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    identifierController.addListener(_validateIdentifier);
  }

  @override
  void dispose() {
    passwordController.removeListener(_validatePassword);
    identifierController.removeListener(_validateIdentifier);
    nameController.dispose();
    identifierController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      if (password.isEmpty) {
        passwordError = null;
      } else if (password.length != 4) {
        passwordError = "Le mot de passe doit contenir exactement 4 caractères";
      } else {
        passwordError = null;
      }
    });
  }

  void _validateIdentifier() {
    final identifier = identifierController.text;
    setState(() {
      if (identifier.isEmpty) {
        identifierError = null;
        return;
      }

      if (selectedOption == 'email') {
        if (!identifier.endsWith('@gmail.com')) {
          identifierError = "L'email doit se terminer par @gmail.com";
        } else {
          identifierError = null;
        }
      } else {
        if (identifier.length < 8) {
          identifierError = "Le numéro doit contenir exactement 8 chiffres";
        } else if (identifier.length > 8) {
          identifierError = "Le numéro ne peut pas dépasser 8 chiffres";
        } else if (!RegExp(r'^[0-9]+$').hasMatch(identifier)) {
          identifierError = "Le numéro doit contenir uniquement des chiffres";
        } else if (!RegExp(r'^[234]').hasMatch(identifier)) {
          identifierError = "Le numéro doit commencer par 2, 3 ou 4";
        } else {
          identifierError = null;
        }
      }
    });
  }

  bool _isPasswordValid() {
    final password = passwordController.text;
    return password.length == 4;
  }

  bool _isIdentifierValid() {
    final identifier = identifierController.text;

    if (identifier.isEmpty) {
      return false;
    }

    if (selectedOption == 'email') {
      return identifier.endsWith('@gmail.com');
    } else {
      return identifier.length == 8 &&
          RegExp(r'^[0-9]+$').hasMatch(identifier) &&
          RegExp(r'^[234]').hasMatch(identifier);
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('+222')) {
      return phone;
    }

    String cleanPhone = phone.startsWith('+') ? phone.substring(1) : phone;

    return '+222$cleanPhone';
  }

  String _getFormattedIdentifier() {
    if (selectedOption == 'phone') {
      return _formatPhoneNumber(identifierController.text);
    } else {
      return identifierController.text;
    }
  }

  Future<void> sendVerificationCode() async {
    if (!_isPasswordValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Le mot de passe doit contenir exactement 4 caractères"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isIdentifierValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedOption == 'email'
              ? "L'email doit se terminer par @gmail.com"
              : "Le numéro doit contenir 8 chiffres et commencer par 2, 3 ou 4"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final String url = 'http://192.168.1.122:8000/api/send-verification-code/';
    try {
      final formattedIdentifier = _getFormattedIdentifier();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': formattedIdentifier,
          'method': selectedOption,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          builder: (_) => _buildCodeDialog(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'envoi du code."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur s'est produite lors de l'envoi du code."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> simulateApiCall(String endpoint,
      {Map<String, dynamic>? data}) async {
    await Future.delayed(const Duration(seconds: 1));

    if (endpoint.contains('/verify-password')) {
      final bool isCorrect = data?['password'] == _userPassword;
      return {
        'success': isCorrect,
        'message':
            isCorrect ? 'Mot de passe correct' : 'Mot de passe incorrect',
      };
    }

    return {'success': false, 'message': 'Endpoint non supporté'};
  }

  Future<void> verifyCode() async {
    setState(() {
      isLoading = true;
    });

    final String url = 'http://192.168.1.122:8000/api/verify-code/';
    try {
      final formattedIdentifier = _getFormattedIdentifier();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': formattedIdentifier,
          'code': codeController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        await registerUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Code incorrect."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur s'est produite lors de la vérification."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    final String url = "http://192.168.1.122:8000/api/patients/";

    if (!_isIdentifierValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedOption == 'email'
              ? "L'email doit se terminer par @gmail.com"
              : "Le numéro doit contenir 8 chiffres et commencer par 2, 3 ou 4"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (!_isPasswordValid() || !_isPasswordValid()) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Le mot de passe doit contenir exactement 4 caractères."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final formattedIdentifier = _getFormattedIdentifier();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'email': selectedOption == 'email' ? formattedIdentifier : '',
          'phone': selectedOption == 'phone' ? formattedIdentifier : '',
          'password': passwordController.text,
        }),
      );
      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];
        final int patientId = responseData['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_password', passwordController.text);
        await prefs.setString('user_contact', formattedIdentifier);
        await prefs.setString('user_name', nameController.text);
        _userPassword = passwordController.text;
        await prefs.setString('authToken', token);
        await prefs.setInt('loggedInPatientId', patientId);
        widget.onLogin(true, nameController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Inscription réussie!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Connectionpatient(onLogin: widget.onLogin)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'inscription."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Une erreur s'est produite."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildCodeDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        "Vérification",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 232, 26, 84),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Nous avons envoyé un code de vérification à votre ${selectedOption == 'email' ? 'adresse email' : 'numéro de téléphone'}.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              labelText: "Code de vérification",
              labelStyle: GoogleFonts.poppins(color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 2),
              ),
              prefixIcon: Icon(Icons.security, color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            "Annuler",
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await verifyCode();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(
            "Vérifier",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
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
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Color(0xFFFF6B6B)),
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
                            color: Colors.black.withOpacity(0.1),
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
                  SizedBox(height: 30),
                  Text(
                    "Créer un compte",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Rejoignez-nous pour accéder à nos services",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildInputLabel("Nom complet"),
                  SizedBox(height: 8),
                  _buildTextField(
                    controller: nameController,
                    hintText: "Entrez votre nom complet",
                    prefixIcon: Icons.person_outline,
                  ),
                  SizedBox(height: 24),
                  _buildInputLabel("Méthode de contact"),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedOption,
                        icon: Icon(Icons.arrow_drop_down,
                            color: Color(0xFFFF6B6B)),
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'email',
                            child: Row(
                              children: [
                                Icon(Icons.email_outlined,
                                    color: Color(0xFFFF6B6B), size: 20),
                                SizedBox(width: 12),
                                Text('Par Email'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'phone',
                            child: Row(
                              children: [
                                Icon(Icons.phone_outlined,
                                    color: Color(0xFFFF6B6B), size: 20),
                                SizedBox(width: 12),
                                Text('Par Téléphone'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value!;
                            identifierController.clear();
                            identifierError = null;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      _buildInputLabel(selectedOption == 'email'
                          ? "Adresse email"
                          : "Numéro de téléphone"),
                      SizedBox(width: 8),
                      Text(
                        selectedOption == 'email'
                            ? "(@gmail.com)"
                            : "(8 chiffres, commence par 2, 3 ou 4)",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildIdentifierField(),
                  if (identifierError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        identifierError!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      _buildInputLabel("Mot de passe"),
                      SizedBox(width: 8),
                      Text(
                        "(4 caractères)",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildPasswordField(),
                  if (passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        passwordError!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : sendVerificationCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: Color(0xFFFF6B6B).withOpacity(0.5),
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
                              "S'inscrire",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vous avez déjà un compte ?",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Connectionpatient(onLogin: widget.onLogin),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Se connecter",
                            style: GoogleFonts.poppins(
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifierField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: identifierController,
        keyboardType: selectedOption == 'email'
            ? TextInputType.emailAddress
            : TextInputType.number,
        maxLength:
            selectedOption == 'phone' ? 8 : null, // Limit phone to 8 digits
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.black87,
        ),
        inputFormatters: selectedOption == 'phone'
            ? [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return newValue;
                  }

                  String firstChar = newValue.text[0];
                  if (firstChar != '2' &&
                      firstChar != '3' &&
                      firstChar != '4') {
                    return oldValue;
                  }

                  if (newValue.text.length > 8) {
                    return oldValue;
                  }

                  return newValue;
                }),
              ]
            : null,
        decoration: InputDecoration(
          hintText: selectedOption == 'email'
              ? "exemple@gmail.com"
              : "8 chiffres (commence par 2, 3 ou 4)",
          hintStyle: GoogleFonts.poppins(
            color: Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            selectedOption == 'email'
                ? Icons.email_outlined
                : Icons.phone_outlined,
            color: Color(0xFFFF6B6B),
            size: 20,
          ),
          prefixText: selectedOption == 'phone' ? "+222 " : null,
          prefixStyle: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: "",
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: passwordController,
        obscureText: _obscurePassword,
        keyboardType: TextInputType.visiblePassword,
        maxLength: 4,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Entrez 4 caractères",
          hintStyle: GoogleFonts.poppins(
            color: Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Color(0xFFFF6B6B),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: "", // Hide the character counter
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
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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
}
