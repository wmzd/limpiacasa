import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const LimpiacasaApp());
}

class LimpiacasaApp extends StatelessWidget {
  const LimpiacasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Limpia Casa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const RandomNumberScreen(),
    );
  }
}

class RandomNumberScreen extends StatelessWidget {
  const RandomNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vamos a hacer un poco de quehacer'),
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
                  final randomNumber = Random().nextInt(18) + 1;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TimerScreen(selectedNumber: randomNumber),
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
  const TimerScreen({super.key, required this.selectedNumber});

  final int selectedNumber;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _durations = [5, 7, 10, 12, 15];
  static const _areas = [
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
  ];
  late int _currentNumber;
  int _selectedMinutes = _durations.first;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentNumber = widget.selectedNumber;
    _selectedMinutes = _pickRandomDuration();
    _remainingSeconds = _selectedMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    final index = _currentNumber - 1;
    if (index < 0 || index >= _areas.length) return 'Área desconocida';
    return _areas[index];
  }

  void _randomizeArea() {
    _timer?.cancel();
    final random = Random();
    _currentNumber = random.nextInt(_areas.length) + 1;
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
