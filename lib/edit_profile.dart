import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

final Logger log = Logger('EditProfilePage');

class EditProfilePage extends StatefulWidget {
  final String userName;
  final String userId;
  final String contact;

  const EditProfilePage({
    super.key,
    required this.userName,
    required this.userId,
    required this.contact,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controllers pour la vérification du mot de passe
  final _passwordController = TextEditingController();

  // Controllers pour l'édition du profil
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isChangingPassword = false;

  // Données utilisateur actuelles
  final Map<String, dynamic> _currentUserData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Charger les données utilisateur depuis le backend
  Future<void> _loadUserData() async {
    try {
      final response = await _makeApiCall('GET', '/api/user/${widget.userId}');

      final prefs = await SharedPreferences.getInstance();
      final fallbackName = prefs.getString('user_name') ?? widget.userName;
      final fallbackContact = prefs.getString('user_contact') ?? widget.contact;

      if (response['success'] && response['data'] != null) {
        final data = response['data'];

        setState(() {
          _nameController.text = data['name'] ?? fallbackName;
          _contactController.text = data['contact'] ?? fallbackContact;
        });
      } else {
        // Si l'API a échoué, on utilise les données locales
        setState(() {
          _nameController.text = fallbackName;
          _contactController.text = fallbackContact;
        });
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _nameController.text = prefs.getString('user_name') ?? widget.userName;
        _contactController.text =
            prefs.getString('user_contact') ?? widget.contact;
      });
      _showSnackBar('Erreur lors du chargement des données', isError: true);
    }
  }

  Future<Map<String, dynamic>> _makeApiCall(String method, String endpoint,
      [Map<String, dynamic>? data]) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    log.info('Token: $token'); // Debug

    if (token == null || token.isEmpty) {
      _showSnackBar('Vous devez être connecté pour faire cette action',
          isError: true);
      setState(() {
        _isLoading = false;
      });
      return {'success': false, 'message': 'Token manquant'};
    }

    // Suppression de la simulation /update-profile
    if (endpoint.contains('/verify-password')) {
      final bool isCorrect =
          data?['password'] == prefs.getString('user_password');
      setState(() {
        _isLoading = false;
      });
      return {
        'success': isCorrect,
        'message':
            isCorrect ? 'Mot de passe correct' : 'Mot de passe incorrect',
      };
    } else if (endpoint.contains('/user/')) {
      setState(() {
        _isLoading = false;
      });
      return {
        'success': true,
        'data': {
          'userId': prefs.getInt('user_id'),
          'name': prefs.getString('user_name') ?? widget.userName,
          'contact': prefs.getString('user_contact') ?? widget.contact,
        },
      };
    }

    // Appel HTTP réel
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };

    final uri = Uri.parse('http://192.168.1.122:8000$endpoint');

    try {
      http.Response response;

      if (method == 'PUT') {
        response =
            await http.put(uri, headers: headers, body: json.encode(data));
      } else if (method == 'PATCH') {
        response =
            await http.patch(uri, headers: headers, body: json.encode(data));
      } else if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response =
            await http.post(uri, headers: headers, body: json.encode(data));
      } else {
        throw Exception('Méthode non supportée');
      }

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Mise à jour locale des SharedPreferences si c'est le profil
        if (endpoint.contains('/update-profile') && data != null) {
          await prefs.setString('user_name', data['name'] ?? '');
          await prefs.setString('user_contact', data['contact'] ?? '');
        }

        return {
          'success': true,
          'message': 'Opération réussie',
          'data': responseData
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur serveur'
        };
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // Vérifier le mot de passe avec le backend
  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Veuillez entrer votre mot de passe', isError: true);
      return;
    }

    try {
      final response = await _makeApiCall('POST', '/api/verify-password', {
        'userId': widget.userId,
        'password': _passwordController.text,
      });

      if (response['success']) {
        setState(() {
          _isPasswordVerified = true;
        });
        _showSnackBar('Mot de passe vérifié avec succès!');
      } else {
        _showSnackBar(response['message'] ?? 'Mot de passe incorrect',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la vérification', isError: true);
    }
  }

  // Sauvegarder les modifications dans le backend
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier la confirmation du nouveau mot de passe si nécessaire
    if (_isChangingPassword) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackBar('Les mots de passe ne correspondent pas', isError: true);
        return;
      }
      if (_newPasswordController.text.length != 4) {
        _showSnackBar('Le mot de passe doit contenir exactement 4  caractères',
            isError: true);
        return;
      }
    }

    try {
      Map<String, dynamic> updateData = {
        'userId': widget.userId,
        'name': _nameController.text,
        'contact': _contactController.text,
      };

      if (_isChangingPassword) {
        updateData['newPassword'] = _newPasswordController.text;
      }

      final response =
          await _makeApiCall('PATCH', '/api/update-profile/', updateData);

      if (response['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', _nameController.text.trim());
        await prefs.setString('user_contact', _contactController.text.trim());
        if (_isChangingPassword) {
          await prefs.setString(
              'user_password', _newPasswordController.text.trim());
        }
        _showSnackBar('Profil mis à jour avec succès!');
        if (_isChangingPassword) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_password', _newPasswordController.text);
        }

        // Retourner à la page précédente après 1.5 secondes
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer le profil'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isPasswordVerified
            ? _buildEditForm()
            : _buildPasswordVerification(),
      ),
    );
  }

  Widget _buildPasswordVerification() {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérification de sécurité',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour votre sécurité, veuillez entrer votre mot de passe actuel pour accéder à l\'édition du profil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  helperStyle: const TextStyle(color: Colors.orange),
                ),
                onSubmitted: (_) => _verifyPassword(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text(
                'Modifier vos informations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isChangingPassword,
                onChanged: (value) {
                  setState(() {
                    _isChangingPassword = value;
                    if (!value) {
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    }
                  });
                },
                activeColor: Colors.blueAccent,
              ),
              const Text('Changer mot de passe'),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Informations personnelles
                  _buildSectionTitle('Informations personnelles'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Email ou Téléphone',
                      prefixIcon: Icon(Icons.contact_mail),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un email ou un téléphone';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Section changement de mot de passe
                  if (_isChangingPassword) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Nouveau mot de passe'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_isChangingPassword &&
                            (value == null || value.isEmpty)) {
                          return 'Veuillez entrer un nouveau mot de passe';
                        }
                        if (_isChangingPassword && value!.length != 4) {
                          return 'Le mot de passe doit contenir exactement 4 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_isChangingPassword &&
                            value != _newPasswordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isChangingPassword
                              ? 'Sauvegarder tout'
                              : 'Sauvegarder',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}
