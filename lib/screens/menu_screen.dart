import 'package:flutter/material.dart';
import 'scores_screen.dart';
import 'game_board.dart';
import 'options_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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
            colors: [
              Color(0xFF5122A3),
              Color(0xFF7C4BD1),
            ],
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
            Positioned(
              bottom: 0,
              left: -100,
              child: Image.asset(
                'assets/images/logo_caribou.png',
                width: 622,
                height: 389,
              ),
            ),

            // Bloc boutons
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 319,
                height: 260,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildMenuButton("JOUER", () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GameBoard()));
                    }),
                    const SizedBox(height: 29),
                    _buildMenuButton("SCORES", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ScoresScreen()),
                      );
                    }),
                    const SizedBox(height: 29),
                    _buildMenuButton("OPTIONS", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OptionsScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
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
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
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
    );
  }
}
