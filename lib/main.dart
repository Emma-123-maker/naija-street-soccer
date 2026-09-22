import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: NaijaStreetSoccer()));

class PlayerData {
  Offset pos;
  Offset target;
  bool isUserTeam;
  bool hasBall = false;
  PlayerData(this.pos, this.isUserTeam) : target = pos;
}

class NaijaStreetSoccer extends StatefulWidget {
  const NaijaStreetSoccer({super.key});
  @override State<NaijaStreetSoccer> createState() => _NaijaStreetSoccerState();
}

class _NaijaStreetSoccerState extends State<NaijaStreetSoccer> with SingleTickerProviderStateMixin {
  late AnimationController gameLoop;

  List<PlayerData> myTeam = [];
  List<PlayerData> enemyTeam = [];
  Offset ballPos = const Offset(200, 400);
  Offset ballVel = Offset.zero;
  int myScore = 0;
  int enemyScore = 0;
  int controlledIndex = 0; // you control 1 player
  Offset joystickDelta = Offset.zero;
  String msg = "Naija Street Soccer - Shooting Stars!";

  @override
  void initState() {
    super.initState();
    // 5v5 Setup
    myTeam = [
      PlayerData(const Offset(200, 700), true), // you - striker
      PlayerData(const Offset(100, 600), true),
      PlayerData(const Offset(300, 600), true),
      PlayerData(const Offset(100, 750), true),
      PlayerData(const Offset(300, 750), true),
    ];
    enemyTeam = [
      PlayerData(const Offset(200, 100), false),
      PlayerData(const Offset(100, 200), false),
      PlayerData(const Offset(300, 200), false),
      PlayerData(const Offset(100, 80), false),
      PlayerData(const Offset(300, 80), false),
    ];
    controlledIndex = 0;

    gameLoop = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    gameLoop.addListener(updateGame);
  }

  void updateGame() {
    setState(() {
      // 1. Move controlled player with joystick
      if (joystickDelta!= Offset.zero) {
        myTeam[controlledIndex].pos += joystickDelta * 4;
      }

      // 2. Ball physics
      ballPos += ballVel;
      ballVel *= 0.98; // friction
      if (ballVel.distance < 0.5) ballVel = Offset.zero;

      // Keep ball in field
      ballPos = Offset(ballPos.dx.clamp(20, 380), ballPos.dy.clamp(20, 780));

      // 3. Check who has ball
      for (var p in [...myTeam,...enemyTeam]) p.hasBall = false;
      for (var p in [...myTeam,...enemyTeam]) {
        if ((p.pos - ballPos).distance < 22) {
          p.hasBall = true;
          ballPos = p.pos + const Offset(0, -12); // ball at feet
          // Auto-switch control to ball holder if my team
          if (p.isUserTeam) {
            controlledIndex = myTeam.indexOf(p);
          }
          break;
        }
      }

      // 4. Enemy AI - chase ball
      for (var enemy in enemyTeam) {
        if (!enemy.hasBall) {
          var dir = ballPos - enemy.pos;
          if (dir.distance > 5) {
            enemy.pos += dir / dir.distance * 1.8;
          }
          // If enemy has ball, run to your goal and shoot
          if ((enemy.pos - ballPos).distance < 25) {
            ballVel = Offset((Random().nextDouble() - 0.5) * 10, 15); // shoot down
          }
        }
      }

      // 5. My team AI - support
      for (int i=0; i<myTeam.length; i++) {
        if (i == controlledIndex) continue;
        if (!myTeam[i].hasBall) {
          // move slightly towards ball but keep formation
          var dir = ballPos - myTeam[i].pos;
          if (dir.distance > 120) {
            myTeam[i].pos += dir / dir.distance * 0.6;
          }
        }
      }

      // 6. Goal Check (Top goal = enemy defends, Bottom goal = you defend)
      bool inTopGoal = ballPos.dy < 30 && ballPos.dx > 140 && ballPos.dx < 260;
      bool inBottomGoal = ballPos.dy > 770 && ballPos.dx > 140 && ballPos.dx < 260;

      if (inTopGoal) {
        myScore++;
        msg = "GOAL!!! SHOOTING STARS SCORED! 🔥";
        resetRound();
      }
      if (inBottomGoal) {
        enemyScore++;
        msg = "Goal conceded... defend!";
        resetRound();
      }
    });
  }

  void resetRound() {
    ballPos = const Offset(200, 400);
    ballVel = Offset.zero;
    Future.delayed(const Duration(seconds: 1), () => setState(() => msg = "First to 3 wins!"));
  }

  void doPass() {
    if (!myTeam[controlledIndex].hasBall) return;
    // Find nearest teammate
    PlayerData? best;
    double bestDist = 9999;
    for (var teammate in myTeam) {
      if (teammate == myTeam[controlledIndex]) continue;
      double d = (teammate.pos - myTeam[controlledIndex].pos).distance;
      if (d < bestDist) { bestDist = d; best = teammate; }
    }
    if (best!= null) {
      ballVel = (best.pos - ballPos) / 8;
      setState(() => msg = "Nice pass!");
    }
  }

  void doShoot() {
    if (!myTeam[controlledIndex].hasBall) return;
    // Shoot to top goal with some spread
    double spread = (Random().nextDouble() - 0.5) * 60;
    Offset goalCenter = Offset(200 + spread, 0);
    ballVel = (goalCenter - ballPos) / 6;
    ballVel = Offset(ballVel.dx.clamp(-20, 20), ballVel.dy.clamp(-30, -10));
    setState(() => msg = "SHOT!!! ⚽");
  }

  @override
  void dispose() { gameLoop.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Stack(
        children: [
          // FIELD
          Positioned.fill(child: CustomPaint(painter: FieldPainter())),

          // Goals
          Positioned(top: 0, left: 140, child: Container(width: 120, height: 10, color: Colors.white)),
          Positioned(bottom: 0, left: 140, child: Container(width: 120, height: 10, color: Colors.white)),

          // Players - Enemy (Red)
         ...enemyTeam.map((p) => Positioned(
            left: p.pos.dx - 14, top: p.pos.dy - 14,
            child: CircleAvatar(radius: 14, backgroundColor: p.hasBall? Colors.orange : Colors.red, child: const Text("E", style: TextStyle(fontSize: 10, color: Colors.white)))
          )),

          // Players - My Team (Blue)
         ...myTeam.asMap().entries.map((e) {
            var p = e.value;
            bool isControlled = e.key == controlledIndex;
            return Positioned(
              left: p.pos.dx - 15, top: p.pos.dy - 15,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: p.hasBall? Colors.yellow : (isControlled? Colors.blue[700] : Colors.blue[300]),
                  shape: BoxShape.circle,
                  border: isControlled? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: Center(child: Text(isControlled? "YOU" : "S", style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            );
          }),

          // Ball
          Positioned(left: ballPos.dx - 9, top: ballPos.dy - 9, child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Center(child: Text("⚽", style: TextStyle(fontSize: 12))))),

          // Score
          SafeArea(child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text("$enemyScore : $myScore", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))))),
          SafeArea(child: Padding(padding: const EdgeInsets.only(top: 50), child: Center(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),

          // JOYSTICK (Bottom Left)
          Positioned(
            left: 20, bottom: 100,
            child: GestureDetector(
              onPanUpdate: (d) { setState(() => joystickDelta = d.delta); },
              onPanEnd: (_) => setState(() => joystickDelta = Offset.zero),
              child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle, border: Border.all(color: Colors.white30)), child: const Icon(Icons.gamepad, color: Colors.white54, size: 50)),
            ),
          ),

          // PASS & SHOOT (Bottom Right)
          Positioned(
            right: 20, bottom: 90,
            child: Column(
              children: [
                ElevatedButton(onPressed: doShoot, style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(28), backgroundColor: Colors.red), child: const Text("SHOOT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(height: 15),
                ElevatedButton(onPressed: doPass, style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(28), backgroundColor: Colors.blue), child: const Text("PASS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FieldPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white30..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width-20, size.height-20), paint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), paint);
    canvas.drawCircle(Offset(size.width/2, size.height/2), 50, paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
