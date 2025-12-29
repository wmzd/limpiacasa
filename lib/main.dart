import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const LimpiacasaApp());
}

const _defaultAreas = [
  'Sala',
  'Comedor',
  'Cocina',
  'Baño',
  'Cuarto',
  'Afuera',
  'Patio',
];

const _defaultDurations = [5, 7, 10, 12, 15];

const _areasVersion = 2;

class LimpiacasaApp extends StatefulWidget {
  const LimpiacasaApp({super.key});

  @override
  State<LimpiacasaApp> createState() => _LimpiacasaAppState();
}

class _LimpiacasaAppState extends State<LimpiacasaApp> {
  final ValueNotifier<List<String>> _areaList = ValueNotifier<List<String>>(_defaultAreas);
  final ValueNotifier<List<int>> _timerList = ValueNotifier<List<int>>(_defaultDurations);
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final areas = await StorageService.loadAreas();
    final timers = await StorageService.loadTimers();
    final theme = await StorageService.loadThemeMode();
    if (areas.isNotEmpty) {
      _areaList.value = areas;
    }
    if (timers.isNotEmpty) {
      _timerList.value = timers;
    }
    _themeMode.value = theme;
    setState(() {
      _initialized = true;
    });
  }

  void _updateTheme(ThemeMode mode) {
    _themeMode.value = mode;
    StorageService.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Limpia Casa',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: RandomNumberScreen(
            areaList: _areaList,
            timerList: _timerList,
            themeMode: _themeMode,
            onThemeChanged: _updateTheme,
          ),
        );
      },
    );
  }
}

class RandomNumberScreen extends StatefulWidget {
  const RandomNumberScreen({super.key, required this.areaList, required this.timerList, required this.themeMode, required this.onThemeChanged});

  final ValueNotifier<List<String>> areaList;
  final ValueNotifier<List<int>> timerList;
  final ValueNotifier<ThemeMode> themeMode;
  final void Function(ThemeMode mode) onThemeChanged;

  @override
  State<RandomNumberScreen> createState() => _RandomNumberScreenState();
}

class _RandomNumberScreenState extends State<RandomNumberScreen> {
  List<WorkEntry> _recent = [];
  late final ValueNotifier<List<int>> _timers;

  @override
  void initState() {
    super.initState();
    _timers = widget.timerList;
    _loadRecent();
  }

  String _formatTimestamp(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    final date = '${time.year}-${two(time.month)}-${two(time.day)}';
    final clock = '${two(time.hour)}:${two(time.minute)}';
    return '$date $clock';
  }

  Future<void> _loadRecent() async {
    final entries = await StorageService.loadRecentEntries(limit: 15);
    if (!mounted) return;
    setState(() => _recent = entries);
  }

  Future<void> _showAreaPicker(BuildContext context) async {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un área para continuar')),
      );
      return;
    }

    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Elige un área'),
          children: [
            SizedBox(
              width: double.maxFinite,
              height: 320,
              child: ListView.separated(
                itemCount: areas.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(areas[index]),
                    onTap: () => Navigator.of(context).pop(index),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    if (selectedIndex == null || !context.mounted) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TimerScreen(
              selectedIndex: selectedIndex,
              areaList: widget.areaList,
              timerList: _timers,
            ),
          ),
        )
        .then((_) => _loadRecent());
  }

  void _openRandomTask(BuildContext context) {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un área para continuar')),
      );
      return;
    }
    final randomIndex = Random().nextInt(areas.length);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TimerScreen(
              selectedIndex: randomIndex,
              areaList: widget.areaList,
              timerList: _timers,
            ),
          ),
        )
        .then((_) => _loadRecent());
  }

  void _openSettings() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(areaList: widget.areaList),
          ),
        )
        .then((_) => _loadRecent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openSettings,
              child: const Text('Áreas y Tareas'),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cerrar'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Áreas y Tareas'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSettings();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Timers'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => TimersScreen(timerList: _timers),
                        ),
                      )
                      .then((_) => _loadRecent());
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeMode,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Modo Oscuro'),
                    value: isDark,
                    onChanged: (value) {
                      final newMode = value ? ThemeMode.dark : ThemeMode.light;
                      widget.onThemeChanged(newMode);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.cleaning_services_outlined, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text(
              'Hagamos quehacer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.clean_hands_outlined),
              label: const Text('Dame una tarea'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _openRandomTask(context),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text('Elegir'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _showAreaPicker(context),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimas 15 completadas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (_recent.isEmpty)
              const Text('Aún no hay completadas'),
            if (_recent.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recent.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = _recent[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(entry.area),
                    subtitle: Text('${entry.minutes} min · ${_formatTimestamp(entry.finishedAt)}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.selectedIndex, required this.areaList, required this.timerList});

  final int selectedIndex;
  final ValueNotifier<List<String>> areaList;
  final ValueNotifier<List<int>> timerList;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  List<int> get _durations => widget.timerList.value.isNotEmpty ? widget.timerList.value : _defaultDurations;
  late final ValueNotifier<List<int>> _timerList;
  late int _currentIndex;
  int _selectedMinutes = _defaultDurations.first;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  List<WorkEntry> _history = [];
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerList = widget.timerList;
    _currentIndex = widget.selectedIndex;
    _selectedMinutes = _pickRandomDuration();
    _remainingSeconds = _selectedMinutes * 60;
    widget.areaList.addListener(_onAreasChanged);
    _timerList.addListener(_onDurationsChanged);
    _refreshHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.areaList.removeListener(_onAreasChanged);
    _timerList.removeListener(_onDurationsChanged);
    _timer?.cancel();
    _endAt = null;
    NotificationService.cancelTimerDone();
    super.dispose();
  }

  void _onAreasChanged() {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      setState(() {
        _currentIndex = 0;
      });
      _history = [];
      return;
    }
    if (_currentIndex >= areas.length) {
      setState(() {
        _currentIndex = areas.length - 1;
      });
    }
    _refreshHistory();
  }

  void _onDurationsChanged() {
    final durations = _durations;
    if (durations.isEmpty) {
      setState(() {
        _selectedMinutes = _defaultDurations.first;
        _remainingSeconds = _selectedMinutes * 60;
      });
      return;
    }
    if (!durations.contains(_selectedMinutes)) {
      setState(() {
        _selectedMinutes = durations.first;
        _remainingSeconds = _selectedMinutes * 60;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncRemaining();
    }
  }

  void _syncRemaining() {
    if (!_isRunning || _endAt == null) return;
    final remaining = _computeRemaining();
    if (remaining <= 0) {
      _finishTimer();
    } else {
      setState(() {
        _remainingSeconds = remaining;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final totalSeconds = _selectedMinutes * 60;
    _endAt = DateTime.now().add(Duration(seconds: totalSeconds));
    NotificationService.cancelTimerDone();
    NotificationService.scheduleTimerDone(_areaName(), _selectedMinutes, _endAt!);
    setState(() {
      _isRunning = true;
    });

    _tickAndSchedule();
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
      _endAt = null;
    });
    NotificationService.cancelTimerDone();
  }

  void _playAlarm() {
    SystemSound.play(SystemSoundType.alert);
  }

  void _handleTimerFinished() {
    _playAlarm();
    NotificationService.showTimerDone(_areaName(), _selectedMinutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tiempo cumplido')),
    );
  }

  void _tickAndSchedule() {
    _timer?.cancel();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (!_isRunning || _endAt == null) return;
    final remaining = _computeRemaining();
    if (remaining <= 0) {
      _finishTimer();
    } else {
      if (mounted) {
        setState(() {
          _remainingSeconds = remaining;
        });
      }
    }
  }

  int _computeRemaining() {
    if (_endAt == null) return 0;
    return max(0, _endAt!.difference(DateTime.now()).inSeconds);
  }

  void _finishTimer() {
    _timer?.cancel();
    _endAt = null;
    NotificationService.cancelTimerDone();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
    _handleTimerFinished();
  }

  String _areaName() {
    final areas = widget.areaList.value;
    if (areas.isEmpty) return 'Área desconocida';
    final index = _currentIndex.clamp(0, areas.length - 1);
    return areas[index];
  }

  Future<void> _randomizeArea() async {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega áreas en Configuración')),
      );
      return;
    }

    await _addHistoryEntry(status: 'SALTADO');

    _timer?.cancel();
    await NotificationService.cancelTimerDone();
    _endAt = null;
    final random = Random();
    _currentIndex = random.nextInt(areas.length);
    _selectedMinutes = _pickRandomDuration();
    _remainingSeconds = _selectedMinutes * 60;
    setState(() {
      _isRunning = false;
    });
    await _refreshHistory();
  }

  Future<void> _markCompleted() async {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega áreas en Configuración')),
      );
      return;
    }

    _timer?.cancel();
    await NotificationService.cancelTimerDone();
    _endAt = null;
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });

    await _addHistoryEntry(status: 'COMPLETADO');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabajo registrado')),
      );

      // Regresa a la pantalla inicial para elegir otra actividad.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  int _pickRandomDuration() {
    final durations = _durations;
    if (durations.isEmpty) return _defaultDurations.first;
    final random = Random();
    return durations[random.nextInt(durations.length)];
  }

  Future<void> _refreshHistory() async {
    final area = _areaName();
    final entries = await StorageService.loadHistory(area);
    if (!mounted) return;
    setState(() {
      _history = entries;
    });
  }

  Future<void> _addHistoryEntry({required String status}) async {
    final area = _areaName();
    final entries = await StorageService.loadHistory(area);
    final entry = WorkEntry(
      area: area,
      minutes: _selectedMinutes,
      finishedAt: DateTime.now(),
      status: status,
    );

    entries.insert(0, entry);
    if (entries.length > 10) {
      entries.removeRange(10, entries.length);
    }

    await StorageService.saveHistory(area, entries);
    if (!mounted) return;
    setState(() {
      _history = entries;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime time) {
    final date = '${time.year}-${_twoDigits(time.month)}-${_twoDigits(time.day)}';
    final clock = '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';
    return '$date $clock';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ahora limpiaremos:'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.primaryContainer,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cleaning_services_outlined, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _areaName(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Duración (minutos)',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: (_durations.isNotEmpty ? _durations : _defaultDurations).map((minutes) {
                final isSelected = _selectedMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMinutes = minutes;
                        if (!_isRunning) {
                          _remainingSeconds = _selectedMinutes * 60;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Text(
              _formatTime(_remainingSeconds),
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isRunning ? Icons.refresh : Icons.play_arrow),
                    label: Text(_isRunning ? 'Reiniciar' : 'Iniciar'),
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('Detener'),
                    onPressed: _isRunning || _remainingSeconds > 0 ? _stopTimer : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.autorenew),
              label: const Text('Dame otra área'),
              onPressed: _randomizeArea,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Trabajo Terminado'),
              onPressed: _markCompleted,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos 10 trabajos',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              const Text('Aún no hay registros'),
            if (_history.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = _history[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.task_alt),
                    title: Text(entry.area),
                    subtitle: Text('${entry.status} · ${entry.minutes} min · ${_formatTimestamp(entry.finishedAt)}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.areaList});

  final ValueNotifier<List<String>> areaList;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key, required this.timerList});

  final ValueNotifier<List<int>> timerList;

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  final TextEditingController _newTimerController = TextEditingController();

  @override
  void dispose() {
    _newTimerController.dispose();
    super.dispose();
  }

  void _addTimer() {
    final raw = _newTimerController.text.trim();
    if (raw.isEmpty) return;
    final value = int.tryParse(raw);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número de minutos válido')),
      );
      return;
    }
    final current = List<int>.from(widget.timerList.value);
    current.add(value);
    current.sort();
    widget.timerList.value = current;
    StorageService.saveTimers(current);
    _newTimerController.clear();
  }

  void _deleteTimer(int index) {
    final current = List<int>.from(widget.timerList.value);
    if (current.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe existir al menos un timer')),
      );
      return;
    }
    current.removeAt(index);
    widget.timerList.value = current;
    StorageService.saveTimers(current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTimerController,
                    decoration: const InputDecoration(
                      labelText: 'Minutos (ej. 5, 10, 15)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _addTimer(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _addTimer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<int>>(
                valueListenable: widget.timerList,
                builder: (context, timers, child) {
                  if (timers.isEmpty) {
                    return const Center(child: Text('No hay timers, agrega uno para empezar'));
                  }
                  return ListView.separated(
                    itemCount: timers.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: Text('${timers[index]} minutos'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteTimer(index),
                          tooltip: 'Eliminar',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _newAreaController = TextEditingController();

  @override
  void dispose() {
    _newAreaController.dispose();
    super.dispose();
  }

  void _addArea() {
    final text = _newAreaController.text.trim();
    if (text.isEmpty) return;
    final updated = List<String>.from(widget.areaList.value)..add(text);
    widget.areaList.value = updated;
    StorageService.saveAreas(updated);
    _newAreaController.clear();
  }

  void _deleteArea(int index) {
    final current = widget.areaList.value;
    if (current.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe existir al menos un área')),
      );
      return;
    }
    final updated = List<String>.from(current)..removeAt(index);
    widget.areaList.value = updated;
    StorageService.saveAreas(updated);
  }

  void _renameArea(int index) async {
    final current = widget.areaList.value;
    if (index < 0 || index >= current.length) return;
    final controller = TextEditingController(text: current[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar área'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre del área'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final updated = List<String>.from(current);
      updated[index] = result;
      widget.areaList.value = updated;
      StorageService.saveAreas(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Áreas y Actividades'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newAreaController,
                    decoration: const InputDecoration(
                      labelText: 'Ej. Sala de estar, Lavar los platos',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addArea(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: _addArea,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: widget.areaList,
                builder: (context, areas, child) {
                  if (areas.isEmpty) {
                    return const Center(child: Text('No hay áreas ni actividades, agrega una para empezar'));
                  }
                  return ListView.separated(
                    itemCount: areas.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: Text(areas[index]),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _renameArea(index),
                              tooltip: 'Renombrar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteArea(index),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkEntry {
  WorkEntry({required this.area, required this.minutes, required this.finishedAt, required this.status});

  final String area;
  final int minutes;
  final DateTime finishedAt;
  final String status;

  Map<String, dynamic> toJson() => {
        'area': area,
        'minutes': minutes,
        'finishedAt': finishedAt.toIso8601String(),
        'status': status,
      };

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      area: json['area'] as String? ?? 'Área',
      minutes: json['minutes'] as int? ?? 0,
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'COMPLETADO',
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _timerDoneId = 1;

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await mac?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static NotificationDetails _timerDetails() {
    const androidDetails = AndroidNotificationDetails(
      'timer_done_channel',
      'Timer completado',
      channelDescription: 'Alertas cuando termina el timer',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );
  }

  static Future<void> showTimerDone(String area, int minutes) async {
    await _plugin.show(
      _timerDoneId,
      'Tiempo cumplido',
      '$area listo en $minutes min',
      _timerDetails(),
    );
  }

  static Future<void> scheduleTimerDone(String area, int minutes, DateTime when) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      _timerDoneId,
      'Tiempo cumplido',
      '$area listo en $minutes min',
      scheduled,
      _timerDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelTimerDone() async {
    await _plugin.cancel(_timerDoneId);
  }
}

class StorageService {
  static const _areasKey = 'areas_list';
  static const _areasVersionKey = 'areas_version';
  static const _timersKey = 'timers_list';
  static const _themeKey = 'theme_mode';

  static Future<List<String>> loadAreas() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_areasVersionKey) ?? 0;

    // If version changed, reset to defaults and clear histories.
    if (storedVersion != _areasVersion) {
      await prefs.setInt(_areasVersionKey, _areasVersion);
      await prefs.setStringList(_areasKey, _defaultAreas);
      // clear per-area histories
      final keys = prefs.getKeys().where((k) => k.startsWith('history_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      return _defaultAreas;
    }

    return prefs.getStringList(_areasKey) ?? _defaultAreas;
  }

  static Future<void> saveAreas(List<String> areas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_areasVersionKey, _areasVersion);
    await prefs.setStringList(_areasKey, areas);
  }

  static Future<List<int>> loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_timersKey);
    if (stored == null) return _defaultDurations;
    return stored.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  static Future<void> saveTimers(List<int> timers) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = timers.map((e) => e.toString()).toList();
    await prefs.setStringList(_timersKey, encoded);
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeKey);
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeKey, value);
  }

  static String _historyKey(String area) => 'history_${base64Url.encode(utf8.encode(area))}';

  static Future<List<WorkEntry>> loadHistory(String area) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey(area)) ?? [];
    return raw
        .map((e) => WorkEntry.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveHistory(String area, List<WorkEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = entries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_historyKey(area), encoded);
  }

  static Future<List<WorkEntry>> loadRecentEntries({int limit = 15}) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('history_'));
    final all = <WorkEntry>[];

    for (final key in keys) {
      final raw = prefs.getStringList(key) ?? [];
      for (final item in raw) {
        try {
          final map = json.decode(item) as Map<String, dynamic>;
          final entry = WorkEntry.fromJson(map);
          if (entry.status == 'COMPLETADO') {
            all.add(entry);
          }
        } catch (_) {
          // Ignora entradas corruptas
        }
      }
    }

    all.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }
}
