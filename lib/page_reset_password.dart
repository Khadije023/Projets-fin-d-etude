import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

class PageResetPassword extends StatefulWidget {
  const PageResetPassword({super.key});

  @override
  PageResetPasswordState createState() => PageResetPasswordState();
}

class PageResetPasswordState extends State<PageResetPassword> {
  final identifierController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool codeSent = false;
  bool codeVerified = false;
  bool isLoading = false;
  String selectedOption = "email"; // ou "phone"
  String? errorMessage;
  String? successMessage;
  String? identifierError;

  final Color primaryRed = Color(0xFFDC2626);
  final Color darkRed = Color(0xFFB91C1C);
  final Color lightRed = Color(0xFFFEF2F2);
  final Color roseLight = Color(0xFFFFF1F2);

  String formatPhoneNumber(String phone) {
    if (phone.startsWith('+222')) {
      return phone;
    }
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    return '+222$cleanPhone';
  }

  void validateIdentifier(String identifier) {
    setState(() {
      if (selectedOption == "phone") {
        String cleanPhone = identifier.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanPhone.length < 8) {
          identifierError = tr('reset_password.phone_exactly_8_digits');
        } else if (cleanPhone.length > 8) {
          identifierError = tr('reset_password.phone_max_8_digits');
        } else if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
          identifierError = tr('reset_password.phone_only_digits');
        } else if (!RegExp(r'^[234]').hasMatch(cleanPhone)) {
          identifierError = tr('reset_password.phone_start_with_234');
        } else {
          identifierError = null;
        }
      } else {
        if (!identifier.endsWith('@gmail.com')) {
          identifierError = tr('reset_password.email_must_end_gmail');
        } else {
          identifierError = null;
        }
      }
    });
  }

  Future<void> sendVerificationCode() async {
    final String url = 'http://192.168.1.122:8000/api/send-verification-code/';

    validateIdentifier(identifierController.text.trim());

    if (identifierError != null) {
      setState(() {
        errorMessage = identifierError;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    String finalIdentifier = identifierController.text.trim();

    if (selectedOption == "phone") {
      finalIdentifier = formatPhoneNumber(finalIdentifier);
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': finalIdentifier,
          'method': selectedOption,
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
          successMessage = tr('reset_password.code_sent_success');
        });
      } else if (response.statusCode == 404 || response.statusCode == 400) {
        setState(() {
          errorMessage = tr('reset_password.user_not_found');
        });
      } else {
        setState(() {
          errorMessage = tr('reset_password.send_code_failed');
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = tr('reset_password.send_code_error');
      });
    }
  }

  Future<void> verifyCode() async {
    final String url = 'http://192.168.1.122:8000/api/verify-code/';
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    String finalIdentifier = identifierController.text.trim();

    if (selectedOption == "phone") {
      finalIdentifier = formatPhoneNumber(finalIdentifier);
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': finalIdentifier,
          'code': codeController.text.trim(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          codeVerified = true;
          successMessage = tr('reset_password.code_verified_success');
        });
      } else {
        setState(() {
          errorMessage = tr('reset_password.incorrect_code');
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = tr('reset_password.verification_error');
      });
    }
  }

  Future<void> resetPassword() async {
    final String url = 'http://172.20.10.2:8000/api/reset-password/';
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    if (newPasswordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = tr('reset_password.passwords_dont_match');
        isLoading = false;
      });
      return;
    }

    if (newPasswordController.text.length < 6) {
      setState(() {
        errorMessage = tr('reset_password.password_min_length');
        isLoading = false;
      });
      return;
    }

    String finalIdentifier = identifierController.text.trim();

    if (selectedOption == "phone") {
      finalIdentifier = formatPhoneNumber(finalIdentifier);
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': finalIdentifier,
          'new_password': newPasswordController.text.trim(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          successMessage = tr('reset_password.password_reset_success');
        });

        Future.delayed(Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context);
        });
      } else {
        setState(() {
          errorMessage = tr('reset_password.no_account_found');
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = tr('reset_password.reset_error');
      });
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !codeSent ? primaryRed : Color(0xFFE5E7EB),
            ),
          ),
          Container(
            width: 32,
            height: 2,
            color: codeSent ? primaryRed : Color(0xFFE5E7EB),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: codeSent && !codeVerified
                  ? primaryRed
                  : codeVerified
                      ? Color(0xFFE5E7EB)
                      : Color(0xFFE5E7EB),
            ),
          ),
          Container(
            width: 32,
            height: 2,
            color: codeVerified ? primaryRed : Color(0xFFE5E7EB),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: codeVerified ? primaryRed : Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox() {
    if (errorMessage != null) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFFECACA)),
        ),
        child: Text(
          errorMessage!,
          style: GoogleFonts.poppins(
            color: Color(0xFFB91C1C),
            fontSize: 14,
          ),
        ),
      );
    }

    if (successMessage != null) {
      return Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                successMessage!,
                style: GoogleFonts.poppins(
                  color: Color(0xFF16A34A),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  @override
  void initState() {
    super.initState();
    newPasswordController.addListener(_onTextChanged);
    confirmPasswordController.addListener(_onTextChanged);
    codeController.addListener(() => setState(() {}));
    identifierController.addListener(() {
      if (identifierController.text.isNotEmpty) {
        validateIdentifier(identifierController.text);
      } else {
        setState(() {
          identifierError = null;
        });
      }
    });
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    newPasswordController.removeListener(_onTextChanged);
    confirmPasswordController.removeListener(_onTextChanged);
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('reset_password.title'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lightRed, roseLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryRed),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                !codeSent
                                    ? tr('reset_password.enter_identifier')
                                    : !codeVerified
                                        ? tr(
                                            'reset_password.enter_verification_code')
                                        : tr(
                                            'reset_password.create_new_password'),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              _buildProgressIndicator(),
                              _buildMessageBox(),
                              if (!codeSent) ...[
                                Text(
                                  tr('reset_password.recovery_method'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Radio(
                                      value: "email",
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedOption = value.toString();
                                          identifierController.clear();
                                          identifierError = null;
                                        });
                                      },
                                      activeColor: primaryRed,
                                    ),
                                    Icon(Icons.email,
                                        color: primaryRed, size: 18),
                                    SizedBox(width: 4),
                                    Text(tr('reset_password.email'),
                                        style: GoogleFonts.poppins()),
                                    SizedBox(width: 16),
                                    Radio(
                                      value: "phone",
                                      groupValue: selectedOption,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedOption = value.toString();
                                          identifierController.clear();
                                          identifierError = null;
                                        });
                                      },
                                      activeColor: primaryRed,
                                    ),
                                    Icon(Icons.phone,
                                        color: primaryRed, size: 18),
                                    SizedBox(width: 4),
                                    Text(tr('reset_password.phone'),
                                        style: GoogleFonts.poppins()),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  selectedOption == "email"
                                      ? tr('reset_password.email_address')
                                      : tr('reset_password.phone_number'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: identifierController,
                                  keyboardType: selectedOption == "email"
                                      ? TextInputType.emailAddress
                                      : TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: selectedOption == "email"
                                        ? tr('reset_password.email_placeholder')
                                        : "",
                                    prefixText: selectedOption == "phone"
                                        ? "+222 "
                                        : null,
                                    prefixStyle: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: primaryRed, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 1),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 2),
                                    ),
                                    errorText: identifierError,
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: identifierController.text
                                              .trim()
                                              .isNotEmpty &&
                                          identifierError == null
                                      ? sendVerificationCode
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(tr('reset_password.send_code')),
                                ),
                              ] else if (!codeVerified) ...[
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.shield,
                                          color: primaryRed, size: 48),
                                      SizedBox(height: 8),
                                      Text(
                                        selectedOption == "email"
                                            ? tr(
                                                'reset_password.code_sent_email')
                                            : tr(
                                                'reset_password.code_sent_phone'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  tr('reset_password.verification_code'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextField(
                                  controller: codeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    letterSpacing: 8,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    hintText: "",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: primaryRed, width: 2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  tr('reset_password.enter_6_digit_code'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: newPasswordController
                                              .text.isNotEmpty &&
                                          confirmPasswordController
                                              .text.isNotEmpty
                                      ? () {
                                          if (newPasswordController.text !=
                                              confirmPasswordController.text) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(tr(
                                                    'reset_password.passwords_dont_match')),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } else {
                                            resetPassword();
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryRed,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(tr(
                                      'reset_password.reset_password_button')),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
