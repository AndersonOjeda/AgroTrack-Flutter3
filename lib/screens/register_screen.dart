import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/supabase_service.dart';
import '../services/email_service.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../widgets/location_search_field.dart';
import 'email_confirmation_screen.dart';
import 'login_screen.dart';
import 'package:flutter/foundation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ubicacionController = TextEditingController();

  
  DateTime? _fechaNacimiento;
  bool _showBirthDatePicker = false;
  String? _experienciaAgricola;
  String? _tamanoFinca;
  String? _primaryCrops;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _obscurePassword = true;

  final List<String> _experienciaOpciones = [
    'New to agriculture (less than 1 year)',
    'Beginner (1-3 years)',
    'Experienced (4-10 years)',
    'Very experienced (11-20 years)',
    'Expert (more than 20 years)'
  ];

  final List<String> _tamanoFincaOpciones = [
    'Small (less than 1 hectare)',
    'Medium (1-5 hectares)',
    'Large (more than 5 hectares)'
  ];

  final List<Map<String, dynamic>> _primaryCropsOptions = [
    {'value': 'Corn (Maize)', 'icon': Icons.eco, 'description': 'Staple cereal crop used for food and feed'},
    {'value': 'Wheat', 'icon': Icons.grass, 'description': 'Major cereal grain for flour and food'},
    {'value': 'Rice', 'icon': Icons.rice_bowl, 'description': 'Primary staple food crop in many regions'},
    {'value': 'Soybeans', 'icon': Icons.spa, 'description': 'Legume for oil and protein-rich products'},
    {'value': 'Coffee', 'icon': Icons.coffee, 'description': 'Popular beverage crop grown in tropical climates'},
    {'value': 'Cocoa', 'icon': Icons.cookie, 'description': 'Bean used to produce chocolate products'},
    {'value': 'Banana/Plantain', 'icon': Icons.local_florist, 'description': 'Tropical fruit crop for fresh and cooked uses'},
    {'value': 'Sugarcane', 'icon': Icons.ssid_chart, 'description': 'Crop for sugar and bioethanol production'},
    {'value': 'Cotton', 'icon': Icons.dry_cleaning, 'description': 'Fiber crop for textiles and industry'},
    {'value': 'Vegetables', 'icon': Icons.spa_outlined, 'description': 'Mixed horticultural vegetables as main production'},
    {'value': 'Fruits', 'icon': Icons.local_florist_outlined, 'description': 'Mixed fruit orchards or plantations'},
    {'value': 'Other', 'icon': Icons.category, 'description': 'Another primary crop not listed'}
  ];
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      // Primero intentar usar nuestro servicio de ubicaciones de Colombia
      LocationData? nearestCity = LocationService.findNearestCityByCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (nearestCity != null) {
        // Si encontramos una ciudad en nuestro servicio, usarla
        _ubicacionController.text = nearestCity.fullName;
        _showInfo('Location detected: ${nearestCity.fullName}');
        return;
      }
      
      // Si no encontramos en nuestro servicio, usar geocoding como fallback
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String locationName = '';
          String detailedLocation = '';
          
          // Priorizar el nombre del pueblo/ciudad más cercano
          if (place.locality != null && place.locality!.isNotEmpty) {
            // Locality es generalmente la ciudad o pueblo
            locationName = place.locality!;
          } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            // SubLocality puede ser un barrio o área específica
            locationName = place.subLocality!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            // Thoroughfare es la calle o área específica
            locationName = place.thoroughfare!;
          } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
            // SubAdministrativeArea es generalmente el municipio
            locationName = place.subAdministrativeArea!;
          } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            // AdministrativeArea es el estado o provincia
            locationName = place.administrativeArea!;
          }
          
          // Construir ubicación en formato "Ciudad, Departamento"
          String city = place.locality ?? place.subAdministrativeArea ?? locationName;
          String department = place.administrativeArea ?? '';
          
          if (city.isNotEmpty && department.isNotEmpty) {
            detailedLocation = '$city, $department';
          } else {
            // Construir ubicación detallada para mostrar más contexto
            List<String> locationParts = [];
            
            if (place.locality != null && place.locality!.isNotEmpty) {
              locationParts.add(place.locality!);
            }
            if (place.subAdministrativeArea != null && 
                place.subAdministrativeArea!.isNotEmpty && 
                place.subAdministrativeArea != place.locality) {
              locationParts.add(place.subAdministrativeArea!);
            }
            if (place.administrativeArea != null && 
                place.administrativeArea!.isNotEmpty && 
                place.administrativeArea != place.subAdministrativeArea) {
              locationParts.add(place.administrativeArea!);
            }
            
            detailedLocation = locationParts.join(', ');
          }
          
          // Si no se pudo obtener un nombre, usar coordenadas
          if (detailedLocation.isEmpty) {
            detailedLocation = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          }
          
          _ubicacionController.text = detailedLocation;
          
          // Mostrar mensaje específico sobre la ubicación detectada
          String ciudadDetectada = city.isNotEmpty ? city : 'location';
          _showInfo('Location detected: $ciudadDetectada');
        } else {
          // Fallback a coordenadas si no hay placemarks
          _ubicacionController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _showInfo('Location obtained (coordinates)');
        }
      } catch (geocodingError) {
        // Si falla el geocoding, usar coordenadas
        _ubicacionController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _showInfo('Location obtained (coordinates)');
        LoggerService.error('Geocoding error: $geocodingError');
      }
    } catch (e) {
      _showError('Error getting location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 años
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
        // No mantener abierto: modal discreto y cerrable
        _showBirthDatePicker = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      _showError('Please select your birth date');
      return;
    }
    if (_experienciaAgricola == null) {
      _showError('Please select your agricultural experience');
      return;
    }
    if (_tamanoFinca == null) {
      _showError('Please select your farm size');
      return;
    }
    if (_primaryCrops == null) {
      _showError('Please select your primary crops');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      LoggerService.info('SignUp: starting request to Supabase');
      final response = await SupabaseService.client.auth
          .signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: SupabaseService.emailRedirectUrl,
        data: {
          'first_name': _nombreController.text.trim(),
          'last_name': _apellidoController.text.trim(),
          'phone': _telefonoController.text.trim(),
          'location': _ubicacionController.text.trim(),
          'birth_date': DateFormat('yyyy-MM-dd').format(_fechaNacimiento!),
          'farming_experience': _experienciaAgricola,
          'farm_size': _tamanoFinca,
          'farming_type': _primaryCrops,
          'primary_crops': _primaryCrops,
        },
      )
          .timeout(const Duration(seconds: 15));

      // Minimal diagnostics
      LoggerService.info('SignUp: user=${response.user?.email ?? 'null'} redirect=${SupabaseService.emailRedirectUrl}');
      LoggerService.info('SignUp: session exists=${response.session != null}');

      if (response.user != null) {
        if (mounted) {
          // On mobile, redirect to Login screen after registration
          if (!kIsWeb) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created. Please confirm your email, then sign in.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // On web, keep email confirmation instructions screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailConfirmationScreen(
                  userEmail: _emailController.text.trim(),
                ),
              ),
            );
          }
        }
      } else {
        // If user is null (confirmation required), force a resend to ensure email is dispatched
        final email = _emailController.text.trim();
        final sent = await EmailService.resendConfirmationEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                sent
                    ? 'Confirmation email resent. Please check your inbox.'
                    : 'Could not send the confirmation email. Verify configuration.',
              ),
              backgroundColor: sent ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on TimeoutException {
      _showError('Sign up timed out. Check internet and Supabase config.');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
              Colors.green.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back, color: Colors.green.shade700),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      size: 30,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Join AgroTrack',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Únete a AgroTrack',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48), // Balance for back button
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your first name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Apellido
                        TextFormField(
                          controller: _apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your last name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 16),

                        // Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter your phone' : null,
                        ),
                        const SizedBox(height: 16),

                        // Fecha de nacimiento (selección discreta)
                        InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fechaNacimiento == null
                                        ? 'Birth date'
                                        : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                                    style: TextStyle(
                                      color: _fechaNacimiento == null ? Colors.grey.shade600 : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_fechaNacimiento != null)
                                      IconButton(
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.clear),
                                        color: Colors.grey.shade600,
                                        onPressed: () {
                                          setState(() {
                                            _fechaNacimiento = null;
                                          });
                                        },
                                      ),
                                    Icon(Icons.calendar_month, color: Colors.grey.shade600),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Calendario modal: no persistente para no estorbar la UI
                        const SizedBox.shrink(),
                        const SizedBox(height: 16),

                        // Experiencia agrícola
                        DropdownButtonFormField<String>(
                          initialValue: _experienciaAgricola,
                          decoration: InputDecoration(
                            labelText: 'Agricultural experience',
                            prefixIcon: const Icon(Icons.agriculture_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                          fillColor: Colors.grey.shade50,
                          ),
                          isExpanded: true,
                          items: _experienciaOpciones.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _experienciaAgricola = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Select your experience' : null,
                        ),
                        const SizedBox(height: 16),

                        // Tamaño de finca
                        DropdownButtonFormField<String>(
                          initialValue: _tamanoFinca,
                          decoration: InputDecoration(
                            labelText: 'Farm size',
                            prefixIcon: const Icon(Icons.landscape_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                            ),
                            filled: true,
                          fillColor: Colors.grey.shade50,
                          ),
                          isExpanded: true,
                          items: _tamanoFincaOpciones.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _tamanoFinca = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Select your farm size' : null,
                        ),
                        const SizedBox(height: 16),

                        // Primary crops
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _primaryCrops,
                                decoration: InputDecoration(
                                  labelText: 'Primary Crops',
                                  prefixIcon: Icon(
                                    _primaryCrops != null 
                                      ? _primaryCropsOptions.firstWhere(
                                          (option) => option['value'] == _primaryCrops,
                                          orElse: () => {'icon': Icons.local_florist}
                                        )['icon']
                                      : Icons.eco,
                                    color: Colors.green.shade600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                items: _primaryCropsOptions.map((Map<String, dynamic> option) {
                                  return DropdownMenuItem<String>(
                                    value: option['value'],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      child: Text(
                                        option['value'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _primaryCrops = newValue;
                                  });
                                },
                                validator: (v) => v == null ? 'Select your primary crops' : null,
                                isExpanded: true,
                                menuMaxHeight: 300,
                                itemHeight: null, // Altura dinámica automática
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showPrimaryCropsInfo(),
                              icon: const Icon(
                                Icons.help_outline,
                                color: Colors.green,
                                size: 24,
                              ),
                              tooltip: 'See primary crop descriptions',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ubicación
                        LocationSearchField(
                          controller: _ubicacionController,
                          labelText: 'Location',
                          hintText: 'Search city and state (e.g: Pasto, Nariño)',
                          validator: (v) => (v == null || v.isEmpty) ? 'Select your location' : null,
                          onLocationSelected: () {
                            // Opcional: agregar lógica adicional cuando se selecciona una ubicación
                          },
                        ),
                        const SizedBox(height: 8),
                        
                        // Botón para obtener ubicación actual
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                icon: _isLoadingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location),
                                label: Text(_isLoadingLocation 
                                    ? 'Getting location...' 
                                    : 'Use my current location'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green.shade600,
                                  side: BorderSide(color: Colors.green.shade600),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botón de registro
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add),
                                      SizedBox(width: 8),
                                      Text(
                                        'Join AgroTrack',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Texto de términos
                        Text(
                          'By creating an account, you accept our terms and conditions of use.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
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

  void _showPrimaryCropsInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Primary Crops',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _primaryCropsOptions.length,
              itemBuilder: (context, index) {
                final tipo = _primaryCropsOptions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              tipo['icon'],
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tipo['value'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPrimaryCropsDescription(tipo['value']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPrimaryCropsDescription(String crop) {
    switch (crop) {
      case 'Corn (Maize)':
        return 'Staple cereal used for food, feed, silage, and biofuel.';
      case 'Wheat':
        return 'Major cereal grain processed into flour, bread, and pasta.';
      case 'Rice':
        return 'Primary staple food crop; grown in paddies or upland systems.';
      case 'Soybeans':
        return 'Legume for edible oil, animal feed, tofu, and protein products.';
      case 'Coffee':
        return 'Tropical beverage crop; arabica/robusta varieties for roasting.';
      case 'Cocoa':
        return 'Beans processed into chocolate; requires humid tropical climates.';
      case 'Banana/Plantain':
        return 'Tropical fruit; plantain commonly used cooked; banana eaten fresh.';
      case 'Sugarcane':
        return 'Industrial crop for sugar, molasses, and bioethanol production.';
      case 'Cotton':
        return 'Fiber crop used in textiles; requires warm climates and management.';
      case 'Vegetables':
        return 'Horticultural crops such as leafy greens, roots, and fruiting veg.';
      case 'Fruits':
        return 'Orchard or tropical fruit crops; fresh market or processing.';
      case 'Other':
        return 'Another primary crop as main production focus.';
      default:
        return 'Description not available.';
    }
  }
}
