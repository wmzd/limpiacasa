# limpiacasa

App Flutter para asignar áreas de limpieza al azar o elegirlas manualmente y llevar control rápido del tiempo y registros.

## Funcionalidad

- Pantalla inicial: muestra “Vamos a empezar”, permite seleccionar un área al azar con “Dame una tarea” o elegirla manualmente con “Elegir”, y abre Configuración (Áreas y Tareas).
- Pantalla de temporizador:
	- Muestra el área elegida y asigna duración aleatoria (5/7/10/12/15 min), con opción de cambiarla.
	- Controles de iniciar/reiniciar y detener, con alarma del sistema al finalizar.
	- Botón “Dame otra área” marca la tarea como SALTADO y selecciona otra área aleatoria.
	- Botón “Trabajo Terminado” guarda un registro COMPLETADO, vuelve a la pantalla inicial y se muestran las últimas 10 entradas del área actual con fecha/hora.
- Configuración: agregar, renombrar o borrar áreas. Listas e historiales se guardan en el dispositivo (SharedPreferences). Áreas por defecto: Sala, Comedor, Cocina, Baño, Cuarto, Afuera, Patio.

## Novedades

- **1.1.2+14:** Se corrigió el paquete Android a mx.zdlabsmx.limpiacasa; desinstala versiones previas (com.example.limpiacasa) antes de instalar el APK actual para evitar errores de arranque.
- **1.1.0+13:** Selector manual de área desde la pantalla inicial (“Elegir”) y regreso automático a la pantalla inicial al completar un trabajo.

## Cómo correr

1) Instala dependencias: `flutter pub get`
2) Ejecuta en un dispositivo/emulador: `flutter run`

## Notas

- El sonido usa `SystemSoundType.alert`; no requiere assets.
- El historial es por área y persiste entre sesiones; si cambias las áreas por defecto con una nueva versión, se reinicia la lista e historiales antiguos.
- Si tuviste instalada la app con el paquete com.example.limpiacasa, desinstálala antes de instalar esta versión (paquete mx.zdlabsmx.limpiacasa) para evitar ClassNotFoundException.
