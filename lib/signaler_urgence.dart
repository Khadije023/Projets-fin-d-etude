import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'Urgence_acceptee.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dossier_medical.dart';

enum AgeVictime { adulte, enfant, nourrisson }

class SignalerUrgencePage extends StatefulWidget {
  const SignalerUrgencePage({super.key});

  @override
  _SignalerUrgencePageState createState() => _SignalerUrgencePageState();
}

class _SignalerUrgencePageState extends State<SignalerUrgencePage> {
  final ImagePicker _picker = ImagePicker();
  bool _inclureDossierMedical = false;
  XFile? _image;
  bool _isLoading = false;
  String _statutUrgence = 'Aucune urgence signalée';
  int? _urgenceId;
  Timer? _timer;
  String? _patientToken;
  int? _loggedInPatientId;

  final List<String> _activeUrgenceDisplayStatuses = const [
    'En attente de réponse...',
    'ambulance_affectee',
    'en_route_vers_victime',
    'arrivee_sur_place',
    'prise_en_charge',
    'en_route_vers_base',
  ];

  final _formKeySignalerUrgence = GlobalKey<FormState>();

  int _adultCount = 0;
  int _childCount = 0;
  int _infantCount = 0;

  String? _selectedUrgenceApiValue;
  String _autreUrgenceDescription = '';

  bool? _estConscient;
  bool? _respire;
  bool? _saignementImportant;

  final Map<String, String> typeUrgenceMap = {
    'Arrêt Cardiaque': 'arret_cardiaque',
    'Brûlure': 'brulure',
    'Étouffement': 'etouffement',
    'Accident de la voie publique': 'accident_voie_publique',
    'Perte de connaissance': 'perte_de_connaissance',
    'Malaise': 'malaise',
    'Noyade': 'noyade',
    'Fracture': 'fracture',
    'Electrocution': 'electrocution',
    'Autre': 'autre',
  };

  double? _signaledUrgenceLatitude;
  double? _signaledUrgenceLongitude;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
    _getCurrentLocation();
  }

  Future<void> _loadPatientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _patientToken = prefs.getString('token');
      _loggedInPatientId = prefs.getInt('loggedInPatientId');
    });
    print('Patient Token Loaded: $_patientToken');
    print('Logged-in Patient ID Loaded: $_loggedInPatientId');

    await _loadUrgenceStatus();
  }

  Future<void> _loadUrgenceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUrgenceId = prefs.getInt('currentUrgenceId');
    final storedStatut = prefs.getString('currentUrgenceStatut');
    final storedUrgencePatientId = prefs.getInt('currentUrgencePatientId');

    _signaledUrgenceLatitude = prefs.getDouble('currentUrgenceLatitude');
    _signaledUrgenceLongitude = prefs.getDouble('currentUrgenceLongitude');

    int? tempUrgenceId = null;
    String tempStatut = 'Aucune urgence signalée';
    double? tempLatitude = null;
    double? tempLongitude = null;

    if (storedUrgenceId != null &&
        storedStatut != null &&
        storedUrgencePatientId != null) {
      if (_loggedInPatientId != null &&
          storedUrgencePatientId == _loggedInPatientId) {
        tempUrgenceId = storedUrgenceId;
        tempStatut = storedStatut;
        tempLatitude = _signaledUrgenceLatitude;
        tempLongitude = _signaledUrgenceLongitude;
        if (tempStatut == 'En attente de réponse...' ||
            tempStatut.startsWith('Acceptée')) {
          print(
              "Reprise du suivi de l'urgence ID: $tempUrgenceId avec statut: $tempStatut pour le patient ID: $_loggedInPatientId");
          _timer = Timer.periodic(
              const Duration(seconds: 7), (timer) => _verifierStatutUrgence());
        }
      } else {
        print(
            "Urgence stockée ID $storedUrgenceId n'appartient pas au patient connecté ID: $_loggedInPatientId. Ne pas afficher et ne pas effacer.");
      }
    } else {
      print("Aucune urgence active stockée du tout. L'UI sera réinitialisée.");
    }

    setState(() {
      _urgenceId = tempUrgenceId;
      _statutUrgence = tempStatut;
      _signaledUrgenceLatitude = tempLatitude;
      _signaledUrgenceLongitude = tempLongitude;
    });
  }

  Future<void> _saveUrgenceStatus(int id, String statut, int patientDbId,
      {double? latitude, double? longitude}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentUrgenceId', id);
    await prefs.setString('currentUrgenceStatut', statut);
    await prefs.setInt('currentUrgencePatientId', patientDbId);

    if (latitude != null && latitude.isFinite) {
      await prefs.setDouble('currentUrgenceLatitude', latitude);
    } else {
      await prefs.remove('currentUrgenceLatitude');
    }
    if (longitude != null && longitude.isFinite) {
      await prefs.setDouble('currentUrgenceLongitude', longitude);
    } else {
      await prefs.remove('currentUrgenceLongitude');
    }

    print(
        "Statut urgence ID $id sauvegardé pour patient $patientDbId: $statut (Lat: $latitude, Lon: $longitude)");
  }

  Future<void> _clearUrgenceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUrgenceId');
    await prefs.remove('currentUrgenceStatut');
    await prefs.remove('currentUrgencePatientId');
    await prefs.remove('currentUrgenceLatitude');
    await prefs.remove('currentUrgenceLongitude');
    setState(() {
      _urgenceId = null;
      _statutUrgence = 'Aucune urgence signalée';
      _signaledUrgenceLatitude = null;
      _signaledUrgenceLongitude = null;
    });
    print("Statut urgence effacé.");
  }

  String _ageVictimeToString(AgeVictime age) {
    switch (age) {
      case AgeVictime.adulte:
        return 'Adulte';
      case AgeVictime.enfant:
        return 'Enfant';
      case AgeVictime.nourrisson:
        return 'Nourrisson';
    }
  }

  Future<void> _pickImageSource() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Choisir la source de l\'image'),
        content: const Text(
            'Voulez-vous prendre une nouvelle photo ou en choisir une depuis votre galerie ?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Caméra'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: const Text('Galerie'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? pickedImage = await _picker.pickImage(source: source);
      if (mounted && pickedImage != null) {
        setState(() => _image = pickedImage);
      }
    }
  }

  Future<void> _getCurrentLocation() async {}

  Future<void> _confirmerEnvoiUrgence() async {
    final bool? confirmation = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation d\'envoi d\'urgence'),
          content: const Text(
              'Voulez-vous inclure votre dossier médical avec ce signalement d\'urgence ? Cela peut aider les secouristes.'),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Non', style: TextStyle(color: Colors.redAccent)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Oui', style: TextStyle(color: Colors.green)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmation != null) {
      setState(() {
        _inclureDossierMedical = confirmation;
      });
      _envoyerUrgence();
    }
  }

  Future<void> _envoyerUrgence() async {
    final String apiUrl = 'http://192.168.1.122:8000/api/signaler_urgence/';
    if (mounted) setState(() => _isLoading = true);

    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Veuillez activer votre localisation pour qu'on puisse vous récupérer facilement.";
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission de localisation refusée par l\'utilisateur.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.';
      }

      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!position.latitude.isFinite || !position.longitude.isFinite) {
        throw 'Position GPS invalide (NaN ou Infinity).';
      }
      _signaledUrgenceLatitude = position.latitude;
      _signaledUrgenceLongitude = position.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
      return;
    }

    int totalVictims = _adultCount + _childCount + _infantCount;
    if (totalVictims == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez spécifier au moins une victime.'),
            backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
      return;
    }

    String? mainVictimApproxAge;
    if (_adultCount > 0) {
      mainVictimApproxAge = _ageVictimeToString(AgeVictime.adulte);
    } else if (_childCount > 0) {
      mainVictimApproxAge = _ageVictimeToString(AgeVictime.enfant);
    } else if (_infantCount > 0) {
      mainVictimApproxAge = _ageVictimeToString(AgeVictime.nourrisson);
    }

    try {
      _timer?.cancel();

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      if (_patientToken != null) {
        request.headers['Authorization'] = 'Token $_patientToken';
        print('Authorization Header Added: Token $_patientToken');
      } else {
        print(
            'Warning: Patient token is null. Authorization header not added.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Erreur: Vous n\'êtes pas authentifié. Veuillez vous reconnecter.'),
            backgroundColor: Colors.red,
          ));
          setState(() => _isLoading = false);
        }
        return;
      }

      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();
      request.fields['type_urgence'] = _selectedUrgenceApiValue!;

      if (_selectedUrgenceApiValue == 'autre' &&
          _autreUrgenceDescription.isNotEmpty) {
        request.fields['description'] = _autreUrgenceDescription;
      }

      request.fields['nombre_total_victimes'] = totalVictims.toString();
      request.fields['adult_count'] = _adultCount.toString();
      request.fields['child_count'] = _childCount.toString();
      request.fields['infant_count'] = _infantCount.toString();

      if (mainVictimApproxAge != null) {
        request.fields['age_approximatif_victime_principale'] =
            mainVictimApproxAge;
      }

      request.fields['victime_principale_consciente'] =
          _estConscient! ? 'oui' : 'non';
      request.fields['victime_principale_respire'] = _respire! ? 'oui' : 'non';
      request.fields['victime_principale_saignement_important'] =
          _saignementImportant! ? 'oui' : 'non';
      request.fields['inclure_dossier_medical'] =
          _inclureDossierMedical.toString();
      if (_image != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print("🆕 Nouvelle urgence créée avec ID: ${data['id']}");
        if (mounted) {
          setState(() {
            _urgenceId = data['id'];
            _statutUrgence = 'En attente de réponse...';
            _selectedUrgenceApiValue = null;
            _autreUrgenceDescription = '';
            _adultCount = 0;
            _childCount = 0;
            _infantCount = 0;
            _estConscient = null;
            _respire = null;
            _saignementImportant = null;
            _image = null;
            _formKeySignalerUrgence.currentState?.reset();
          });

          if (_loggedInPatientId == null) {
            print(
                '❌ Erreur: _loggedInPatientId est null. Impossible de sauvegarder le statut de l\'urgence.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Erreur interne: ID patient manquant. Veuillez vous reconnecter.'),
                  backgroundColor: Colors.red));
            }
            return;
          }

          if (_urgenceId == null) {
            print('❌ Erreur: _urgenceId est null malgré la création réussie.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Erreur interne: ID d\'urgence manquant.'),
                  backgroundColor: Colors.red));
            }
            return;
          }

          await _saveUrgenceStatus(
              _urgenceId!, _statutUrgence, _loggedInPatientId!,
              latitude: _signaledUrgenceLatitude,
              longitude: _signaledUrgenceLongitude);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Urgence signalée avec succès !'),
              backgroundColor: Colors.green));

          _timer = Timer.periodic(
              const Duration(seconds: 7), (timer) => _verifierStatutUrgence());
        }
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Erreur lors de l\'envoi: $responseBody (Code: ${response.statusCode})'),
              backgroundColor: Colors.red));
        }
        print(
            'Erreur lors de l\'envoi: $responseBody (Code: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur inattendue lors de l\'envoi: $e'),
            backgroundColor: Colors.red));
      }
      print('❌ Exception lors de l\'envoi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifierStatutUrgence() async {
    if (_urgenceId == null || _loggedInPatientId == null) {
      _timer?.cancel();
      _clearUrgenceStatus();
      return;
    }

    final url = 'http://192.168.1.122:8000/api/urgences/$_urgenceId/';
    print(
        '🔍 Vérification du statut pour urgence ID=$_urgenceId pour patient ID=$_loggedInPatientId à ${DateTime.now()}');
    try {
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (_patientToken != null) {
        headers['Authorization'] = 'Token $_patientToken';
        print('Authorization Header for status check: Token $_patientToken');
      } else {
        print(
            'Warning: Patient token is null. Authorization header not added for status check.');

        _timer?.cancel();
        _clearUrgenceStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Session expirée ou non authentifiée, impossible de vérifier le statut de l\'urgence.'),
              backgroundColor: Colors.orangeAccent));
        }
        return;
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String statut = data['statut'];
        final int backendUrgencePatientId = data['patient'];

        if (backendUrgencePatientId != _loggedInPatientId) {
          print(
              "⛔ Mismatch patient ID: Urgence $_urgenceId appartient à $backendUrgencePatientId, mais connecté est $_loggedInPatientId. Nettoyage.");
          _timer?.cancel();
          _clearUrgenceStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Cette urgence n\'appartient pas à votre compte. Affichage effacé.'),
                backgroundColor: Colors.orangeAccent));
          }
          return;
        }

        double? backendUrgenceLat = (data['latitude'] as num?)?.toDouble();
        double? backendUrgenceLon = (data['longitude'] as num?)?.toDouble();

        if (backendUrgenceLat != null && !backendUrgenceLat.isFinite) {
          print(
              "Backend urgence latitude est NaN ou Infinity, utilisation de null.");
          backendUrgenceLat = null;
        }
        if (backendUrgenceLon != null && !backendUrgenceLon.isFinite) {
          print(
              "Backend urgence longitude est NaN ou Infinity, utilisation de null.");
          backendUrgenceLon = null;
        }

        final String? docteurNom = data['docteur_nom'];
        final String? docteurPrenom = data['docteur_prenom'];
        String nomCompletDocteur = "Docteur";
        if (docteurPrenom != null &&
            docteurNom != null &&
            docteurPrenom.isNotEmpty &&
            docteurNom.isNotEmpty) {
          nomCompletDocteur = "$docteurPrenom $docteurNom";
        } else if (docteurNom != null && docteurNom.isNotEmpty) {
          nomCompletDocteur = docteurNom;
        } else if (docteurPrenom != null && docteurPrenom.isNotEmpty) {
          nomCompletDocteur = docteurPrenom;
        }

        if (statut == 'acceptee') {
          if (_statutUrgence != 'Acceptée par $nomCompletDocteur') {
            setState(() => _statutUrgence = 'Acceptée par $nomCompletDocteur');
            await _saveUrgenceStatus(_urgenceId!, _statutUrgence,
                _loggedInPatientId!, // Passer l'ID du patient
                latitude: backendUrgenceLat ?? _signaledUrgenceLatitude,
                longitude: backendUrgenceLon ?? _signaledUrgenceLongitude);
            _timer?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UrgenceAccepteePage(
                  urgenceId: _urgenceId!,
                  urgenceLatitude:
                      backendUrgenceLat ?? _signaledUrgenceLatitude,
                  urgenceLongitude:
                      backendUrgenceLon ?? _signaledUrgenceLongitude,
                ),
              ),
            );
          }
        } else if (statut == 'refusee' || statut == 'terminee') {
          if (_statutUrgence != 'Refusée par le docteur' &&
              _statutUrgence != 'Terminée') {
            setState(() => _statutUrgence =
                statut == 'refusee' ? 'Refusée par le docteur' : 'Terminée');
            await _saveUrgenceStatus(
                _urgenceId!, _statutUrgence, _loggedInPatientId!,
                latitude: _signaledUrgenceLatitude,
                longitude: _signaledUrgenceLongitude);
          }
          _timer?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Votre urgence a été ${statut == 'refusee' ? 'refusée' : 'terminée'}.'),
                backgroundColor: Colors.orange));
          }
        } else if (statut == 'en_attente') {
          if (_statutUrgence != 'En attente de réponse...') {
            setState(() => _statutUrgence = 'En attente de réponse...');
            await _saveUrgenceStatus(_urgenceId!, _statutUrgence,
                _loggedInPatientId!, // Passer l'ID du patient
                latitude: _signaledUrgenceLatitude,
                longitude: _signaledUrgenceLongitude);
          }
        } else {
          if (_statutUrgence != statut) {
            setState(() => _statutUrgence = statut);
            await _saveUrgenceStatus(_urgenceId!, _statutUrgence,
                _loggedInPatientId!, // Passer l'ID du patient
                latitude: _signaledUrgenceLatitude,
                longitude: _signaledUrgenceLongitude);
          }
        }
      } else if (response.statusCode == 404 || response.statusCode == 403) {
        print(
            "⚠ Erreur vérification statut (Code: ${response.statusCode}): ${utf8.decode(response.bodyBytes)}");
        _timer?.cancel();
        setState(() => _statutUrgence =
            "L'urgence ID $_urgenceId n'existe plus ou vous n'y avez pas accès.");
        await _clearUrgenceStatus();
      } else {
        print(
            "⚠ Erreur vérification statut (Code: ${response.statusCode}): ${utf8.decode(response.bodyBytes)}");
      }
    } catch (e) {
      print("❌ Exception vérification statut: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildRadioQuestion(String title, bool? groupStateValue,
      ValueChanged<bool?> onStateChanged, String validationMessage) {
    return FormField<bool>(
      initialValue: groupStateValue,
      validator: (value) {
        if (groupStateValue == null) {
          return validationMessage;
        }
        return null;
      },
      builder: (FormFieldState<bool> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            Row(children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Oui', style: TextStyle(fontSize: 16)),
                  value: true,
                  groupValue: groupStateValue,
                  onChanged: (bool? newValue) {
                    onStateChanged(newValue);
                    field.didChange(newValue);
                  },
                  activeColor: Colors.redAccent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Non', style: TextStyle(fontSize: 16)),
                  value: false,
                  groupValue: groupStateValue,
                  onChanged: (bool? newValue) {
                    onStateChanged(newValue);
                    field.didChange(newValue);
                  },
                  activeColor: Colors.redAccent,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 0.0, top: 2.0),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12.0),
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildAgeStepper(
      String label, int currentCount, ValueChanged<int> onCountChanged) {
    return FormField<int>(
      initialValue: currentCount,
      validator: (value) {
        return null;
      },
      builder: (FormFieldState<int> field) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        if (currentCount > 0) {
                          onCountChanged(currentCount - 1);
                          field.didChange(currentCount - 1);
                        }
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.remove,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          currentCount.toString(),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        onCountChanged(currentCount + 1);
                        field.didChange(currentCount + 1);
                      },
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Signaler une Urgence'),
          backgroundColor: Colors.redAccent,
          elevation: 4.0),
      body: Form(
        key: _formKeySignalerUrgence,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Veuillez fournir les informations ci-dessous :',
                  style: TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.red.shade200, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 3))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Quelle est l'urgence principale ?",
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedUrgenceApiValue,
                      hint: const Text('Sélectionnez un type'),
                      isExpanded: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 12.0)),
                      items: typeUrgenceMap.entries
                          .map((e) => DropdownMenuItem<String>(
                              value: e.value,
                              child: Text(e.key,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedUrgenceApiValue = v),
                      validator: (v) =>
                          v == null ? 'Type d\'urgence requis' : null,
                    ),
                    if (_selectedUrgenceApiValue == 'autre') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _autreUrgenceDescription,
                        onChanged: (v) =>
                            setState(() => _autreUrgenceDescription = v),
                        decoration: InputDecoration(
                            labelText: 'Décrivez l\'urgence (Autre)',
                            hintText: 'Précisez la nature...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            filled: true,
                            fillColor: Colors.grey.shade50),
                        maxLines: 3,
                        validator: (v) =>
                            (_selectedUrgenceApiValue == 'autre' &&
                                    (v == null || v.isEmpty))
                                ? 'Description requise pour "Autre"'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Combien y a-t-il de victimes par catégorie d\'âge ?',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildAgeStepper('Adultes', _adultCount, (newValue) {
                      setState(() => _adultCount = newValue);
                    }),
                    _buildAgeStepper('Enfants', _childCount, (newValue) {
                      setState(() => _childCount = newValue);
                    }),
                    _buildAgeStepper('Nourrissons', _infantCount, (newValue) {
                      setState(() => _infantCount = newValue);
                    }),
                    const SizedBox(height: 12),
                    _buildRadioQuestion(
                        "La victime principale est-elle consciente ?",
                        _estConscient,
                        (val) => setState(() => _estConscient = val),
                        "Veuillez indiquer si la victime est consciente."),
                    _buildRadioQuestion(
                        "La victime principale respire-t-elle ?",
                        _respire,
                        (val) => setState(() => _respire = val),
                        "Veuillez indiquer si la victime respire."),
                    _buildRadioQuestion(
                        "Y a-t-il un saignement important chez la victime principale ?",
                        _saignementImportant,
                        (val) => setState(() => _saignementImportant = val),
                        "Veuillez indiquer s'il y a un saignement important."),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (_image != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        File(_image!.path),
                        height: 180,
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _pickImageSource,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade200,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        elevation: 3.0,
                        minimumSize: const Size(50, 50),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 10),
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.redAccent)
                        : Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_urgenceId != null &&
                                    (_statutUrgence ==
                                            'Refusée par le docteur' ||
                                        _statutUrgence == 'Terminée')) {
                                  final bool? clearOldUrgency =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text(
                                            'Ancienne Urgence Terminée'),
                                        content: Text(
                                            'Votre dernière urgence a été $_statutUrgence. Voulez-vous la réinitialiser et signaler une nouvelle urgence ?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Annuler',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                          ),
                                          TextButton(
                                            child: const Text('Réinitialiser',
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (clearOldUrgency == true) {
                                    await _clearUrgenceStatus();
                                  } else {
                                    return;
                                  }
                                }

                                bool isUrgencyCurrentlyActive = _urgenceId !=
                                        null &&
                                    (_statutUrgence.startsWith('Acceptée') ||
                                        _activeUrgenceDisplayStatuses
                                            .contains(_statutUrgence));

                                if (isUrgencyCurrentlyActive) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Une urgence est déjà signalée et en attente ou en cours. Vous ne pouvez pas en signaler une nouvelle.'),
                                          backgroundColor: Colors.blueAccent));
                                  return;
                                }

                                if (_formKeySignalerUrgence.currentState!
                                    .validate()) {
                                  if ((_adultCount +
                                          _childCount +
                                          _infantCount) <
                                      1) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Veuillez spécifier au moins une victime.'),
                                            backgroundColor:
                                                Colors.orangeAccent));
                                    return;
                                  }
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    await _confirmerEnvoiUrgence();
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Veuillez compléter tous les champs obligatoire'),
                                          backgroundColor:
                                              Colors.orangeAccent));
                                }
                              },
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: const Text('Envoyer l\'urgence',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 3.0,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                  child: Text('Statut : $_statutUrgence',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
