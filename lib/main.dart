import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LimpiacasaApp());
}

class LimpiacasaApp extends StatelessWidget {
  const LimpiacasaApp({super.key});

  static final ValueNotifier<List<String>> _areaList = ValueNotifier<List<String>>([
    'Afuera',
    'Cuarto Tere',
    'Cuarto',
    'Recibidor',
    'Patio Abajo',
    'Hamaca',
    'Comedor',
    'Baño abajo',
    'Bar',
    'Cocina',
    'Patio arriba',
    'Sala Arriba',
    'Bodega',
    'Baño Arriba',
    'Hotel',
    'Oficina',
    'Pasillo',
    'Escaleras',
  ]);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Limpia Casa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: RandomNumberScreen(areaList: _areaList),
    );
  }
}

class RandomNumberScreen extends StatelessWidget {
  const RandomNumberScreen({super.key, required this.areaList});

  final ValueNotifier<List<String>> areaList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vamos a hacer un poco de quehacer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(areaList: areaList),
                ),
              );
            },
            tooltip: 'Configurar áreas',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.cleaning_services_outlined, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Descubre tu destino',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.clean_hands_outlined),
                label: const Text('Elegir área'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final areas = areaList.value;
                  if (areas.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Agrega al menos un área para continuar')),
                    );
                    return;
                  }
                  final randomIndex = Random().nextInt(areas.length);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TimerScreen(
                        selectedIndex: randomIndex,
                        areaList: areaList,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.selectedIndex, required this.areaList});

  final int selectedIndex;
  final ValueNotifier<List<String>> areaList;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _durations = [5, 7, 10, 12, 15];
  late int _currentIndex;
  int _selectedMinutes = _durations.first;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
    _selectedMinutes = _pickRandomDuration();
    _remainingSeconds = _selectedMinutes * 60;
    widget.areaList.addListener(_onAreasChanged);
  }

  @override
  void dispose() {
    widget.areaList.removeListener(_onAreasChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _onAreasChanged() {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }
    if (_currentIndex >= areas.length) {
      setState(() {
        _currentIndex = areas.length - 1;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });
        _playAlarm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiempo cumplido')),
        );
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  void _playAlarm() {
    SystemSound.play(SystemSoundType.alert);
  }

  String _areaName() {
    final areas = widget.areaList.value;
    if (areas.isEmpty) return 'Área desconocida';
    final index = _currentIndex.clamp(0, areas.length - 1);
    return areas[index];
  }

  void _randomizeArea() {
    final areas = widget.areaList.value;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega áreas en Configuración')),
      );
      return;
    }

    _timer?.cancel();
    final random = Random();
    _currentIndex = random.nextInt(areas.length);
    _selectedMinutes = _pickRandomDuration();
    _remainingSeconds = _selectedMinutes * 60;
    setState(() {
      _isRunning = false;
    });
  }

  int _pickRandomDuration() {
    final random = Random();
    return _durations[random.nextInt(_durations.length)];
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
              children: _durations.map((minutes) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar áreas'),
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
                      labelText: 'Nueva área',
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
                    return const Center(child: Text('No hay áreas, agrega una para empezar'));
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
