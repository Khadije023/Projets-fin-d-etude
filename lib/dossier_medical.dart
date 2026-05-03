import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfe/premiere_secours.dart';
import 'package:pfe/trousse_medical.dart';
import 'package:pfe/Profil.dart';
import 'package:pfe/connectionpatient.dart';
import 'package:easy_localization/easy_localization.dart';

class DossierMedicalPage extends StatefulWidget {
  const DossierMedicalPage({super.key});

  @override
  DossierMedicalPageState createState() => DossierMedicalPageState();
}

class DossierMedicalPageState extends State<DossierMedicalPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _antecedentsController = TextEditingController();
  final TextEditingController _medecinController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _tailleController = TextEditingController();
  final TextEditingController _sexeController = TextEditingController();
  final TextEditingController _groupeSanguinController =
      TextEditingController();
  bool _aAllergies = false;

  bool _loading = false;
  bool _isEditing = false; // Ajout pour le système d'édition
  String? _token;
  int _selectedIndex = 3; // Dossier = index 3
  bool isLoggedIn = false;
  String userName = '';

  final String _baseUrl = 'http://192.168.1.122:8000/api';

  @override
  void initState() {
    super.initState();
    _poidsController.text = "0";
    _tailleController.text = "0";
    _groupeSanguinController.text = "0";
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      isLoggedIn = _token != null;
      userName = prefs.getString('userName') ?? '';
    });
    if (_token != null) {
      _loadExistingData();
    }
  }

  void _updateLoginState(bool status, String name) {
    setState(() {
      isLoggedIn = status;
      userName = name;
    });
  }

  Future<void> _loadExistingData() async {
    if (_token == null) return;
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dossier-medical/'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nomController.text = data['nom'] ?? '';
          _dobController.text = data['date_naissance'] ?? '';
          _antecedentsController.text = data['antecedents'] ?? '';
          _medecinController.text = data['medecin_traitant'] ?? '';
          _telController.text = data['numero_tel'] ?? '';
          _poidsController.text = data['poids']?.toString() ?? '';
          _tailleController.text = data['taille']?.toString() ?? '';
          _sexeController.text = data['sexe'] ?? '';
          _groupeSanguinController.text = data['groupe_sanguin'] ?? '';
          _aAllergies = data['a_allergies'] ?? false;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDossier() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vous devez être connecté pour sauvegarder votre dossier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final medicalData = {
        'nom': _nomController.text.trim(),
        'date_naissance': _dobController.text.trim(),
        'antecedents': _antecedentsController.text.trim(),
        'medecin_traitant': _medecinController.text.trim(),
        'numero_tel': _telController.text.trim(),
        'poids': double.tryParse(_poidsController.text.trim()) ?? 0,
        'taille': double.tryParse(_tailleController.text.trim()) ?? 0,
        'sexe': _sexeController.text.trim(),
        'groupe_sanguin': _groupeSanguinController.text.trim(),
        'a_allergies': _aAllergies,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/dossier-medical/'),
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode(medicalData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('dssave'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Retour au mode lecture après sauvegarde
      setState(() {
        _isEditing = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('err'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Already on this page

    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab using pushReplacement
    switch (index) {
      case 0:
        // Navigate to HomePage
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        // Navigate to PremiereSecoursPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PremiereSecoursPage()),
        );
        break;
      case 2:
        // Navigate to DiscussionAvecDocteurPage
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
        // Already on DossierMedicalPage
        break;
      case 4:
        // Navigate to ProfilPage or LoginPage
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
                backgroundColor: Colors.teal,
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

  // Calcul de l'IMC
  double _calculateBMI() {
    final weight = double.tryParse(_poidsController.text) ?? 0;
    final height = (double.tryParse(_tailleController.text) ?? 0) / 100;
    if (weight > 0 && height > 0) {
      return weight / (height * height);
    }
    return 0;
  }

  String _getBMIStatus(double bmi) {
    if (bmi < 18.5) return "Insuffisant";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Surpoids";
    return "Obésité";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "medicalRecord".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: "md".tr(),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _saveDossier,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text("sv".tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading && !_isEditing
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.indigo.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.security,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "infSSS".tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "infS".tr(),
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Header Title
                  Text(
                    'DS'.tr(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'gere'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards Row
                  if (_poidsController.text.isNotEmpty ||
                      _tailleController.text.isNotEmpty ||
                      _groupeSanguinController.text.isNotEmpty) ...[
                    Row(
                      children: [
                        // Weight Card
                        if (_poidsController.text.isNotEmpty) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade50,
                                    Colors.orange.shade100
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "pk".tr(),
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _poidsController.text,
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange.shade800,
                                                ),
                                              ),
                                              Text(
                                                " kg",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.orange.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade200,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.fitness_center,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (bmi > 0) ...[
                                    Text(
                                      "IMC: ${bmi.toStringAsFixed(1)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getBMIColor(bmi)
                                            .withAlpha((0.2 * 255).round()),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getBMIStatus(bmi),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: _getBMIColor(bmi),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // Blood Group Card

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pink.shade50,
                                  Colors.pink.shade100
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.pink.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "gro".tr(),
                                          style: TextStyle(
                                            color: Colors.pink.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _groupeSanguinController.text,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.bloodtype,
                                        color: Colors.pink.shade700,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _aAllergies
                                        ? Colors.red.shade100
                                        : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Personal Information Card

                  // Medical Information Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_hospital,
                                  color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "inf".tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _nomController,
                            label: "Nom".tr(),
                            icon: Icons.person,
                            hint: "nom".tr(),
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _dobController,
                            label: "DN".tr(),
                            icon: Icons.calendar_today,
                            hint: "dnss".tr(),
                            onTap:
                                _isEditing ? () => _selectDate(context) : null,
                            readOnly: true,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 24),
                          Builder(
                            builder: (context) {
                              String? sexeValue = ['Homme', 'Femme']
                                      .contains(_sexeController.text)
                                  ? _sexeController.text
                                  : null;

                              return DropdownButtonFormField<String>(
                                value: sexeValue,
                                items: ['Homme', 'Femme'].map((sexe) {
                                  return DropdownMenuItem(
                                    value: sexe,
                                    child: Text(sexe),
                                  );
                                }).toList(),
                                onChanged: _isEditing
                                    ? (value) {
                                        setState(() {
                                          _sexeController.text = value!;
                                        });
                                      }
                                    : null,
                                decoration: InputDecoration(
                                  labelText: "See".tr(),
                                  hintText: "ents".tr(),
                                  prefixIcon: Icon(
                                    Icons.wc,
                                    color: _isEditing
                                        ? Colors.teal.shade600
                                        : Colors.teal.shade600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: const Color(0xFF1F2937)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.teal.shade600, width: 2),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  filled: !_isEditing,
                                  fillColor:
                                      _isEditing ? null : Colors.grey.shade50,
                                  labelStyle: TextStyle(
                                    color: _isEditing
                                        ? Colors.teal.shade700
                                        : Colors.grey.shade500,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _poidsController,
                                  label: "pk".tr(),
                                  icon: Icons.fitness_center,
                                  hint: "entp".tr(),
                                  enabled: _isEditing,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _tailleController,
                                  label: "tc".tr(),
                                  icon: Icons.height,
                                  hint: "entt".tr(),
                                  enabled: _isEditing,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-'
                            ].contains(_groupeSanguinController.text)
                                ? _groupeSanguinController.text
                                : null,
                            items: [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-'
                            ].map((groupe) {
                              return DropdownMenuItem(
                                value: groupe,
                                child: Text(groupe),
                              );
                            }).toList(),
                            onChanged: _isEditing
                                ? (value) {
                                    setState(() {
                                      _groupeSanguinController.text = value!;
                                    });
                                  }
                                : null,
                            decoration: InputDecoration(
                              labelText: "gro".tr(),
                              hintText: "EX".tr(),
                              prefixIcon: Icon(
                                Icons.bloodtype,
                                color: _isEditing
                                    ? Colors.teal.shade600
                                    : Colors.teal.shade600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: const Color(0xFF1F2937)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.teal.shade600, width: 2),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200),
                              ),
                              filled: !_isEditing,
                              fillColor:
                                  _isEditing ? null : Colors.grey.shade50,
                              labelStyle: TextStyle(
                                color: _isEditing
                                    ? Colors.teal.shade700
                                    : Colors.grey.shade500,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _medecinController,
                            label: "med".tr(),
                            icon: Icons.local_hospital,
                            hint: "entM".tr(),
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _antecedentsController,
                            label: "ant".tr(),
                            icon: Icons.medical_services,
                            hint: "ent".tr(),
                            maxLines: 3,
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                "ave".tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _aAllergies,
                                onChanged: _isEditing
                                    ? (value) {
                                        setState(() {
                                          _aAllergies = value;
                                        });
                                      }
                                    : null,
                                activeColor: Colors.teal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Medical History Card

                  // Save Button (only shown in editing mode)
                  if (_isEditing) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveDossier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "sav".tr(),
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80), // Space for bottom navigation bar
                ],
              ),
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
              )
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.teal, // Match app bar color
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1905, 6, 9),
      lastDate: DateTime.now(),
      locale: const Locale("fr"), // si tu veux en français
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      style: TextStyle(
        color: enabled ? const Color(0xFF1F2937) : const Color(0xFF1F2937),
        fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: enabled ? Colors.teal.shade600 : Colors.teal.shade600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade50,
        labelStyle: TextStyle(
          color: enabled ? Colors.teal.shade700 : Colors.grey.shade500,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
