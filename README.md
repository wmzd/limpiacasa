# limpiacasa

App Flutter sencilla con dos pantallas:

- Genera un número aleatorio del 1 al 18.
- Muestra el número seleccionado junto con un temporizador configurable de 5, 7, 10, 12 o 15 minutos.
- Botón para iniciar/reiniciar el conteo y botón para detenerlo.
- Al terminar el tiempo se reproduce una alerta del sistema.

## Cómo correr

1) Instala dependencias: `flutter pub get`
2) Ejecuta en un dispositivo/emulador: `flutter run`

## Notas

- El sonido usa `SystemSoundType.alert` del sistema; no requiere assets adicionales.
- Ajusta la selección de minutos con los chips; al iniciar se reinicia el temporizador con la duración elegida.
