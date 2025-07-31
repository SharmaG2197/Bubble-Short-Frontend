import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config.dart';

class Explosion {
  final double top;
  final double left;
  final UniqueKey key;

  Explosion(this.top, this.left) : key = UniqueKey();
}

class Bubble {
  final String letter;
  final String word;
  final bool isSpecial;
  double topPosition;
  double leftPosition;

  Bubble(this.letter, this.word, this.isSpecial,
      {this.topPosition = 0, required this.leftPosition});
}

class AdultsGameScreen extends StatefulWidget {
  const AdultsGameScreen({super.key});

  @override
  State<AdultsGameScreen> createState() => _KidsGameScreenState();
}

class _KidsGameScreenState extends State<AdultsGameScreen> {
  final List<Bubble> _bubbles = [];
  final FlutterTts _tts = FlutterTts();
  final String _deviceId = const Uuid().v4();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Explosion> _explosions = [];

  Timer? _bubbleTimer;
  Timer? _fallTimer;
  int _score = 0;
  int _life = 3;
  bool _paused = false;
  bool _gameEnded = false;
  double _bubbleSpeed = 6.0;
  int _bubbleCount = 0;

  @override
  void initState() {
    super.initState();
    _setupTTS();
    _playStartMusic();
    _startGame();
    _startFallTimer();
  }

  void _playStartMusic() async {
    await _audioPlayer.play(AssetSource('audio/game_start.mp3'));
  }

  void _setupTTS() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);
  }

  void _startGame() {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 500 * i), _fetchBubble);
    }

    _bubbleTimer = Timer.periodic(
      Duration(seconds: _bubbleSpeed.toInt()),
      (_) {
        if (!_paused && !_gameEnded) _fetchBubble();
      },
    );
  }

  void _startFallTimer() {
    _fallTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_paused && !_gameEnded) {
        if (!mounted) return;
        setState(() {
          for (int i = _bubbles.length - 1; i >= 0; i--) {
            _bubbles[i].topPosition += 5;
            if (_bubbles[i].topPosition > MediaQuery.of(context).size.height - 100) {
              _bubbles.removeAt(i);
              _life = (_life - 1).clamp(0, 3);
              if (_life == 0) _gameOver();
            }
          }
        });
      }
    });
  }

  Future<void> _fetchBubble() async {
    final response = await http.get(
      // Uri.parse('http://127.0.0.1:8000/play?device_id=$_deviceId&device_type=web'),
      Uri.parse('$apiBaseUrl/play?device_id=$_deviceId&device_type=web')
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isSpecial = (_bubbleCount + 1) % 10 == 0;
      _bubbleCount++;

      double left;
      int retry = 0;
      do {
        left = Random().nextDouble() * MediaQuery.of(context).size.width * 0.8;
        retry++;
      } while (_bubbles.any((b) => (b.leftPosition - left).abs() < 60) && retry < 10);

      final bubble = Bubble(
        data['letter'],
        data['word'],
        isSpecial,
        leftPosition: left,
      );

      if (!mounted) return;
      setState(() => _bubbles.add(bubble));
    }
  }

  void _handleUserInput(String input) async {
    if (_paused || _gameEnded) return;

    final matchIndex = _bubbles.indexWhere(
        (bubble) => input.toUpperCase() == bubble.letter.toUpperCase());

    if (matchIndex != -1) {
      final current = _bubbles[matchIndex];

      setState(() {
        _explosions.add(Explosion(current.topPosition, current.leftPosition));
        _bubbles.removeAt(matchIndex);
      });

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _explosions.removeWhere((e) => e.key == _explosions.last.key);
        });
      }

      await _speak("${current.letter} for ${current.word}");

      if (!mounted) return;
      setState(() {
        _score += current.isSpecial ? 10 : 5;
      });

      _bubbleSound();
      _checkSpeed();
      _fetchBubble();
    } else {
      if (!mounted) return;
      setState(() {
        _life = (_life - 1).clamp(0, 3);
        if (_life == 0) _gameOver();
      });
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  void _checkSpeed() {
    if (_score > 0 && _score % 50 == 0) {
      _bubbleSpeed = (_bubbleSpeed - 0.5).clamp(1.0, 6.0);
      _bubbleTimer?.cancel();
      _bubbleTimer = Timer.periodic(
        Duration(milliseconds: (_bubbleSpeed * 1000).toInt()),
        (_) {
          if (!_paused && !_gameEnded) {
            if (!mounted) return;
            _fetchBubble();
          }
        },
      );
    }
  }

  void _bubbleSound() {
    _audioPlayer.play(AssetSource('audio/gun-shot.mp3'));
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) _showPauseDialog();
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/image/game_paused.png',
                width: 420,
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _paused = false);
                    },
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset('assets/image/continue.png'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close pause dialog
                      Navigator.of(context).pop(); // Return to home
                    },
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset('assets/image/exit.png'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _restartGame();
                    },
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset('assets/image/restart.png'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _gameOver() {
    _tts.speak("Game Over");
    _audioPlayer.play(AssetSource('audio/game-over.mp3'));
    _bubbleTimer?.cancel();
    _fallTimer?.cancel();
    _gameEnded = true;

    // http.post(Uri.parse('http://127.0.0.1:8000/end'), headers: {'accept': 'application/json'});
    http.post(Uri.parse('$apiBaseUrl/end'), headers: {'accept': 'application/json'});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/image/game_over.png',
                width: 420,
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _restartGame();
                    },
                    child: Image.asset(
                      'assets/image/restart.png',
                      width: 140,
                    ),
                  ),
                  const SizedBox(width: 30),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close game over dialog
                      Navigator.of(context).pop(); // Return to home
                    },
                    child: Image.asset(
                      'assets/image/exit.png',
                      width: 140,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _restartGame() {
    if (!mounted) return;
    setState(() {
      _score = 0;
      _life = 3;
      _bubbles.clear();
      _explosions.clear();
      _bubbleSpeed = 6.0;
      _paused = false;
      _gameEnded = false;
      _bubbleCount = 0;
    });
    _bubbleTimer?.cancel();
    _fallTimer?.cancel();
    _startGame();
    _startFallTimer();
  }

  Widget _buildHearts() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index < _life;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: isActive ? 1.0 : 0.5,
            child: Container(
              width: 55,
              height: 55,
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                isActive
                    ? 'assets/image/red-heart.png'
                    : 'assets/image/white-heart.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getColorForLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.blue;
      case 'D':
        return Colors.green;
      case 'E':
        return Colors.teal;
      case 'F':
        return Colors.pink;
      case 'G':
        return Colors.indigo;
      case 'H':
        return Colors.cyan;
      case 'I':
        return Colors.amber;
      case 'J':
        return Colors.brown;
      case 'K':
        return Colors.deepPurple;
      case 'L':
        return Colors.lime;
      case 'M':
        return Colors.deepOrange;
      case 'N':
        return Colors.lightGreen;
      case 'O':
        return Colors.blueGrey;
      case 'P':
        return Colors.lightBlue;
      case 'Q':
        return Colors.purple;
      case 'R':
        return Colors.greenAccent;
      case 'S':
        return Colors.redAccent;
      case 'T':
        return Colors.orangeAccent;
      case 'U':
        return Colors.yellow;
      case 'V':
        return Colors.cyanAccent;
      case 'W':
        return Colors.tealAccent;
      case 'X':
        return Colors.pinkAccent;
      case 'Y':
        return Colors.indigoAccent;
      case 'Z':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _fallTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKey: (e) {
        if (e.runtimeType.toString() == 'RawKeyDownEvent') {
          if (e.logicalKey.keyLabel == ' ') {
            _togglePause();
          } else {
            _handleUserInput(e.logicalKey.keyLabel);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Score: $_score"),
              _buildHearts(),
              IconButton(
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                onPressed: _togglePause,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            ..._bubbles.map((bubble) => Positioned(
              top: bubble.topPosition,
              left: bubble.leftPosition,
              child: GestureDetector(
                onTap: () => _handleUserInput(bubble.letter),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/image/bubble.png',
                      width: bubble.isSpecial ? 240 : 125,
                      height: bubble.isSpecial ? 240 : 125,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: bubble.isSpecial ? 120 : 80,
                      height: bubble.isSpecial ? 120 : 80,
                      decoration: BoxDecoration(
                        color: _getColorForLetter(bubble.letter).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        bubble.letter,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            ..._explosions.map((e) => Positioned(
              key: e.key,
              top: e.top,
              left: e.left,
              child: Image.asset(
                'assets/image/blast.png',
                width: 120,
                height: 120,
              ),
            )),
          ],
        ),
      ),
    );
  }
}