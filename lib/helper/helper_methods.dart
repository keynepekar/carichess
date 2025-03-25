bool isWhite(int index) {
  int x = index ~/ 8; // donne la partie entière de la division
          int y = index % 8; // donne le reste donc la colonne

          // Alterner les couleurs pour chaque carré
          bool isWhite = (x + y) % 2 == 0;
  return isWhite;
}