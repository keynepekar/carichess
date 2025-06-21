import 'dart:async';
import 'package:carichess/components/dead_pieces.dart';
import 'package:carichess/components/piece.dart';
import 'package:carichess/components/square.dart';
import 'package:carichess/res/helper/helper.dart';
import 'package:carichess/res/helper/score_manager.dart';
import 'package:carichess/screens/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // board 8x8 de ChessPiece ou null
  late List<List<ChessPiece?>> board;

  // piece selectionnee, null si aucune
  ChessPiece? selectedPiece;
  int ligneSelec = -1;
  int colonneSelec = -1;

  // coups valides pour piece selectionnee
  List<List<int>> coupsValides = [];

  // captures
  List<ChessPiece?> blancsCaptures = [];
  List<ChessPiece?> noirsCaptures = [];

  bool tourBlanc = true;

  // pos des rois pour check
  List<int> posKingB = [7, 4];
  List<int> posKingN = [0, 4];
  bool checkStatus = false;

  // nom/score joueurs
  String nomJ1 = '';
  String nomJ2 = '';
  int victoiresJ1 = 0;
  int victoiresJ2 = 0;

  // timer sec
  int tpsInitial = 0;
  int tpsRestantB = 0;
  int tpsRestantN = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    _loadGameOptions();
  }

  Future<void> _loadGameOptions() async {
    final prefs = await SharedPreferences.getInstance();
    nomJ1 = prefs.getString('player1') ?? 'Joueur 1';
    nomJ2 = prefs.getString('player2') ?? 'Joueur 2';
    victoiresJ1 = prefs.getInt(nomJ1) ?? 0;
    victoiresJ2 = prefs.getInt(nomJ2) ?? 0;
    final timerVal = prefs.getInt('timer') ?? 5;
    tpsInitial = timerVal * 60;
    tpsRestantB = tpsRestantN = tpsInitial;
    setState(() {});
    _demarrerTimer();
  }

  void _demarrerTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (tourBlanc) {
          if (tpsRestantB > 0) tpsRestantB--;
        } else {
          if (tpsRestantN > 0) tpsRestantN--;
        }
      });
      // timeout
      if (tpsRestantB == 0) _onTimeout(nomJ2);
      if (tpsRestantN  == 0) _onTimeout(nomJ1);
    });
  }

  Future<void> _onTimeout(String vainqueur) async {
    _timer?.cancel();
    await incrementScore(vainqueur);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("$vainqueur a gagné par dépassement de temps !"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
            },
            child: const Text('Menu'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // INITIALIZE BOARD
  void _initializeBoard() {
    List<List<ChessPiece?>> newBoard = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

    // nb : 8x8 null
    // ]

    // -- pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        img: 'assets/images/pieces/pawn_b.png',
      );
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: true,
        img: 'assets/images/pieces/pawn_w.png',
      );
    }

    // -- rooks
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: 'assets/images/pieces/rook_b.png',
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      img: 'assets/images/pieces/rook_b.png',
    );
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: 'assets/images/pieces/rook_w.png',
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      img: 'assets/images/pieces/rook_w.png',
    );

    // -- knights
    newBoard[0][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: 'assets/images/pieces/knight_b.png',
    );
    newBoard[0][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: false,
      img: 'assets/images/pieces/knight_b.png',
    );
    newBoard[7][1] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: 'assets/images/pieces/knight_w.png',
    );
    newBoard[7][6] = ChessPiece(
      type: ChessPieceType.knight,
      isWhite: true,
      img: 'assets/images/pieces/knight_w.png',
    );

    // -- bishops
    newBoard[0][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: 'assets/images/pieces/bishop_b.png',
    );
    newBoard[0][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: false,
      img: 'assets/images/pieces/bishop_b.png',
    );
    newBoard[7][2] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: 'assets/images/pieces/bishop_w.png',
    );
    newBoard[7][5] = ChessPiece(
      type: ChessPieceType.bishop,
      isWhite: true,
      img: 'assets/images/pieces/bishop_w.png',
    );

    // -- queen
    newBoard[0][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: false,
      img: 'assets/images/pieces/queen_b.png',
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPieceType.queen,
      isWhite: true,
      img: 'assets/images/pieces/queen_w.png',
    );

    // -- king
    newBoard[0][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: false,
      img: 'assets/images/pieces/king_b.png',
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPieceType.king,
      isWhite: true,
      img: 'assets/images/pieces/king_w.png',
    );

    board = newBoard;
  }

  void selectPiece(int row, int col) {
    setState(() {
      // si pas de piece et case non vide et couleur valide
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == tourBlanc) {
          selectedPiece = board[row][col];
          ligneSelec = row;
          colonneSelec = col;
        }
      }
      // autre sélection
      else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        ligneSelec = row;
        colonneSelec = col;
      }
      // déplacement si valide
      else if (selectedPiece != null &&
          coupsValides.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      coupsValides = calculateRealcoupsValides(
        ligneSelec,
        colonneSelec,
        selectedPiece,
        true,
      );
    });
  }

  // coups bruts
  List<List<int>> calculateRawcoupsValides(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];
    if (piece == null) {
      return [];
    }
    // dir noir/blanc
    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // pawns: en avant si case vide
        if (Helper.isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
        }

        // pawns: 2 avant si pos initiale
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (Helper.isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

        // pawns: capture diagonale
        if (Helper.isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col - 1]);
        }

        if (Helper.isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col + 1]);
        }
        break;

      case ChessPieceType.rook:
        var directions = [
          [-1, 0], // haut
          [1, 0], // bas
          [0, -1], // gauche
          [0, 1], //droite
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // capture
              }
              break; // bloqué
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.knight:
        // 8 L du knight
        var knightMoves = [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1],
        ];

        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!Helper.isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // kill
            }
            continue; // blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;

      case ChessPieceType.bishop:
        // diagonales
        var directions = [
          [-1, -1],
          [-1, 1],
          [1, 1],
          [1, -1],
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.queen:
        // haut bas gauche droite et diags
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, 1],
          [1, -1],
        ];

        for (var direction in directions) {
          int i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!Helper.isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.king:
        // haut bas gauche droite et diags
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, 1],
          [1, -1],
        ];

        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1];
          if (!Helper.isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // kill
            }
            continue; // blocked
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;
    }
    return candidateMoves;
  }

  List<List<int>> calculateRealcoupsValides(
    int row,
    int col,
    ChessPiece? piece,
    bool checkSimulation,
  ) {
    List<List<int>> realcoupsValides = [];
    List<List<int>> candiateMoves = calculateRawcoupsValides(row, col, piece);

    // filtre tous les check
    if (checkSimulation) {
      for (var move in candiateMoves) {
        int endRow = move[0];
        int endCol = move[1];

        // simule move d'après si valide
        if (simulateMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realcoupsValides.add(move);
        }
      }
    } else {
      realcoupsValides = candiateMoves;
    }
    return realcoupsValides;
  }

  Future<void> movePiece(int newRow, int newCol) async {
    // si case ennemie
    if (board[newRow][newCol] != null) {
      // capture selon couleur
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        blancsCaptures.add(capturedPiece);
      } else {
        noirsCaptures.add(capturedPiece);
      }
    }

    // si roi bougé
    if (selectedPiece!.type == ChessPieceType.king) {
      // uppdate pos
      if (selectedPiece!.isWhite) {
        posKingB = [newRow, newCol];
      } else {
        posKingN = [newRow, newCol];
      }
    }

    if (selectedPiece!.type == ChessPieceType.pawn &&
        ((selectedPiece!.isWhite && newRow == 0) ||
            (!selectedPiece!.isWhite && newRow == 7))) {
      // promotion dame
      selectedPiece = ChessPiece(
        type: ChessPieceType.queen,
        isWhite: selectedPiece!.isWhite,
        img:
            selectedPiece!.isWhite
                ? 'assets/images/pieces/queen_w.png'
                : 'assets/images/pieces/queen_b.png',
      );
    }

    // move piece et null sur ancienne case
    board[newRow][newCol] = selectedPiece;
    board[ligneSelec][colonneSelec] = null;

    // check si roi adverse en échec
    if (isKingInCheck(!tourBlanc)) {
      checkStatus = true;
    } else {
      checkStatus = false;
    }

    // clear selection
    setState(() {
      selectedPiece = null;
      ligneSelec = -1;
      colonneSelec = -1;
      coupsValides = [];
    });

    // victoire si échec et mat
    if (isCheckMate(!tourBlanc)) {
      final winner = tourBlanc ? nomJ1 : nomJ2;
      await incrementScore(winner); // maj scoreboard
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: Text("Bravo ! $winner a remporté la partie."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                  child: const Text("Menu"),
                ),
              ],
            ),
      );
      return;
    }

    // tour adverse
    tourBlanc = !tourBlanc;
  }

  bool isKingInCheck(bool isWhiteKing) {
    // pos roi
    List<int> kingPosition =
        isWhiteKing ? posKingB : posKingN;

    // check si roi en échec
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // pas prendre en compte cases vides ou même couleur
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }

        List<List<int>> piececoupsValides = calculateRealcoupsValides(
          i,
          j,
          board[i][j],
          false,
        );
        // check si roi dans coups valide de piece courante
        if (piececoupsValides.any(
          (move) => move[0] == kingPosition[0] && move[1] == kingPosition[1],
        )) {
          return true;
        }
      }
    }
    return false;
  }

  // simuler move futur pour check si roi safe
  bool simulateMoveIsSafe(
    ChessPiece piece,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    // save état plateau
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    // pour le roi, save sa pos originale
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      originalKingPosition =
          piece.isWhite ? posKingB : posKingN;
      // update sa pos
      if (piece.isWhite) {
        posKingB = [endRow, endCol];
      } else {
        posKingN = [endRow, endCol];
      }
    }

    // simuler le move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // check si notre roi est en échec
    bool kingInCheck = isKingInCheck(piece.isWhite);

    // retouner à état original du plateau
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    // remettre roi à sa place
    if (piece.type == ChessPieceType.king) {
      if (piece.isWhite) {
        posKingB = originalKingPosition!;
      } else {
        posKingN = originalKingPosition!;
      }
    }

    // si roi en échec, safe  move = false
    return !kingInCheck;
  }

  bool isCheckMate(bool isWhiteKing) {
    // si roi pas en échec, pas échec et mat
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }

    // si au moins 1 move valide, pas échec et mat
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // skip cases vides ou même couleur
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }

        List<List<int>> piececoupsValides = calculateRealcoupsValides(
          i,
          j,
          board[i][j],
          true,
        );
        // check si pos roi est dans coups valides d'une autre piece
        if (piececoupsValides.isNotEmpty) {
          return false;
        }
      }
    }

    // si aucune pièce ne peut bouger pour sortir de l'échec
    return true;
  }

  void resetGame() {
    Navigator.pop(context);
    _initializeBoard();
    checkStatus = false;
    blancsCaptures.clear();
    noirsCaptures.clear();
    posKingB = [7, 4];
    posKingN = [0, 4];
    tourBlanc = true;
    setState(() {});
  }

  // FEN
  String _buildFenFromBoard() {
    final sb = StringBuffer();
    // parse
    for (int rank = 7; rank >= 0; rank--) {
      int emptyCount = 0;
      for (int file = 0; file < 8; file++) {
        final piece = board[rank][file];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            sb.write(emptyCount);
            emptyCount = 0;
          }
          // lettre selon piece
          String symbol;
          switch (piece.type) {
            case ChessPieceType.pawn:
              symbol = piece.isWhite ? 'P' : 'p';
              break;
            case ChessPieceType.knight:
              symbol = piece.isWhite ? 'N' : 'n';
              break;
            case ChessPieceType.bishop:
              symbol = piece.isWhite ? 'B' : 'b';
              break;
            case ChessPieceType.rook:
              symbol = piece.isWhite ? 'R' : 'r';
              break;
            case ChessPieceType.queen:
              symbol = piece.isWhite ? 'Q' : 'q';
              break;
            case ChessPieceType.king:
              symbol = piece.isWhite ? 'K' : 'k';
              break;
          }
          sb.write(symbol);
        }
      }
      if (emptyCount > 0) sb.write(emptyCount);
      if (rank > 0) sb.write('/');
    }

    // couleur
    sb.write(tourBlanc ? ' w ' : ' b ');

    // pas de roque
    sb.write('- ');

    // pas de passant
    sb.write('- ');

    // demi-coups (def 01)
    sb.write('0 1');

    return sb.toString();
  }

  /// meilleur coup auto
  void _applyBestMove(String uci) {
    // extract des pos
    int fromFile = uci.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int fromRank = int.parse(uci[1]) - 1;
    int toFile = uci.codeUnitAt(2) - 'a'.codeUnitAt(0);
    int toRank = int.parse(uci[3]) - 1;

    // pos sur board
    ligneSelec = fromRank;
    colonneSelec = fromFile;
    selectedPiece = board[fromRank][fromFile];

    movePiece(toRank, toFile);
  }

  Future<void> showBestMoveHint() async {
    final String fen = _buildFenFromBoard(); // convert FEN
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          ),
    );

    String? sanMove;
    String? comment;
    String? uciMove;
    String errorMessage = '';

    try {
      final response = await http.post(
        Uri.parse('https://chess-api.com/v1'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"fen": fen}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        sanMove = data['san']; // meilleur coup (SAN)
        uciMove = data['move'];
        String text =
            data['text'];
        // extract du commentaire
        int idx = text.indexOf(']. ');
        if (idx != -1) {
          comment = text.substring(idx + 3);
        } else {
          comment = text;
        }
        // trad
        comment = comment
            .replaceAll('White is winning', 'Les Blancs ont l\'avantage')
            .replaceAll('Black is winning', 'Les Noirs ont l\'avantage');
            } else {
        errorMessage =
            "Erreur ${response.statusCode} : échec de l'analyse du coup.";
      }
    } catch (e) {
      errorMessage =
          "Impossible d'obtenir le coup conseillé. Vérifiez la connexion.";
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }

    if (!mounted) return; // si fin widget pendant attente

    Widget dialogContent;
    String dialogTitle;
    if (sanMove != null && comment != null) {
      dialogTitle = "Coup recommandé";
      dialogContent = Text(
        "Meilleur coup : $sanMove\nCommentaire : $comment",
        style: TextStyle(fontSize: 16),
      );
    } else {
      dialogTitle = "Triche indisponible";
      dialogContent = Text(
        errorMessage.isNotEmpty
            ? errorMessage
            : "Le service de triche est indisponible pour le moment.",
        style: TextStyle(fontSize: 16),
      );
    }

    // popup meilleur coup
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(dialogTitle),
            content: dialogContent,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
              if (uciMove != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // fin popup
                    _applyBestMove(uciMove!); // coup
                  },
                  child: const Text("Effectuer le coup"),
                ),
            ],
          ),
    );
  }

  // handlers pour boutons bas
  Future<void> _offerDraw() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Match nul!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
                child: const Text('Menu'),
              ),
            ],
          ),
    );
  }

  Future<void> _resign() async {
    final loser = tourBlanc ? nomJ1 : nomJ2;
    final winner = tourBlanc ? nomJ2 : nomJ1;
    await incrementScore(winner);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text('$loser abandonne. $winner remporte donc la partie !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()),
                  );
                },
                child: const Text('Menu'),
              ),
            ],
          ),
    );
  }

  Future<void> _cheat() async {
    await showBestMoveHint();
  }

  @override
  Widget build(BuildContext context) {
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 8,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5122A3), Color(0xFF7C4BD1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // todo refaire alerte echec
              //Text(checkStatus ? "CHECK!" : ""),

              // infos joueurs + timer
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Joueur 1
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/player1.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomJ1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$victoiresJ1 victoire${victoiresJ1 > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Timer
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/timer.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(
                            tourBlanc ? tpsRestantB : tpsRestantN,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7D56BF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Au tour de\n${tourBlanc ? nomJ1 : nomJ2}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Joueur 2
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/player2.png',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nomJ2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$victoiresJ2 victoire${victoiresJ2 > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // captures blancs
              Expanded(
                child: GridView.builder(
                  itemCount: blancsCaptures.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    return DeadPieces(
                      imgPath: blancsCaptures[index]!.img,
                      isWhite: true,
                    );
                  },
                ),
              ),

              // board
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          itemCount: 8 * 8,
                          gridDelegate: gridDelegate,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // pos de la case
                            int row = index ~/ 8;
                            int col = index % 8;

                            // check si case selectionnee
                            bool isSelected =
                                row == ligneSelec && col == colonneSelec;

                            // check coup valide
                            bool isValidMove = false;
                            for (var position in coupsValides) {
                              if (position[0] == row && position[1] == col) {
                                isValidMove = true;
                              }
                            }
                            return Square(
                              isWhite: Helper.isWhite(index),
                              piece: board[row][col],
                              isSelected: isSelected,
                              isValidMove: isValidMove,
                              onTap: () => selectPiece(row, col),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // captures noirs
              Expanded(
                child: GridView.builder(
                  itemCount: noirsCaptures.length,
                  gridDelegate: gridDelegate,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return DeadPieces(
                      imgPath: noirsCaptures[index]!.img,
                      isWhite: false,
                    );
                  },
                ),
              ),

              // boutons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _offerDraw,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/draw.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nulle',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _resign,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/abandon.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Abandon',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _cheat,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/triche.png',
                            width: 50,
                            height: 50,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Triche',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
