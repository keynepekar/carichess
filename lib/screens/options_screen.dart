import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionsScreen extends StatefulWidget {
  const OptionsScreen({super.key});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  final _timerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final prefs = await SharedPreferences.getInstance();

    // todo: discuter des valeurs par défaut
    if (!prefs.containsKey('player1')) {
      await prefs.setString('player1', 'Joueur 1');
    }
    if (!prefs.containsKey('player2')) {
      await prefs.setString('player2', 'Joueur 2');
    }
    if (!prefs.containsKey('timer')) {
      await prefs.setInt('timer', 5);
    }

    _player1Controller.text = prefs.getString('player1')!;
    _player2Controller.text = prefs.getString('player2')!;
    _timerController.text = prefs.getInt('timer')!.toString();
  }

  Future<void> _saveOptions() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'player1',
      _player1Controller.text.isNotEmpty ? _player1Controller.text : 'Joueur 1',
    );

    await prefs.setString(
      'player2',
      _player2Controller.text.isNotEmpty ? _player2Controller.text : 'Joueur 2',
    );

    final timerValue = int.tryParse(_timerController.text);
    if (timerValue != null && timerValue >= 1 && timerValue <= 60) {
      await prefs.setInt('timer', timerValue);
    } else {
      await prefs.setInt(
        'timer',
        5,
      ); // fallback valeur par défaut si mauvais input
      setState(() {
        _timerController.text = '5';
      });
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'November',
            fontSize: 20,
            height: 1.75,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 265,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.5 * 255).toInt()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'November',
              fontSize: 20,
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5122A3), Color(0xFF7C4BD1)],
          ),
        ),
        child: Stack(
          children: [
            // Logo CariChess
            Align(
              alignment: const Alignment(0, -0.85),
              child: Image.asset(
                'assets/images/logo_texte.png',
                width: 360,
                height: 225,
                fit: BoxFit.contain,
              ),
            ),

            // Logo caribou
            Align(
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/images/logo_caribou.png',
                width: 622,
                height: 389,
                fit: BoxFit.contain,
              ),
            ),

            // Zone options
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 232 + 100,
              left: (MediaQuery.of(context).size.width - 320) / 2,
              child: Container(
                width: 320,
                height: 464,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0x80CD61FF),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'OPTIONS',
                      style: TextStyle(
                        fontFamily: 'November',
                        fontSize: 20,
                        letterSpacing: 10,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 3.0),
                            blurRadius: 3.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    _buildInputField("Nom Joueur 1", _player1Controller),
                    const SizedBox(height: 35),
                    _buildInputField("Nom Joueur 2", _player2Controller),
                    const SizedBox(height: 35),
                    _buildInputField(
                      "Temps de partie",
                      _timerController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            // Bouton menu
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await _saveOptions();
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 284,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0x4DCD61FF),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'MENU',
                        style: TextStyle(
                          fontFamily: 'November',
                          fontSize: 20,
                          letterSpacing: 10,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 3.0),
                              blurRadius: 3.0,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
