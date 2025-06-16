import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  Map<String, int> scores = {};

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();

    final player1 = prefs.getString('player1') ?? 'Joueur 1';
    final player2 = prefs.getString('player2') ?? 'Joueur 2';

    final loadedScores = <String, int>{
      player1: prefs.getInt(player1) ?? 0,
      player2: prefs.getInt(player2) ?? 0,
    };

    setState(() {
      scores = loadedScores;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = scores.entries
        .map((entry) => '${entry.key} : ${entry.value}')
        .join('\n');

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

            // zone scoreboard
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - 232 + 100,
              left: (MediaQuery.of(context).size.width - 320) / 2,
              child: Container(
                width: 320,
                height: 464,
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
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'SCORES',
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
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          scoreText.isEmpty
                              ? 'Aucun score pour le moment'
                              : scoreText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'November',
                            fontSize: 20,
                            height: 1.75,
                            letterSpacing: 1.0,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                  onTap: () => Navigator.pop(context),
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
