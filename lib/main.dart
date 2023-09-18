import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'TicTacToe App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    List<String> board = List.filled(9, ''); // Represents the game board.
    bool isXNext = true;
    Widget _buildTile(int index) {
      return GestureDetector(
        onTap: () {
          _onTileTapped(index);
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(),
          ),
          child: Center(
            child: Text(
              board[index],
              style: TextStyle(fontSize: 40),
            ),
          ),
      ),
      );
    }
  void _onTileTapped(int index) {
    if (board[index] == '') {
      setState(() {
        board[index] = isXNext ? 'X' : 'O';
        isXNext = !isXNext;
      });
    }
  }
  bool checkForWin() {
    // Check rows
    for (int i = 0; i < 9; i += 3) {
      if (board[i] != '' &&
          board[i] == board[i + 1] &&
          board[i] == board[i + 2]) {
        return true;
      }
    }
    // Check columns
    for (int i = 0; i < 3; i++) {
      if (board[i] != '' &&
          board[i] == board[i + 3] &&
          board[i] == board[i + 6]) {
        return true;
      }
    }
    // Check diagonals
    if (board[0] != '' && board[0] == board[4] && board[0] == board[8]) {
      return true;
    }
    if (board[2] != '' && board[2] == board[4] && board[2] == board[6]) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {  
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TicTacToe'),
            SizedBox(height: 20),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                return _buildTile(index);
              },
              itemCount: 9,
              shrinkWrap: true,
            ),
            SizedBox(height: 20),
            Text(
              isXNext ? 'Next Player: X' : 'Next Player: O',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}