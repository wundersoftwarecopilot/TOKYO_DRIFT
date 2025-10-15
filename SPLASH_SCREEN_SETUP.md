# Tokyo Drift - Splash Screen Setup

## Instrucciones para configurar el logo de inicio

1. **Guarda la imagen del logo:**
   - Guarda la imagen `tokyo_drift_logo.png` en la carpeta: `assets/images/`
   - La ruta completa debe ser: `c:\Wundev\TOKYO_DRIFT\drift_admin\assets\images\tokyo_drift_logo.png`

2. **Ejecuta Flutter pub get:**
   ```bash
   cd c:\Wundev\TOKYO_DRIFT\drift_admin
   flutter pub get
   ```

3. **Ejecuta la aplicación:**
   ```bash
   flutter run -d windows
   ```

## Características del Splash Screen

- **Duración:** 2.5 segundos
- **Animación:** Fade in + Scale con efecto suave
- **Color de fondo:** Dark (#2B2D30) similar al logo
- **Indicador de carga:** Spinner rojo animado
- **Transición:** Fade suave hacia la pantalla principal

## Personalización

Si quieres cambiar la duración del splash, edita el archivo:
`lib/screens/splash_screen.dart`

Busca la línea:
```dart
Timer(const Duration(milliseconds: 2500), () {
```

Y cambia `2500` por los milisegundos que desees.

## Formato de imagen recomendado

- **Tamaño:** 512x512 o similar (cuadrado)
- **Formato:** PNG con transparencia
- **Fondo:** Transparente (opcional)
