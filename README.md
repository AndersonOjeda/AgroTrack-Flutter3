# example_ia

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Supabase Setup

- Create a project in Supabase and copy your `Project URL` and `anon public key`.
- Duplicate `.env.example` to `.env` and set:
  - `SUPABASE_URL` with your project URL.
  - `SUPABASE_ANON_KEY` with your anon key.
- Ensure `.env` is listed under `assets` in `pubspec.yaml`.
- Run `flutter pub get` and start the app.

### Notes
- Android requires Internet permission; it's already declared in `AndroidManifest.xml`.
- For web, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` via build-time env or serve `.env` securely.

## Arquitectura de Login (Clean Architecture + Patrones)

- Patrón Repository: `AuthRepository` define una interfaz de autenticación y `SupabaseAuthRepository` implementa llamadas a Supabase. Esto desacopla la UI de la infraestructura.
- Caso de Uso: `SignInUseCase` orquesta el flujo de login: autentica mediante el repositorio y luego carga al usuario con `UserService`. Retorna `Result<UserModel>` para manejo robusto de errores.
- Result Wrapper: `utils/result.dart` encapsula éxito o error evitando excepciones en el flujo normal.
- Inyección de Dependencias: `SignInUseCase` permite inyectar el loader de usuario, facilitando pruebas unitarias sin requerir Supabase.
- Instrumentación: Se registran eventos y errores con `LoggerService` en el repositorio y el caso de uso para trazabilidad.
- Pantalla: `LoginScreen` utiliza `SignInUseCase` (no llama directamente a Supabase), valida formulario, maneja estados y mantiene la UI estable.

### Archivos Clave
- `lib/services/auth_repository.dart`: Interfaz y repositorio de Supabase.
- `lib/usecases/sign_in_use_case.dart`: Caso de uso de login.
- `lib/utils/result.dart`: Resultados tipados de éxito/fallo.
- `lib/screens/login_screen.dart`: UI y lógica de presentación desacoplada.
- `test/sign_in_use_case_test.dart`: Pruebas unitarias del caso de uso (éxito/fallo).

### Beneficios
- SOLID (Single Responsibility y Dependency Inversion) aplicados en servicios y casos de uso.
- Testeabilidad mejorada y menor acoplamiento.
- Mantenibilidad y extensibilidad para futuras fuentes de autenticación.

## Solución a conflictos de ruta en Android (Windows)

Si tu directorio de usuario de Windows contiene un archivo llamado `C:\\Users\\Anderson` (o similar), Gradle puede fallar con errores como:

> ancestor 'C:\\Users\\Anderson' is not a directory

### Opciones rápidas

- Mapear el proyecto a una unidad virtual para evitar el ancestro conflictivo y ejecutar desde allí:
  1. `subst Z: "C:\\Users\\<TU_USUARIO>\\Downloads\\example_ia\\AgroTrack"`
  2. `setx GRADLE_USER_HOME "Z:\\.gradle_user_home"`
  3. `flutter clean && flutter pub get && flutter run -d emulator-5554`

- O mover el proyecto a una ruta simple sin espacios y sin depender de `C:\\Users`: por ejemplo `C:\\Dev\\AgroTrack`.

### Script local del repo

También puedes usar el script del repositorio para ejecutar builds Android con un cache local de Gradle:

```
PowerShell
./scripts/run_android.ps1 -Device emulator-5554
```

Este script establece `GRADLE_USER_HOME` en `.gradle_user_home/` dentro del repo (ignorado por git), realiza `flutter clean`, restaura dependencias y lanza la app.
