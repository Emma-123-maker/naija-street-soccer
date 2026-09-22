import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(NaijaStreetSoccer());

class NaijaStreetSoccer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // YOU - IMPROVED!
  double youX = 0.5, youY = 0.8;
  double youSpeed = 0.018; // Was 0.008 - NOW 2x FASTER!
  
  // AI Opponent
  double aiX = 0.5, aiY = 0.2;
  double aiSpeed = 0.006; // Was 0.01 - NOW SLOWER!
  
  // Ball
  double ballX = 0.5, ballY = 0.5;
  double ballVX = 0, ballVY = 0;
  bool ballWithYou = false;
  bool ballWithAI = false;
  
  // Score
  int youScore = 0, aiScore = 0;
  
  // Controls
  double joyX = 0, joyY = 0;
  bool isShooting = false;
  
  Timer? gameLoop;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    gameLoop = Timer.periodic(Duration(milliseconds: 16), (t) {
      setState(() {
        // Move YOU with joystick - FASTER!
        youX += joyX * youSpeed;
        youY += joyY * youSpeed;
        youX = youX.clamp(0.05, 0.95);
        youY = youY.clamp(0.05, 0.95);

        // Move AI (simple)
        if (!ballWithAI) {
          if (aiX < ballX) aiX += aiSpeed;
          if (aiX > ballX) aiX -= aiSpeed;
          if (aiY < ballY) aiY += aiSpeed;
          if (aiY > ballY) aiY -= aiSpeed;
        } else {
          // AI attacks your goal
          if (aiY < 0.9) aiY += aiSpeed * 0.8;
        }

        // Ball physics
        if (!ballWithYou && !ballWithAI) {
          ballX += ballVX;
          ballY += ballVY;
          ballVX *= 0.98;
          ballVY *= 0.98;
          if (ballVX.abs() < 0.001) ballVX = 0;
          if (ballVY.abs() < 0.001) ballVY = 0;
        }

        // Check ball pickup
        if ((youX - ballX).abs() < 0.07 && (youY - ballY).abs() < 0.07) {
          ballWithYou = true; ballWithAI = false;
        }
        if ((aiX - ballX).abs() < 0.07 && (aiY - ballY).abs() < 0.07) {
          ballWithAI = true; ballWithYou = false;
          // AI shoots after 1 sec
          Future.delayed(Duration(milliseconds: 800), () {
            if (ballWithAI) aiShoot();
          });
        }

        // Ball follows player
        if (ballWithYou) { ballX = youX; ballY = youY - 0.05; }
        if (ballWithAI) { ballX = aiX; ballY = aiY + 0.05; }

        // GOAL CHECK
        if (ballY < 0.02 && ballX > 0.35 && ballX < 0.65) {
          youScore++; resetBall();
        }
        if (ballY > 0.98 && ballX > 0.35 && ballX < 0.65) {
          aiScore++; resetBall();
        }

        // Wall bounce
        if (ballX < 0.02 || ballX > 0.98) ballVX *= -1;
      });
    });
  }

  void resetBall() {
    ballX = 0.5; ballY = 0.5;
    ballVX = 0; ballVY = 0;
    ballWithYou = false; ballWithAI = false;
    if (youScore >= 3 || aiScore >= 3) {
      gameLoop?.cancel();
      showResult();
    }
  }

  void showResult() {
    showDialog(context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(youScore >= 3 ? "YOU WIN! 🇳🇬🔥" : "YOU LOSE 😭"),
        content: Text("Score $youScore : $aiScore"),
        actions: [TextButton(onPressed: (){
          Navigator.pop(context);
          setState((){youScore=0; aiScore=0;}); startGame();
        }, child: Text("PLAY AGAIN"))],
      ));
  }

  void shoot() {
    if (!ballWithYou) return;
    setState(() {
      ballWithYou = false;
      // SUPER SHOT - MUCH STRONGER!
      ballVY = -0.035; // Was -0.015
      ballVX = (Random().nextDouble() - 0.5) * 0.01;
    });
  }

  void aiShoot() {
    setState(() {
      ballWithAI = false;
      ballVY = 0.02;
      ballVX = (Random().nextDouble() - 0.5) * 0.015;
    });
  }

  void pass() {
    if (!ballWithYou) return;
    setState(() {
      ballWithYou = false;
      ballVX = (Random().nextDouble() - 0.5) * 0.02;
      ballVY = -0.02;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PITCH
          Container(color: Color(0xFF2E7D32)),
          CustomPaint(size: Size.infinite, painter: PitchPainter()),
          
          // Score
          Positioned(top: 40, left: 0, right: 0,
            child: Center(child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
              child: Text("$youScore : $aiScore", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ))),
          Positioned(top: 75, left: 0, right: 0, child: Center(child: Text("First to 3 wins!", style: TextStyle(color: Colors.white)))),
          
          // Goals
          Positioned(top: 0, left: MediaQuery.of(context).size.width*0.35, child: Container(width: MediaQuery.of(context).size.width*0.3, height: 10, color: Colors.white)),
          Positioned(bottom: 0, left: MediaQuery.of(context).size.width*0.35, child: Container(width: MediaQuery.of(context).size.width*0.3, height: 10, color: Colors.white)),

          // Ball
          Positioned(left: MediaQuery.of(context).size.width*ballX - 10, top: MediaQuery.of(context).size.height*ballY - 10,
            child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black)))),
          
          // YOU - Blue
          Positioned(left: MediaQuery.of(context).size.width*youX - 20, top: MediaQuery.of(context).size.height*youY - 20,
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: Center(child: Text("YOU", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
          
          // AI - Red
          Positioned(left: MediaQuery.of(context).size.width*aiX - 20, top: MediaQuery.of(context).size.height*aiY - 20,
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
              child: Center(child: Text("AI", style: TextStyle(color: Colors.white, fontSize: 10))))),

          // CONTROLS - Fixed layout!
          Positioned(bottom: 20, left: 20, child: Container(
            width: 110, height: 110,
            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  joyX = (d.localPosition.dx - 55) / 55;
                  joyY = (d.localPosition.dy - 55) / 55;
                  if (joyX > 1) joyX = 1; if (joyX < -1) joyX = -1;
                  if (joyY > 1) joyY = 1; if (joyY < -1) joyY = -1;
                });
              },
              onPanEnd: (_) => setState((){joyX=0; joyY=0;}),
              child: Icon(Icons.gamepad, color: Colors.white70, size: 50),
            ))),
          
          Positioned(bottom: 100, right: 20, child: GestureDetector(onTap: shoot,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              child: Center(child: Text("SHOOT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
          
          Positioned(bottom: 20, right: 20, child: GestureDetector(onTap: pass,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              child: Center(child: Text("PASS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))),
        ],
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 2;
    c.drawLine(Offset(0, s.height/2), Offset(s.width, s.height/2), p);
    c.drawCircle(Offset(s.width/2, s.height/2), 60, p);
  }
  @override bool shouldRepaint(_) => false;
}
