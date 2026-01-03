# limpiacasa

App Flutter para asignar áreas de limpieza al azar o elegirlas manualmente y llevar control rápido del tiempo y registros.

## Funcionalidad

- Pantalla inicial: botones “Dame una tarea” (azar), “Elegir” (picker), botón “Áreas y Tareas” en appbar y menú hamburguesa con atajos.
- Lista de últimas 15 actividades completadas bajo los botones (solo COMPLETADO).
- Menú hamburguesa: cerrar, ir a Áreas y Tareas, ir a Timers, y switch persistente de Modo Oscuro.
- Pantalla de temporizador:
	- Usa las duraciones configurables (Timers) y permite elegir entre ellas.
	- Modo Abierto (sin tiempo) que cuenta hacia arriba.
	- Controles de iniciar/reiniciar y detener, con alarma del sistema y notificación al finalizar.
	- “Dame otra área” registra SALTADO y elige otra área al azar.
	- “Trabajo Terminado” registra COMPLETADO, vuelve a inicio y muestra historial del área (últimas 10), evitando duplicados si ya se registró automáticamente.
- Configuración Áreas y Tareas: agregar, renombrar o borrar áreas. Persistencia con SharedPreferences. Áreas por defecto: Sala, Comedor, Cocina, Baño, Cuarto, Afuera, Patio.
- Pantalla Timers: agregar o borrar duraciones (minutos) usadas por el temporizador; se guardan en el dispositivo.

## Novedades

- **1.3.0+23:**
	- El historial se guarda automáticamente al terminar el timer sin depender del botón, y “Trabajo Terminado” evita duplicados con aviso.
	- Modo Abierto cuenta hacia arriba y registra el tiempo real usado.
	- Guardas de plataforma: las notificaciones se omiten en plataformas sin soporte (ej. Windows) para evitar cierres.
- **1.2.1+20:** Se corrige el timer para que siga funcionando con la pantalla apagada/segundo plano, usando notificación programada exacta; evita que se detenga después de ~90s con la pantalla off.
- **1.1.2+14:**
	- Menú hamburguesa con “Cerrar”, atajo a Áreas y Tareas, Timers y switch Modo Oscuro (persistente).
	- Pantalla Timers para administrar las duraciones del temporizador.
	- Lista de últimas 15 completadas en la pantalla inicial.
	- (Android) Paquete corregido a mx.zdlabsmx.limpiacasa; desinstala com.example.limpiacasa antes de instalar.
- **1.1.0+13:** Selector manual de área desde la pantalla inicial (“Elegir”) y regreso automático a la pantalla inicial al completar un trabajo.

## Cómo correr

1) Instala dependencias: `flutter pub get`
2) Ejecuta en un dispositivo/emulador: `flutter run`

## Notas

- El sonido usa `SystemSoundType.alert`; no requiere assets.
- El historial es por área y persiste entre sesiones; si cambias las áreas por defecto con una nueva versión, se reinicia la lista e historiales antiguos.
- Si tuviste instalada la app con el paquete com.example.limpiacasa, desinstálala antes de instalar esta versión (paquete mx.zdlabsmx.limpiacasa) para evitar ClassNotFoundException.
