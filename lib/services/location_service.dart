class LocationData {
  final String city;
  final String department;
  final String fullName;
  final double? latitude;
  final double? longitude;
  final String name;
  final String displayName;

  LocationData({
    required this.city,
    required this.department,
    this.latitude,
    this.longitude,
  }) : fullName = '$city, $department',
       name = city,
       displayName = '$city, $department';

  @override
  String toString() => fullName;
}

class LocationService {
  static final List<LocationData> _colombianCities = [
    // Antioquia
    LocationData(city: 'Medellín', department: 'Antioquia', latitude: 6.2442, longitude: -75.5812),
    LocationData(city: 'Bello', department: 'Antioquia', latitude: 6.3370, longitude: -75.5547),
    LocationData(city: 'Itagüí', department: 'Antioquia', latitude: 6.1845, longitude: -75.5990),
    LocationData(city: 'Envigado', department: 'Antioquia', latitude: 6.1698, longitude: -75.5890),
    LocationData(city: 'Apartadó', department: 'Antioquia', latitude: 7.8814, longitude: -76.6256),
    LocationData(city: 'Turbo', department: 'Antioquia', latitude: 8.0956, longitude: -76.7275),
    LocationData(city: 'Rionegro', department: 'Antioquia', latitude: 6.1555, longitude: -75.3736),
    LocationData(city: 'Sabaneta', department: 'Antioquia', latitude: 6.1513, longitude: -75.6169),
    LocationData(city: 'La Estrella', department: 'Antioquia', latitude: 6.1583, longitude: -75.6417),
    LocationData(city: 'Copacabana', department: 'Antioquia', latitude: 6.3467, longitude: -75.5081),
    
    // Bogotá D.C.
    LocationData(city: 'Bogotá', department: 'Cundinamarca', latitude: 4.7110, longitude: -74.0721),
    
    // Valle del Cauca
    LocationData(city: 'Cali', department: 'Valle del Cauca', latitude: 3.4516, longitude: -76.5320),
    LocationData(city: 'Palmira', department: 'Valle del Cauca', latitude: 3.5394, longitude: -76.3036),
    LocationData(city: 'Buenaventura', department: 'Valle del Cauca', latitude: 3.8801, longitude: -77.0135),
    LocationData(city: 'Tuluá', department: 'Valle del Cauca', latitude: 4.0845, longitude: -76.1955),
    LocationData(city: 'Cartago', department: 'Valle del Cauca', latitude: 4.7467, longitude: -75.9114),
    LocationData(city: 'Buga', department: 'Valle del Cauca', latitude: 3.9006, longitude: -76.2978),
    LocationData(city: 'Jamundí', department: 'Valle del Cauca', latitude: 3.2606, longitude: -76.5447),
    LocationData(city: 'Yumbo', department: 'Valle del Cauca', latitude: 3.5889, longitude: -76.4986),
    
    // Atlántico
    LocationData(city: 'Barranquilla', department: 'Atlántico', latitude: 10.9639, longitude: -74.7964),
    LocationData(city: 'Soledad', department: 'Atlántico', latitude: 10.9185, longitude: -74.7644),
    LocationData(city: 'Malambo', department: 'Atlántico', latitude: 10.8594, longitude: -74.7739),
    LocationData(city: 'Sabanagrande', department: 'Atlántico', latitude: 10.7906, longitude: -74.7556),
    LocationData(city: 'Puerto Colombia', department: 'Atlántico', latitude: 10.9878, longitude: -74.9547),
    
    // Santander
    LocationData(city: 'Bucaramanga', department: 'Santander', latitude: 7.1253, longitude: -73.1198),
    LocationData(city: 'Floridablanca', department: 'Santander', latitude: 7.0619, longitude: -73.0864),
    LocationData(city: 'Girón', department: 'Santander', latitude: 7.0697, longitude: -73.1692),
    LocationData(city: 'Piedecuesta', department: 'Santander', latitude: 6.9889, longitude: -73.0500),
    LocationData(city: 'Barrancabermeja', department: 'Santander', latitude: 7.0653, longitude: -73.8547),
    LocationData(city: 'San Gil', department: 'Santander', latitude: 6.5581, longitude: -73.1339),
    
    // Cundinamarca
    LocationData(city: 'Soacha', department: 'Cundinamarca', latitude: 4.5928, longitude: -74.2175),
    LocationData(city: 'Chía', department: 'Cundinamarca', latitude: 4.8614, longitude: -74.0581),
    LocationData(city: 'Zipaquirá', department: 'Cundinamarca', latitude: 5.0219, longitude: -74.0042),
    LocationData(city: 'Facatativá', department: 'Cundinamarca', latitude: 4.8144, longitude: -74.3553),
    LocationData(city: 'Cajicá', department: 'Cundinamarca', latitude: 4.9186, longitude: -74.0281),
    LocationData(city: 'Fusagasugá', department: 'Cundinamarca', latitude: 4.3386, longitude: -74.3636),
    LocationData(city: 'Madrid', department: 'Cundinamarca', latitude: 4.7306, longitude: -74.2639),
    LocationData(city: 'Mosquera', department: 'Cundinamarca', latitude: 4.7058, longitude: -74.2306),
    LocationData(city: 'Funza', department: 'Cundinamarca', latitude: 4.7167, longitude: -74.2089),
    LocationData(city: 'Girardot', department: 'Cundinamarca', latitude: 4.3017, longitude: -74.8069),
    
    // Bolívar
    LocationData(city: 'Cartagena', department: 'Bolívar', latitude: 10.3910, longitude: -75.4794),
    LocationData(city: 'Magangué', department: 'Bolívar', latitude: 9.2417, longitude: -74.7547),
    LocationData(city: 'Turbaco', department: 'Bolívar', latitude: 10.3358, longitude: -75.4236),
    
    // Norte de Santander
    LocationData(city: 'Cúcuta', department: 'Norte de Santander', latitude: 7.8939, longitude: -72.5078),
    LocationData(city: 'Villa del Rosario', department: 'Norte de Santander', latitude: 7.8333, longitude: -72.4667),
    LocationData(city: 'Los Patios', department: 'Norte de Santander', latitude: 7.8500, longitude: -72.5000),
    LocationData(city: 'Ocaña', department: 'Norte de Santander', latitude: 8.2400, longitude: -73.3547),
    
    // Córdoba
    LocationData(city: 'Montería', department: 'Córdoba', latitude: 8.7479, longitude: -75.8814),
    LocationData(city: 'Lorica', department: 'Córdoba', latitude: 9.2400, longitude: -75.8167),
    LocationData(city: 'Cereté', department: 'Córdoba', latitude: 8.8850, longitude: -75.7917),
    LocationData(city: 'Sahagún', department: 'Córdoba', latitude: 8.9467, longitude: -75.4433),
    
    // Tolima
    LocationData(city: 'Ibagué', department: 'Tolima', latitude: 4.4389, longitude: -75.2322),
    LocationData(city: 'Espinal', department: 'Tolima', latitude: 4.1489, longitude: -74.8839),
    LocationData(city: 'Melgar', department: 'Tolima', latitude: 4.2067, longitude: -74.6417),
    LocationData(city: 'Honda', department: 'Tolima', latitude: 5.2089, longitude: -74.7358),
    
    // Huila
    LocationData(city: 'Neiva', department: 'Huila', latitude: 2.9273, longitude: -75.2819),
    LocationData(city: 'Pitalito', department: 'Huila', latitude: 1.8533, longitude: -76.0506),
    LocationData(city: 'Garzón', department: 'Huila', latitude: 2.1967, longitude: -75.6267),
    LocationData(city: 'La Plata', department: 'Huila', latitude: 2.3833, longitude: -75.8833),
    
    // Nariño
    LocationData(city: 'Pasto', department: 'Nariño', latitude: 1.2136, longitude: -77.2811),
    LocationData(city: 'Chachagüí', department: 'Nariño', latitude: 1.1833, longitude: -77.2833),
    LocationData(city: 'Tumaco', department: 'Nariño', latitude: 1.8014, longitude: -78.7647),
    LocationData(city: 'Ipiales', department: 'Nariño', latitude: 0.8317, longitude: -77.6419),
    LocationData(city: 'Túquerres', department: 'Nariño', latitude: 1.0833, longitude: -77.6167),
    LocationData(city: 'Sandona', department: 'Nariño', latitude: 1.2833, longitude: -77.4667),
    LocationData(city: 'La Unión', department: 'Nariño', latitude: 1.6000, longitude: -77.1333),
    LocationData(city: 'Tangua', department: 'Nariño', latitude: 1.0167, longitude: -77.7500),
    LocationData(city: 'Yacuanquer', department: 'Nariño', latitude: 1.1333, longitude: -77.4167),
    LocationData(city: 'Consacá', department: 'Nariño', latitude: 1.2167, longitude: -77.5167),
    LocationData(city: 'Nariño', department: 'Nariño', latitude: 1.2833, longitude: -77.3500),
    LocationData(city: 'La Florida', department: 'Nariño', latitude: 1.3000, longitude: -77.3667),

    // Cauca
    LocationData(city: 'Popayán', department: 'Cauca', latitude: 2.4448, longitude: -76.6147),
    LocationData(city: 'Santander de Quilichao', department: 'Cauca', latitude: 3.0067, longitude: -76.4833),
    LocationData(city: 'Puerto Tejada', department: 'Cauca', latitude: 3.2333, longitude: -76.4167),
    
    // Risaralda
    LocationData(city: 'Pereira', department: 'Risaralda', latitude: 4.8133, longitude: -75.6961),
    LocationData(city: 'Dosquebradas', department: 'Risaralda', latitude: 4.8356, longitude: -75.6689),
    LocationData(city: 'La Virginia', department: 'Risaralda', latitude: 4.9000, longitude: -75.8833),
    LocationData(city: 'Santa Rosa de Cabal', department: 'Risaralda', latitude: 4.8667, longitude: -75.6167),
    
    // Quindío
    LocationData(city: 'Armenia', department: 'Quindío', latitude: 4.5339, longitude: -75.6811),
    LocationData(city: 'Calarcá', department: 'Quindío', latitude: 4.5289, longitude: -75.6447),
    LocationData(city: 'La Tebaida', department: 'Quindío', latitude: 4.4333, longitude: -75.7833),
    LocationData(city: 'Montenegro', department: 'Quindío', latitude: 4.5667, longitude: -75.7500),
    
    // Caldas
    LocationData(city: 'Manizales', department: 'Caldas', latitude: 5.0703, longitude: -75.5138),
    LocationData(city: 'Villamaría', department: 'Caldas', latitude: 5.0333, longitude: -75.5167),
    LocationData(city: 'Chinchiná', department: 'Caldas', latitude: 4.9833, longitude: -75.6000),
    LocationData(city: 'La Dorada', department: 'Caldas', latitude: 5.4489, longitude: -74.6658),
    
    // Boyacá
    LocationData(city: 'Tunja', department: 'Boyacá', latitude: 5.5353, longitude: -73.3678),
    LocationData(city: 'Duitama', department: 'Boyacá', latitude: 5.8244, longitude: -73.0347),
    LocationData(city: 'Sogamoso', department: 'Boyacá', latitude: 5.7147, longitude: -72.9342),
    LocationData(city: 'Chiquinquirá', department: 'Boyacá', latitude: 5.6167, longitude: -73.8167),
    
    // Meta
    LocationData(city: 'Villavicencio', department: 'Meta', latitude: 4.1420, longitude: -73.6266),
    LocationData(city: 'Acacías', department: 'Meta', latitude: 3.9889, longitude: -73.7611),
    LocationData(city: 'Granada', department: 'Meta', latitude: 3.5333, longitude: -73.7000),
    
    // Cesar
    LocationData(city: 'Valledupar', department: 'Cesar', latitude: 10.4631, longitude: -73.2532),
    LocationData(city: 'Aguachica', department: 'Cesar', latitude: 8.3167, longitude: -73.6167),
    LocationData(city: 'Codazzi', department: 'Cesar', latitude: 10.0333, longitude: -73.2500),
    
    // Magdalena
    LocationData(city: 'Santa Marta', department: 'Magdalena', latitude: 11.2408, longitude: -74.1990),
    LocationData(city: 'Ciénaga', department: 'Magdalena', latitude: 11.0067, longitude: -74.2467),
    LocationData(city: 'Fundación', department: 'Magdalena', latitude: 10.5200, longitude: -74.1850),
    
    // Sucre
    LocationData(city: 'Sincelejo', department: 'Sucre', latitude: 9.3047, longitude: -75.3978),
    LocationData(city: 'Corozal', department: 'Sucre', latitude: 9.3167, longitude: -75.2833),
    
    // La Guajira
    LocationData(city: 'Riohacha', department: 'La Guajira', latitude: 11.5444, longitude: -72.9069),
    LocationData(city: 'Maicao', department: 'La Guajira', latitude: 11.3833, longitude: -72.2500),
    
    // Casanare
    LocationData(city: 'Yopal', department: 'Casanare', latitude: 5.3378, longitude: -72.3958),
    LocationData(city: 'Aguazul', department: 'Casanare', latitude: 5.1667, longitude: -72.5333),
    
    // Caquetá
    LocationData(city: 'Florencia', department: 'Caquetá', latitude: 1.6144, longitude: -75.6062),
    LocationData(city: 'San Vicente del Caguán', department: 'Caquetá', latitude: 2.1167, longitude: -74.7667),
    
    // Putumayo
    LocationData(city: 'Mocoa', department: 'Putumayo', latitude: 1.1533, longitude: -76.6511),
    LocationData(city: 'Puerto Asís', department: 'Putumayo', latitude: 0.5167, longitude: -76.5000),
    
    // Arauca
    LocationData(city: 'Arauca', department: 'Arauca', latitude: 7.0833, longitude: -70.7667),
    LocationData(city: 'Tame', department: 'Arauca', latitude: 6.4667, longitude: -71.7333),
    
    // Amazonas
    LocationData(city: 'Leticia', department: 'Amazonas', latitude: -4.2153, longitude: -69.9406),
    
    // Chocó
    LocationData(city: 'Quibdó', department: 'Chocó', latitude: 5.6947, longitude: -76.6581),
    
    // Guainía
    LocationData(city: 'Inírida', department: 'Guainía', latitude: 3.8653, longitude: -67.9239),
    
    // Guaviare
    LocationData(city: 'San José del Guaviare', department: 'Guaviare', latitude: 2.5667, longitude: -72.6333),
    
    // Vaupés
    LocationData(city: 'Mitú', department: 'Vaupés'),
    
    // Vichada
    LocationData(city: 'Puerto Carreño', department: 'Vichada'),
    
    // San Andrés y Providencia
    LocationData(city: 'San Andrés', department: 'San Andrés y Providencia'),
  ];

  /// Busca ciudades que coincidan con el texto de búsqueda
  static List<LocationData> searchCities(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    
    return _colombianCities.where((location) {
      return location.city.toLowerCase().contains(lowerQuery) ||
             location.department.toLowerCase().contains(lowerQuery) ||
             location.fullName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Obtiene todas las ciudades disponibles
  static List<LocationData> getAllCities() {
    return List.from(_colombianCities);
  }

  /// Obtiene todos los departamentos únicos
  static List<String> getAllDepartments() {
    return _colombianCities
        .map((location) => location.department)
        .toSet()
        .toList()
        ..sort();
  }

  /// Obtiene ciudades por departamento
  static List<LocationData> getCitiesByDepartment(String department) {
    return _colombianCities
        .where((location) => location.department == department)
        .toList();
  }

  /// Encuentra la ciudad más cercana basada en coordenadas GPS
  /// Utiliza una aproximación simple basada en nombres de lugares conocidos
  static LocationData? findNearestCityByCoordinates(double latitude, double longitude) {
    // Mapeo aproximado de coordenadas a ciudades principales de Colombia
    // Basado en rangos geográficos conocidos
    
    // Región Andina - Nariño - Chachagüí (área específica)
    // Chachagüí: 1.3873° N, -77.2693° W
    if (latitude >= 1.35 && latitude <= 1.42 && longitude >= -77.30 && longitude <= -77.24) {
      return LocationData(city: 'Chachagüí', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Pasto (área específica)
    // Pasto: 1.2058° N, -77.2857° W
    if (latitude >= 1.15 && latitude <= 1.35 && longitude >= -77.35 && longitude <= -77.20) {
      return LocationData(city: 'Pasto', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Ipiales (área específica)
    if (latitude >= 0.80 && latitude <= 0.90 && longitude >= -77.70 && longitude <= -77.60) {
      return LocationData(city: 'Ipiales', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Túquerres (área específica)
    if (latitude >= 1.05 && latitude <= 1.15 && longitude >= -77.70 && longitude <= -77.60) {
      return LocationData(city: 'Túquerres', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Sandona (área específica)
    if (latitude >= 1.25 && latitude <= 1.35 && longitude >= -77.50 && longitude <= -77.40) {
      return LocationData(city: 'Sandona', department: 'Nariño');
    }
    
    // Región Andina - Nariño - La Unión (área específica)
    if (latitude >= 1.55 && latitude <= 1.65 && longitude >= -77.20 && longitude <= -77.10) {
      return LocationData(city: 'La Unión', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Tangua (área específica)
    if (latitude >= 1.05 && latitude <= 1.15 && longitude >= -77.30 && longitude <= -77.20) {
      return LocationData(city: 'Tangua', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Yacuanquer (área específica)
    if (latitude >= 1.10 && latitude <= 1.20 && longitude >= -77.40 && longitude <= -77.30) {
      return LocationData(city: 'Yacuanquer', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Consacá (área específica)
    if (latitude >= 1.15 && latitude <= 1.25 && longitude >= -77.60 && longitude <= -77.50) {
      return LocationData(city: 'Consacá', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Nariño (área específica)
    if (latitude >= 1.25 && latitude <= 1.35 && longitude >= -77.35 && longitude <= -77.25) {
      return LocationData(city: 'Nariño', department: 'Nariño');
    }
    
    // Región Andina - Nariño - La Florida (área específica)
    if (latitude >= 1.30 && latitude <= 1.40 && longitude >= -77.40 && longitude <= -77.30) {
      return LocationData(city: 'La Florida', department: 'Nariño');
    }
    
    // Región Andina - Nariño - Tumaco (área específica)
    if (latitude >= 1.75 && latitude <= 1.85 && longitude >= -78.85 && longitude <= -78.75) {
      return LocationData(city: 'Tumaco', department: 'Nariño');
    }
    
    // Región Andina - Nariño (área general - fallback)
    if (latitude >= 0.5 && latitude <= 2.0 && longitude >= -78.0 && longitude <= -76.5) {
      return LocationData(city: 'Pasto', department: 'Nariño');
    }
    
    // Región Andina - Cauca (Popayán y alrededores)
    if (latitude >= 2.0 && latitude <= 3.0 && longitude >= -77.5 && longitude <= -75.5) {
      return LocationData(city: 'Popayán', department: 'Cauca');
    }
    
    // Valle del Cauca (Cali y alrededores)
    if (latitude >= 3.0 && latitude <= 4.5 && longitude >= -77.5 && longitude <= -75.5) {
      return LocationData(city: 'Cali', department: 'Valle del Cauca');
    }
    
    // Cundinamarca (Bogotá y alrededores)
    if (latitude >= 4.0 && latitude <= 5.5 && longitude >= -75.0 && longitude <= -73.5) {
      return LocationData(city: 'Bogotá', department: 'Cundinamarca');
    }
    
    // Antioquia (Medellín y alrededores)
    if (latitude >= 5.5 && latitude <= 7.5 && longitude >= -76.5 && longitude <= -74.5) {
      return LocationData(city: 'Medellín', department: 'Antioquia');
    }
    
    // Santander (Bucaramanga y alrededores)
    if (latitude >= 6.5 && latitude <= 8.0 && longitude >= -74.5 && longitude <= -72.5) {
      return LocationData(city: 'Bucaramanga', department: 'Santander');
    }
    
    // Atlántico (Barranquilla y alrededores)
    if (latitude >= 10.5 && latitude <= 11.5 && longitude >= -75.5 && longitude <= -74.5) {
      return LocationData(city: 'Barranquilla', department: 'Atlántico');
    }
    
    // Bolívar (Cartagena y alrededores)
    if (latitude >= 10.0 && latitude <= 11.0 && longitude >= -76.0 && longitude <= -75.0) {
      return LocationData(city: 'Cartagena', department: 'Bolívar');
    }
    
    // Huila (Neiva y alrededores)
    if (latitude >= 2.5 && latitude <= 3.5 && longitude >= -76.0 && longitude <= -74.5) {
      return LocationData(city: 'Neiva', department: 'Huila');
    }
    
    // Tolima (Ibagué y alrededores)
    if (latitude >= 4.0 && latitude <= 5.0 && longitude >= -76.0 && longitude <= -74.5) {
      return LocationData(city: 'Ibagué', department: 'Tolima');
    }
    
    // Caldas (Manizales y alrededores)
    if (latitude >= 4.5 && latitude <= 5.5 && longitude >= -76.0 && longitude <= -75.0) {
      return LocationData(city: 'Manizales', department: 'Caldas');
    }
    
    // Risaralda (Pereira y alrededores)
    if (latitude >= 4.5 && latitude <= 5.5 && longitude >= -76.5 && longitude <= -75.5) {
      return LocationData(city: 'Pereira', department: 'Risaralda');
    }
    
    // Quindío (Armenia y alrededores)
    if (latitude >= 4.0 && latitude <= 5.0 && longitude >= -76.0 && longitude <= -75.0) {
      return LocationData(city: 'Armenia', department: 'Quindío');
    }
    
    // Norte de Santander (Cúcuta y alrededores)
    if (latitude >= 7.5 && latitude <= 8.5 && longitude >= -73.5 && longitude <= -72.0) {
      return LocationData(city: 'Cúcuta', department: 'Norte de Santander');
    }
    
    // Córdoba (Montería y alrededores)
    if (latitude >= 8.0 && latitude <= 9.5 && longitude >= -76.5 && longitude <= -75.0) {
      return LocationData(city: 'Montería', department: 'Córdoba');
    }
    
    // Sucre (Sincelejo y alrededores)
    if (latitude >= 9.0 && latitude <= 10.0 && longitude >= -76.0 && longitude <= -75.0) {
      return LocationData(city: 'Sincelejo', department: 'Sucre');
    }
    
    // Meta (Villavicencio y alrededores)
    if (latitude >= 3.5 && latitude <= 4.5 && longitude >= -74.0 && longitude <= -72.5) {
      return LocationData(city: 'Villavicencio', department: 'Meta');
    }
    
    // Boyacá (Tunja y alrededores)
    if (latitude >= 5.0 && latitude <= 6.0 && longitude >= -74.0 && longitude <= -72.5) {
      return LocationData(city: 'Tunja', department: 'Boyacá');
    }
    
    // Cesar (Valledupar y alrededores)
    if (latitude >= 9.5 && latitude <= 11.0 && longitude >= -74.5 && longitude <= -73.0) {
      return LocationData(city: 'Valledupar', department: 'Cesar');
    }
    
    // La Guajira (Riohacha y alrededores)
    if (latitude >= 11.0 && latitude <= 12.5 && longitude >= -73.5 && longitude <= -71.0) {
      return LocationData(city: 'Riohacha', department: 'La Guajira');
    }
    
    // Magdalena (Santa Marta y alrededores)
    if (latitude >= 10.5 && latitude <= 11.5 && longitude >= -75.0 && longitude <= -73.5) {
      return LocationData(city: 'Santa Marta', department: 'Magdalena');
    }
    
    // Casanare (Yopal y alrededores)
    if (latitude >= 5.0 && latitude <= 6.5 && longitude >= -73.0 && longitude <= -71.0) {
      return LocationData(city: 'Yopal', department: 'Casanare');
    }
    
    // Arauca (Arauca y alrededores)
    if (latitude >= 6.5 && latitude <= 7.5 && longitude >= -71.5 && longitude <= -70.0) {
      return LocationData(city: 'Arauca', department: 'Arauca');
    }
    
    // Caquetá (Florencia y alrededores)
    if (latitude >= 1.0 && latitude <= 2.5 && longitude >= -76.5 && longitude <= -74.5) {
      return LocationData(city: 'Florencia', department: 'Caquetá');
    }
    
    // Putumayo (Mocoa y alrededores)
    if (latitude >= 0.5 && latitude <= 1.5 && longitude >= -77.5 && longitude <= -75.5) {
      return LocationData(city: 'Mocoa', department: 'Putumayo');
    }
    
    // Amazonas (Leticia y alrededores)
    if (latitude >= -5.0 && latitude <= -3.5 && longitude >= -71.0 && longitude <= -69.0) {
      return LocationData(city: 'Leticia', department: 'Amazonas');
    }
    
    // Chocó (Quibdó y alrededores)
    if (latitude >= 4.5 && latitude <= 7.5 && longitude >= -78.0 && longitude <= -76.0) {
      return LocationData(city: 'Quibdó', department: 'Chocó');
    }
    
    // Vichada (Puerto Carreño y alrededores)
    if (latitude >= 5.5 && latitude <= 7.0 && longitude >= -68.5 && longitude <= -67.0) {
      return LocationData(city: 'Puerto Carreño', department: 'Vichada');
    }
    
    // Guainía (Inírida y alrededores)
    if (latitude >= 3.0 && latitude <= 4.5 && longitude >= -68.5 && longitude <= -67.0) {
      return LocationData(city: 'Inírida', department: 'Guainía');
    }
    
    // Vaupés (Mitú y alrededores)
    if (latitude >= 0.5 && latitude <= 2.0 && longitude >= -71.0 && longitude <= -69.5) {
      return LocationData(city: 'Mitú', department: 'Vaupés');
    }
    
    // Guaviare (San José del Guaviare y alrededores)
    if (latitude >= 1.5 && latitude <= 3.0 && longitude >= -73.5 && longitude <= -71.5) {
      return LocationData(city: 'San José del Guaviare', department: 'Guaviare');
    }
    
    // Si no coincide con ninguna región, devolver null
    return null;
  }

  /// Busca ubicaciones en Colombia basado en una consulta de texto
  static Future<List<LocationData>> searchLocationsInColombia(String query) async {
    if (query.trim().isEmpty) return [];
    
    final results = searchCities(query);
    
    // Limitar a 10 resultados para mejor rendimiento
    return results.take(10).toList();
  }

  /// Obtiene el nombre de una ubicación basado en coordenadas
  static Future<String> getLocationName(double latitude, double longitude) async {
    try {
      // Intentar encontrar la ciudad más cercana usando nuestro servicio
      final nearestCity = findNearestCityByCoordinates(latitude, longitude);
      
      if (nearestCity != null) {
        return nearestCity.fullName;
      }
      
      // Si no encontramos una ciudad cercana, devolver coordenadas
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      return 'Ubicación desconocida';
    }
  }
}