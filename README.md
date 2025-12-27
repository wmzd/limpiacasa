# limpiacasa

App Flutter para asignar áreas de limpieza al azar y llevar control rápido del tiempo y registros.

## Funcionalidad

- Pantalla inicial: muestra “Descubre tu destino”, elige un área al azar de la lista actual y permite abrir Configuración.
- Pantalla de temporizador:
	- Muestra el área elegida y asigna duración aleatoria (5/7/10/12/15 min), con opción de cambiarla.
	- Controles de iniciar/reiniciar y detener, con alarma del sistema al finalizar.
	- Botón “Dame otra área” marca la tarea como SALTADO y selecciona otra área aleatoria.
	- Botón “Trabajo Terminado” guarda un registro COMPLETADO; se muestran las últimas 10 entradas del área actual con fecha/hora.
- Configuración: agregar, renombrar o borrar áreas. Listas e historiales se guardan en el dispositivo (SharedPreferences). Áreas por defecto: Sala, Comedor, Cocina, Baño, Cuarto, Afuera, Patio.

## Cómo correr

1) Instala dependencias: `flutter pub get`
2) Ejecuta en un dispositivo/emulador: `flutter run`

## Notas

- El sonido usa `SystemSoundType.alert`; no requiere assets.
- El historial es por área y persiste entre sesiones; si cambias las áreas por defecto con una nueva versión, se reinicia la lista e historiales antiguos.
