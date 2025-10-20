class LocationData {
  final String city;
  final String department;
  final String fullName;
  final double? latitude;
  final double? longitude;

  LocationData({
    required this.city,
    required this.department,
    this.latitude,
    this.longitude,
  }) : fullName = '$city, $department';

  @override
  String toString() => fullName;
}

class LocationService {
  static final List<LocationData> _colombianCities = [
    // Antioquia
    LocationData(city: 'Medellín', department: 'Antioquia'),
    LocationData(city: 'Bello', department: 'Antioquia'),
    LocationData(city: 'Itagüí', department: 'Antioquia'),
    LocationData(city: 'Envigado', department: 'Antioquia'),
    LocationData(city: 'Apartadó', department: 'Antioquia'),
    LocationData(city: 'Turbo', department: 'Antioquia'),
    LocationData(city: 'Rionegro', department: 'Antioquia'),
    LocationData(city: 'Sabaneta', department: 'Antioquia'),
    LocationData(city: 'La Estrella', department: 'Antioquia'),
    LocationData(city: 'Copacabana', department: 'Antioquia'),
    
    // Bogotá D.C.
    LocationData(city: 'Bogotá', department: 'Cundinamarca'),
    
    // Valle del Cauca
    LocationData(city: 'Cali', department: 'Valle del Cauca'),
    LocationData(city: 'Palmira', department: 'Valle del Cauca'),
    LocationData(city: 'Buenaventura', department: 'Valle del Cauca'),
    LocationData(city: 'Tuluá', department: 'Valle del Cauca'),
    LocationData(city: 'Cartago', department: 'Valle del Cauca'),
    LocationData(city: 'Buga', department: 'Valle del Cauca'),
    LocationData(city: 'Jamundí', department: 'Valle del Cauca'),
    LocationData(city: 'Yumbo', department: 'Valle del Cauca'),
    
    // Atlántico
    LocationData(city: 'Barranquilla', department: 'Atlántico'),
    LocationData(city: 'Soledad', department: 'Atlántico'),
    LocationData(city: 'Malambo', department: 'Atlántico'),
    LocationData(city: 'Sabanagrande', department: 'Atlántico'),
    LocationData(city: 'Puerto Colombia', department: 'Atlántico'),
    
    // Santander
    LocationData(city: 'Bucaramanga', department: 'Santander'),
    LocationData(city: 'Floridablanca', department: 'Santander'),
    LocationData(city: 'Girón', department: 'Santander'),
    LocationData(city: 'Piedecuesta', department: 'Santander'),
    LocationData(city: 'Barrancabermeja', department: 'Santander'),
    LocationData(city: 'San Gil', department: 'Santander'),
    
    // Cundinamarca
    LocationData(city: 'Soacha', department: 'Cundinamarca'),
    LocationData(city: 'Chía', department: 'Cundinamarca'),
    LocationData(city: 'Zipaquirá', department: 'Cundinamarca'),
    LocationData(city: 'Facatativá', department: 'Cundinamarca'),
    LocationData(city: 'Cajicá', department: 'Cundinamarca'),
    LocationData(city: 'Fusagasugá', department: 'Cundinamarca'),
    LocationData(city: 'Madrid', department: 'Cundinamarca'),
    LocationData(city: 'Mosquera', department: 'Cundinamarca'),
    LocationData(city: 'Funza', department: 'Cundinamarca'),
    LocationData(city: 'Girardot', department: 'Cundinamarca'),
    
    // Bolívar
    LocationData(city: 'Cartagena', department: 'Bolívar'),
    LocationData(city: 'Magangué', department: 'Bolívar'),
    LocationData(city: 'Turbaco', department: 'Bolívar'),
    
    // Norte de Santander
    LocationData(city: 'Cúcuta', department: 'Norte de Santander'),
    LocationData(city: 'Villa del Rosario', department: 'Norte de Santander'),
    LocationData(city: 'Los Patios', department: 'Norte de Santander'),
    LocationData(city: 'Ocaña', department: 'Norte de Santander'),
    
    // Córdoba
    LocationData(city: 'Montería', department: 'Córdoba'),
    LocationData(city: 'Lorica', department: 'Córdoba'),
    LocationData(city: 'Cereté', department: 'Córdoba'),
    LocationData(city: 'Sahagún', department: 'Córdoba'),
    
    // Tolima
    LocationData(city: 'Ibagué', department: 'Tolima'),
    LocationData(city: 'Espinal', department: 'Tolima'),
    LocationData(city: 'Melgar', department: 'Tolima'),
    LocationData(city: 'Honda', department: 'Tolima'),
    
    // Huila
    LocationData(city: 'Neiva', department: 'Huila'),
    LocationData(city: 'Pitalito', department: 'Huila'),
    LocationData(city: 'Garzón', department: 'Huila'),
    LocationData(city: 'La Plata', department: 'Huila'),
    
    // Nariño
    LocationData(city: 'Pasto', department: 'Nariño'),
    LocationData(city: 'Chachagüí', department: 'Nariño'),
    LocationData(city: 'Tumaco', department: 'Nariño'),
    LocationData(city: 'Ipiales', department: 'Nariño'),
    LocationData(city: 'Túquerres', department: 'Nariño'),
    LocationData(city: 'Sandona', department: 'Nariño'),
    LocationData(city: 'La Unión', department: 'Nariño'),
    LocationData(city: 'Tangua', department: 'Nariño'),
    LocationData(city: 'Yacuanquer', department: 'Nariño'),
    LocationData(city: 'Consacá', department: 'Nariño'),
    LocationData(city: 'Nariño', department: 'Nariño'),
    LocationData(city: 'La Florida', department: 'Nariño'),

    // Cauca
    LocationData(city: 'Popayán', department: 'Cauca'),
    LocationData(city: 'Santander de Quilichao', department: 'Cauca'),
    LocationData(city: 'Puerto Tejada', department: 'Cauca'),
    
    // Risaralda
    LocationData(city: 'Pereira', department: 'Risaralda'),
    LocationData(city: 'Dosquebradas', department: 'Risaralda'),
    LocationData(city: 'La Virginia', department: 'Risaralda'),
    LocationData(city: 'Santa Rosa de Cabal', department: 'Risaralda'),
    
    // Quindío
    LocationData(city: 'Armenia', department: 'Quindío'),
    LocationData(city: 'Calarcá', department: 'Quindío'),
    LocationData(city: 'La Tebaida', department: 'Quindío'),
    LocationData(city: 'Montenegro', department: 'Quindío'),
    
    // Caldas
    LocationData(city: 'Manizales', department: 'Caldas'),
    LocationData(city: 'Villamaría', department: 'Caldas'),
    LocationData(city: 'Chinchiná', department: 'Caldas'),
    LocationData(city: 'La Dorada', department: 'Caldas'),
    
    // Boyacá
    LocationData(city: 'Tunja', department: 'Boyacá'),
    LocationData(city: 'Duitama', department: 'Boyacá'),
    LocationData(city: 'Sogamoso', department: 'Boyacá'),
    LocationData(city: 'Chiquinquirá', department: 'Boyacá'),
    
    // Meta
    LocationData(city: 'Villavicencio', department: 'Meta'),
    LocationData(city: 'Acacías', department: 'Meta'),
    LocationData(city: 'Granada', department: 'Meta'),
    
    // Cesar
    LocationData(city: 'Valledupar', department: 'Cesar'),
    LocationData(city: 'Aguachica', department: 'Cesar'),
    LocationData(city: 'Codazzi', department: 'Cesar'),
    
    // Magdalena
    LocationData(city: 'Santa Marta', department: 'Magdalena'),
    LocationData(city: 'Ciénaga', department: 'Magdalena'),
    LocationData(city: 'Fundación', department: 'Magdalena'),
    
    // Sucre
    LocationData(city: 'Sincelejo', department: 'Sucre'),
    LocationData(city: 'Corozal', department: 'Sucre'),
    
    // La Guajira
    LocationData(city: 'Riohacha', department: 'La Guajira'),
    LocationData(city: 'Maicao', department: 'La Guajira'),
    
    // Casanare
    LocationData(city: 'Yopal', department: 'Casanare'),
    LocationData(city: 'Aguazul', department: 'Casanare'),
    
    // Caquetá
    LocationData(city: 'Florencia', department: 'Caquetá'),
    LocationData(city: 'San Vicente del Caguán', department: 'Caquetá'),
    
    // Putumayo
    LocationData(city: 'Mocoa', department: 'Putumayo'),
    LocationData(city: 'Puerto Asís', department: 'Putumayo'),
    
    // Arauca
    LocationData(city: 'Arauca', department: 'Arauca'),
    LocationData(city: 'Tame', department: 'Arauca'),
    
    // Amazonas
    LocationData(city: 'Leticia', department: 'Amazonas'),
    
    // Chocó
    LocationData(city: 'Quibdó', department: 'Chocó'),
    
    // Guainía
    LocationData(city: 'Inírida', department: 'Guainía'),
    
    // Guaviare
    LocationData(city: 'San José del Guaviare', department: 'Guaviare'),
    
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
}