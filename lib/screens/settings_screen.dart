import 'package:flutter/material.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estados de configuración
  bool _notificationsEnabled = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  bool _taskReminders = true;

  String _selectedTheme = 'system'; // system, light, dark
  String _selectedLanguage = 'es'; // es, en

  bool _biometricAuth = false;
  bool _autoSync = true;
  bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notificaciones
              _buildSectionTitle('Notificaciones'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Notificaciones',
                  'Activar todas las notificaciones',
                  Icons.notifications,
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                if (_notificationsEnabled) ...[
                  _buildSwitchTile(
                    'Notificaciones Push',
                    'Recibir notificaciones en tiempo real',
                    Icons.phone_android,
                    _pushNotifications,
                    (value) {
                      setState(() {
                        _pushNotifications = value;
                      });
                    },
                  ),
                  _buildSwitchTile(
                    'Notificaciones por Email',
                    'Recibir resúmenes por correo',
                    Icons.email,
                    _emailNotifications,
                    (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                  ),

                  _buildSwitchTile(
                    'Recordatorios de Tareas',
                    'Alertas sobre tareas pendientes',
                    Icons.task_alt,
                    _taskReminders,
                    (value) {
                      setState(() {
                        _taskReminders = value;
                      });
                    },
                  ),
                ],
              ]),

              const SizedBox(height: 24),

              // Apariencia
              _buildSectionTitle('Apariencia'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildSelectionTile(
                  'Tema',
                  _getThemeDescription(_selectedTheme),
                  Icons.palette,
                  () => _showThemeDialog(),
                ),
                _buildSelectionTile(
                  'Idioma',
                  _getLanguageDescription(_selectedLanguage),
                  Icons.language,
                  () => _showLanguageDialog(),
                ),
              ]),

              const SizedBox(height: 24),

              // Seguridad
              _buildSectionTitle('Seguridad y Privacidad'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Autenticación Biométrica',
                  'Usar huella dactilar o Face ID',
                  Icons.fingerprint,
                  _biometricAuth,
                  (value) {
                    setState(() {
                      _biometricAuth = value;
                    });
                  },
                ),
                _buildActionTile(
                  'Cambiar Contraseña',
                  'Actualizar tu contraseña de acceso',
                  Icons.lock,
                  () => _changePassword(),
                ),
                _buildActionTile(
                  'Privacidad de Datos',
                  'Gestionar el uso de tus datos',
                  Icons.privacy_tip,
                  () => _showPrivacySettings(),
                ),
              ]),

              const SizedBox(height: 24),

              // Sincronización
              _buildSectionTitle('Sincronización y Datos'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildSwitchTile(
                  'Sincronización Automática',
                  'Sincronizar datos automáticamente',
                  Icons.sync,
                  _autoSync,
                  (value) {
                    setState(() {
                      _autoSync = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  'Modo Offline',
                  'Trabajar sin conexión a internet',
                  Icons.offline_bolt,
                  _offlineMode,
                  (value) {
                    setState(() {
                      _offlineMode = value;
                    });
                  },
                ),
                _buildActionTile(
                  'Limpiar Caché',
                  'Eliminar datos temporales',
                  Icons.cleaning_services,
                  () => _clearCache(),
                ),
                _buildActionTile(
                  'Exportar Datos',
                  'Descargar una copia de tus datos',
                  Icons.download,
                  () => _exportData(),
                ),
              ]),

              const SizedBox(height: 24),

              // Información
              _buildSectionTitle('Información'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildActionTile(
                  'Acerca de',
                  'Información de la aplicación',
                  Icons.info,
                  () => _showAboutDialog(),
                ),
                _buildActionTile(
                  'Términos y Condiciones',
                  'Leer términos de uso',
                  Icons.description,
                  () => _showTerms(),
                ),
                _buildActionTile(
                  'Política de Privacidad',
                  'Revisar política de privacidad',
                  Icons.policy,
                  () => _showPrivacyPolicy(),
                ),
                _buildActionTile(
                  'Ayuda y Soporte',
                  'Obtener ayuda técnica',
                  Icons.support_agent,
                  () => _contactSupport(),
                ),
                _buildActionTile(
                  'Cerrar Sesión',
                  'Salir de tu cuenta',
                  Icons.logout,
                  () => _showLogoutDialog(),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSelectionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  String _getThemeDescription(String theme) {
    switch (theme) {
      case 'light':
        return 'Tema claro';
      case 'dark':
        return 'Tema oscuro';
      case 'system':
      default:
        return 'Seguir sistema';
    }
  }

  String _getLanguageDescription(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'es':
      default:
        return 'Español';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Tema'),
          content: RadioGroup<String>(
            groupValue: _selectedTheme,
            onChanged: (value) {
              setState(() {
                _selectedTheme = value!;
              });
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Seguir sistema'),
                  leading: Radio<String>(value: 'system'),
                  onTap: () {
                    setState(() {
                      _selectedTheme = 'system';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Tema claro'),
                  leading: Radio<String>(value: 'light'),
                  onTap: () {
                    setState(() {
                      _selectedTheme = 'light';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Tema oscuro'),
                  leading: Radio<String>(value: 'dark'),
                  onTap: () {
                    setState(() {
                      _selectedTheme = 'dark';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Idioma'),
          content: RadioGroup<String>(
            groupValue: _selectedLanguage,
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value!;
              });
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Español'),
                  leading: Radio<String>(value: 'es'),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = 'es';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('English'),
                  leading: Radio<String>(value: 'en'),
                  onTap: () {
                    setState(() {
                      _selectedLanguage = 'en';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de cambio de contraseña próximamente'),
      ),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuraciones de privacidad próximamente'),
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Caché'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todos los datos temporales?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caché limpiado correctamente')),
                );
              },
              child: const Text('Limpiar'),
            ),
          ],
        );
      },
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación próximamente'),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'AgroTrack',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.eco,
        color: Theme.of(context).colorScheme.primary,
        size: 48,
      ),
      children: [
        const Text(
          'AgroTrack es una aplicación diseñada para ayudar a los agricultores a gestionar sus cultivos de manera eficiente y sostenible.',
        ),
      ],
    );
  }

  void _showTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Términos y condiciones próximamente')),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Política de privacidad próximamente')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacto con soporte próximamente')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  await UserService.signOut();
                  if (mounted) {
                    navigator.pushNamedAndRemoveUntil('/', (route) => false);
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al cerrar sesión: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
