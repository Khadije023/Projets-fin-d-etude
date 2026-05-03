import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class ResetDocteurPasswordPage extends StatefulWidget {
  const ResetDocteurPasswordPage({super.key});

  @override
  _ResetDocteurPasswordPageState createState() =>
      _ResetDocteurPasswordPageState();
}

class _ResetDocteurPasswordPageState extends State<ResetDocteurPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final emailOrPhoneController = TextEditingController();
  final codeSecretController = TextEditingController();
  final newNameController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showPasswordFields = false;
  bool isLoading = false;
  String? errorMessage;
  bool showPassword = false;
  bool showConfirmPassword = false;

  bool isValidPassword(String password) {
    final regex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> verifyDoctorIdentity() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('http://192.168.1.122:8000/api/verify-docteur/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email_or_phone': emailOrPhoneController.text.trim(),
        'code_secret': codeSecretController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        showPasswordFields = true;
      });
    } else {
      setState(() {
        errorMessage = jsonDecode(response.body)['error'];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> resetPassword() async {
    final password = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = newNameController.text.trim();

    if (password != confirmPassword) {
      setState(() => errorMessage =
          tr('doctor_reset_password.errors.passwords_dont_match'));
      return;
    }

    if (!isValidPassword(password)) {
      setState(() =>
          errorMessage = tr('doctor_reset_password.errors.weak_password'));
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('http://192.168.1.122:8000/api/reset-docteur-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email_or_phone': emailOrPhoneController.text.trim(),
        'new_password': password,
        'new_name': name.isEmpty ? null : name,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('doctor_reset_password.success.password_reset'))));
      Navigator.pop(context);
    } else {
      setState(() {
        errorMessage = jsonDecode(response.body)['error'];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = showPasswordFields ? 2 : 1;
    double progress = (currentStep / 2);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 32),

                // Header avec icône
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      tr('doctor_reset_password.title'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      tr('doctor_reset_password.subtitle'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('doctor_reset_password.step_indicator',
                                args: [currentStep.toString()]),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            "${(progress * 100).round()}%",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                showPasswordFields
                                    ? Icons.person
                                    : Icons.security,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                showPasswordFields
                                    ? tr(
                                        'doctor_reset_password.new_password.title')
                                    : tr(
                                        'doctor_reset_password.identity_verification.title'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            showPasswordFields
                                ? tr(
                                    'doctor_reset_password.new_password.subtitle')
                                : tr(
                                    'doctor_reset_password.identity_verification.subtitle'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 24),
                          if (!showPasswordFields) ...[
                            _buildModernTextField(
                              tr('doctor_reset_password.identity_verification.email_or_phone_label'),
                              emailOrPhoneController,
                              tr('doctor_reset_password.identity_verification.email_or_phone_hint'),
                            ),
                            SizedBox(height: 16),
                            _buildModernTextField(
                              tr('doctor_reset_password.identity_verification.secret_code_label'),
                              codeSecretController,
                              tr('doctor_reset_password.identity_verification.secret_code_hint'),
                              obscure: true,
                            ),
                            SizedBox(height: 24),
                            _buildModernButton(
                              text: tr(
                                  'doctor_reset_password.identity_verification.verify_button'),
                              icon: Icons.check_circle,
                              onPressed: (isLoading ||
                                      emailOrPhoneController.text.isEmpty ||
                                      codeSecretController.text.isEmpty)
                                  ? null
                                  : verifyDoctorIdentity,
                              isLoading: isLoading,
                              loadingText: tr(
                                  'doctor_reset_password.identity_verification.verifying'),
                            ),
                          ] else ...[
                            _buildModernTextField(
                              tr('doctor_reset_password.new_password.new_name_label'),
                              newNameController,
                              tr('doctor_reset_password.new_password.new_name_hint'),
                            ),
                            SizedBox(height: 16),
                            _buildPasswordField(
                              tr('doctor_reset_password.new_password.new_password_label'),
                              newPasswordController,
                              tr('doctor_reset_password.new_password.new_password_hint'),
                              showPassword,
                              () =>
                                  setState(() => showPassword = !showPassword),
                            ),
                            SizedBox(height: 16),
                            _buildPasswordField(
                              tr('doctor_reset_password.new_password.confirm_password_label'),
                              confirmPasswordController,
                              tr('doctor_reset_password.new_password.confirm_password_hint'),
                              showConfirmPassword,
                              () => setState(() =>
                                  showConfirmPassword = !showConfirmPassword),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('doctor_reset_password.new_password.password_requirements'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    tr('doctor_reset_password.new_password.password_rules'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                            _buildModernButton(
                              text: tr(
                                  'doctor_reset_password.new_password.reset_button'),
                              icon: Icons.check_circle,
                              onPressed: (isLoading ||
                                      newPasswordController.text.isEmpty ||
                                      confirmPasswordController.text.isEmpty)
                                  ? null
                                  : resetPassword,
                              isLoading: isLoading,
                              loadingText: tr(
                                  'doctor_reset_password.new_password.resetting'),
                            ),
                          ],
                          if (errorMessage != null) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('doctor_reset_password.security_card.title'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                tr('doctor_reset_password.security_card.description'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(
      String label, TextEditingController controller, String hint,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller,
      String hint, bool showText, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: !showText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                showText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    String? loadingText,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(loadingText ?? text),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  SizedBox(width: 8),
                  Text(text),
                ],
              ),
      ),
    );
  }
}
