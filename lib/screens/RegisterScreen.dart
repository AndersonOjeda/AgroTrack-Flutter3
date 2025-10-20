import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../widgets/location_search_field.dart';
import 'EmailConfirmationScreen.dart';

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
  String? _experienciaAgricola;
  String? _tamanoFinca;
  String? _tipoAgricultura;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  bool _obscurePassword = true;

  final List<String> _experienciaOpciones = [
    'Nuevo en la agricultura (menos de 1 año)',
    'Principiante (1-3 años)',
    'Con experiencia (4-10 años)',
    'Muy experimentado (11-20 años)',
    'Experto (más de 20 años)'
  ];

  final List<String> _tamanoFincaOpciones = [
    'Pequeña (menos de 1 hectárea)',
    'Mediana (1-5 hectáreas)',
    'Grande (más de 5 hectáreas)'
  ];

  final List<Map<String, dynamic>> _tipoAgriculturaOpciones = [
    {
      'value': 'Agricultura orgánica',
      'icon': Icons.eco,
      'description': 'Sin pesticidas ni fertilizantes químicos'
    },
    {
      'value': 'Agricultura convencional',
      'icon': Icons.agriculture,
      'description': 'Métodos tradicionales con tecnología moderna'
    },
    {
      'value': 'Agricultura hidropónica',
      'icon': Icons.water_drop,
      'description': 'Cultivo en soluciones nutritivas sin suelo'
    },
    {
      'value': 'Agricultura de precisión',
      'icon': Icons.gps_fixed,
      'description': 'Uso de tecnología GPS y sensores'
    },
    {
      'value': 'Permacultura',
      'icon': Icons.nature_people,
      'description': 'Diseño sostenible de sistemas agrícolas'
    },
    {
      'value': 'Agricultura vertical',
      'icon': Icons.layers,
      'description': 'Cultivo en estructuras verticales'
    },
    {
      'value': 'Agroecología',
      'icon': Icons.forest,
      'description': 'Integración de principios ecológicos'
    },
    {
      'value': 'Agricultura regenerativa',
      'icon': Icons.refresh,
      'description': 'Restauración de la salud del suelo'
    }
  ];
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Los servicios de ubicación están deshabilitados.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permisos de ubicación denegados.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permisos de ubicación denegados permanentemente.');
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
        _showInfo('Ubicación detectada: ${nearestCity.fullName}');
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
          String ciudadDetectada = city.isNotEmpty ? city : 'ubicación';
          _showInfo('Ubicación detectada: $ciudadDetectada');
        } else {
          // Fallback a coordenadas si no hay placemarks
          _ubicacionController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _showInfo('Ubicación obtenida (coordenadas)');
        }
      } catch (geocodingError) {
        // Si falla el geocoding, usar coordenadas
        _ubicacionController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _showInfo('Ubicación obtenida (coordenadas)');
        print('Error de geocoding: $geocodingError');
      }
    } catch (e) {
      _showError('Error al obtener la ubicación: $e');
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
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      _showError('Por favor selecciona tu fecha de nacimiento');
      return;
    }
    if (_experienciaAgricola == null) {
      _showError('Por favor selecciona tu experiencia agrícola');
      return;
    }
    if (_tamanoFinca == null) {
      _showError('Por favor selecciona el tamaño de tu finca');
      return;
    }
    if (_tipoAgricultura == null) {
      _showError('Por favor selecciona el tipo de agricultura');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
          'experiencia_agricola': _experienciaAgricola,
          'tamano_finca': _tamanoFinca,
          'tipo_agricultura': _tipoAgricultura,
        },
      );

      if (response.user != null) {
        // Navegar a la pantalla de confirmación de email
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailConfirmationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado: $e');
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
                                    'Crear Cuenta',
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
                            labelText: 'Nombre',
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
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 16),

                        // Apellido
                        TextFormField(
                          controller: _apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
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
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu apellido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
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
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu correo' : null,
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
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
                          validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
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
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu teléfono' : null,
                        ),
                        const SizedBox(height: 16),

                        // Fecha de nacimiento
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
                                        ? 'Fecha de nacimiento'
                                        : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                                    style: TextStyle(
                                      color: _fechaNacimiento == null ? Colors.grey.shade600 : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Experiencia agrícola
                        DropdownButtonFormField<String>(
                          value: _experienciaAgricola,
                          decoration: InputDecoration(
                            labelText: 'Experiencia agrícola',
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
                          validator: (v) => v == null ? 'Selecciona tu experiencia' : null,
                        ),
                        const SizedBox(height: 16),

                        // Tamaño de finca
                        DropdownButtonFormField<String>(
                          value: _tamanoFinca,
                          decoration: InputDecoration(
                            labelText: 'Tamaño de finca',
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
                          validator: (v) => v == null ? 'Selecciona el tamaño de tu finca' : null,
                        ),
                        const SizedBox(height: 16),

                        // Tipo de agricultura
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _tipoAgricultura,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de agricultura',
                                  prefixIcon: Icon(
                                    _tipoAgricultura != null 
                                      ? _tipoAgriculturaOpciones.firstWhere(
                                          (option) => option['value'] == _tipoAgricultura,
                                          orElse: () => {'icon': Icons.eco}
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
                                items: _tipoAgriculturaOpciones.map((Map<String, dynamic> option) {
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
                                    _tipoAgricultura = newValue;
                                  });
                                },
                                validator: (v) => v == null ? 'Selecciona el tipo de agricultura' : null,
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
                              onPressed: () => _mostrarDefinicionesAgricultura(),
                              icon: const Icon(
                                Icons.help_outline,
                                color: Colors.green,
                                size: 24,
                              ),
                              tooltip: 'Ver definiciones de tipos de agricultura',
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
                          labelText: 'Ubicación',
                          hintText: 'Buscar ciudad y departamento (ej: Pasto, Nariño)',
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecciona tu ubicación' : null,
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
                                    ? 'Obteniendo ubicación...' 
                                    : 'Usar mi ubicación actual'),
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
                                        'Crear Cuenta',
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
                          'Al crear una cuenta, aceptas nuestros términos y condiciones de uso.',
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

  void _mostrarDefinicionesAgricultura() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Tipos de Agricultura',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _tipoAgriculturaOpciones.length,
              itemBuilder: (context, index) {
                final tipo = _tipoAgriculturaOpciones[index];
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
                          _getDefinicionCompleta(tipo['value']),
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

  String _getDefinicionCompleta(String tipoAgricultura) {
    switch (tipoAgricultura) {
      case 'Agricultura orgánica':
        return 'Sistema de producción que evita el uso de fertilizantes sintéticos, pesticidas, reguladores de crecimiento y aditivos para el ganado. Se basa en el uso de abonos orgánicos, rotación de cultivos y control biológico de plagas para mantener la fertilidad del suelo y controlar las plagas.';
      
      case 'Agricultura convencional':
        return 'Método de agricultura que utiliza fertilizantes sintéticos, pesticidas químicos y técnicas modernas de mecanización. Es el sistema más común y busca maximizar la producción mediante el uso de tecnología y productos químicos aprobados.';
      
      case 'Agricultura hidropónica':
        return 'Técnica de cultivo que no utiliza suelo, sino que las plantas crecen en soluciones nutritivas líquidas. Permite un control preciso de los nutrientes y puede realizarse en espacios reducidos con mayor eficiencia en el uso del agua.';
      
      case 'Agricultura de precisión':
        return 'Sistema de manejo agrícola que utiliza tecnologías como GPS, sensores, drones y análisis de datos para optimizar el rendimiento de los cultivos. Permite aplicar insumos de manera variable según las necesidades específicas de cada zona del campo.';
      
      case 'Permacultura':
        return 'Filosofía y método de diseño que busca crear sistemas agrícolas sostenibles y autosuficientes. Se basa en principios éticos y de diseño que imitan los patrones naturales para crear ecosistemas productivos y resilientes.';
      
      case 'Agricultura vertical':
        return 'Método de cultivo que utiliza estructuras verticales apiladas para producir alimentos en espacios reducidos. Comúnmente se combina con hidroponía y iluminación LED controlada, siendo ideal para áreas urbanas.';
      
      case 'Agroecología':
        return 'Enfoque científico que aplica principios ecológicos al diseño y manejo de sistemas agrícolas sostenibles. Integra aspectos ambientales, sociales y económicos para crear sistemas productivos que respeten los ciclos naturales.';
      
      case 'Agricultura regenerativa':
        return 'Sistema de cultivo que se enfoca en regenerar y mejorar la salud del suelo mediante prácticas como cultivos de cobertura, rotación diversa, pastoreo rotacional y minimización del laboreo. Busca capturar carbono y restaurar la biodiversidad.';
      
      default:
        return 'Definición no disponible.';
    }
  }
}