import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(NaijaStreetSoccer());
class NaijaStreetSoccer extends StatelessWidget {
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner: false, home: GameScreen());
}
class GameScreen extends StatefulWidget {
  @override _GameScreenState createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  // EQUAL SPEED - FAIR + REAL
  double youX=0.5, youY=0.8, baseSpeed=0.009;
  double aiX=0.5, aiY=0.2;
  double ballX=0.5, ballY=0.5, ballVX=0, ballVY=0;
  bool ballWithYou=false, ballWithAI=false;
  int youScore=0, aiScore=0;
  double joyX=0, joyY=0, joyDist=0;
  bool sprinting=false;
  Timer? gameLoop;
  double shootPower=0;
  Timer? powerTimer;

  @override void initState(){super.initState(); startGame();}

  void startGame(){
    gameLoop=Timer.periodic(Duration(milliseconds: 16), (t){
      setState((){
        double speed = baseSpeed * (sprinting && ballWithYou? 1.8 : 1.0) * (0.5 + joyDist);
        // Real momentum
        youX += joyX * speed;
        youY += joyY * speed;
        youX=youX.clamp(0.06,0.94); youY=youY.clamp(0.06,0.94);

        // AI - EQUAL SPEED, same logic
        double aiSpeed = baseSpeed * (ballWithAI? 1.3 : 1.0);
        if(!ballWithAI &&!ballWithYou){
          if(aiX < ballX) aiX+=aiSpeed * (ballX-aiX).abs()*2;
          if(aiX > ballX) aiX-=aiSpeed * (ballX-aiX).abs()*2;
          if(aiY < ballY) aiY+=aiSpeed;
          if(aiY > ballY) aiY-=aiSpeed*0.5;
        } else if(ballWithAI){
          if(aiY < 0.85) aiY+=aiSpeed;
          // AI dribbles to goal
          aiX += (0.5-aiX)*0.01;
        }
        aiX=aiX.clamp(0.06,0.94); aiY=aiY.clamp(0.06,0.94);

        // Ball physics - REAL
        if(!ballWithYou &&!ballWithAI){
          ballX+=ballVX; ballY+=ballVY;
          ballVX*=0.985; ballVY*=0.985;
          if(ballVX.abs()<0.0005) ballVX=0;
          if(ballVY.abs()<0.0005) ballVY=0;
        }

        // Tackle / Pickup - REAL FOOTBALL distance
        double youDist = sqrt(pow(youX-ballX,2)+pow(youY-ballY,2));
        double aiDist = sqrt(pow(aiX-ballX,2)+pow(aiY-ballY,2));
        if(youDist < 0.06 && aiDist > youDist){ballWithYou=true; ballWithAI=false; ballVX=0; ballVY=0;}
        if(aiDist < 0.06 && youDist > aiDist){ballWithAI=true; ballWithYou=false; ballVX=0; ballVY=0; Future.delayed(Duration(milliseconds: 700), (){ if(ballWithAI) aiShoot(); });}

        // Dribble - ball in front of player based on joystick direction
        if(ballWithYou){
          double offset = 0.05 + (sprinting?0.03:0);
          ballX = youX + joyX*offset;
          ballY = youY + joyY*offset - 0.02;
          if(joyDist < 0.1){ballX=youX; ballY=youY-0.05;}
        }
        if(ballWithAI){ballX=aiX; ballY=aiY+0.05;}

        // Goals
        if(ballY<0.02 && ballX>0.32 && ballX<0.68){youScore++; resetBall();}
        if(ballY>0.98 && ballX>0.32 && ballX<0.68){aiScore++; resetBall();}
        if(ballX<0.02 || ballX>0.98){ballVX*=-0.8; ballX=ballX.clamp(0.02,0.98);}
      });
    });
  }

  void resetBall(){ballX=0.5; ballY=0.5; ballVX=0; ballVY=0; ballWithYou=false; ballWithAI=false; if(youScore>=3 || aiScore>=3){gameLoop?.cancel(); showResult();}}
  void showResult(){showDialog(context: context, barrierDismissible: false, builder: (_)=>AlertDialog(title: Text(youScore>=3?"YOU WIN! 🏆 REAL BALLER!":"YOU LOSE - FAIR GAME"), content: Text("Score $youScore : $aiScore\nEqual Speed Mode"), actions: [TextButton(onPressed: (){Navigator.pop(context); setState((){youScore=0; aiScore=0;}); startGame();}, child: Text("PLAY AGAIN"))]));}

  void startShootPower(){powerTimer=Timer.periodic(Duration(milliseconds: 50), (t){setState((){if(shootPower<1) shootPower+=0.05;});});}
  void doShoot(){
    powerTimer?.cancel();
    if(!ballWithYou) {shootPower=0; return;}
    setState((){
      ballWithYou=false;
      double power = 0.015 + shootPower*0.03; // hold = stronger
      double dirX = joyDist>0.2? joyX : (Random().nextDouble()-0.5)*0.3;
      double dirY = joyDist>0.2 && joyY<-0.2? joyY : -1;
      ballVX = dirX * power;
      ballVY = dirY * power;
      shootPower=0;
    });
  }
  void doPass(){
    if(!ballWithYou) return;
    setState((){
      ballWithYou=false;
      double px = joyDist>0.2? joyX : 0;
      double py = joyDist>0.2? joyY : -1;
      ballVX = px * 0.018;
      ballVY = py * 0.018;
    });
  }
  void aiShoot(){setState((){ballWithAI=false; ballVY=0.022; ballVX=(Random().nextDouble()-0.5)*0.01;});}

  @override Widget build(BuildContext context){
    double w=MediaQuery.of(context).size.width, h=MediaQuery.of(context).size.height;
    return Scaffold(body: Stack(children: [
      Container(color: Color(0xFF2E7D32)),
      CustomPaint(size: Size.infinite, painter: PitchPainter()),
      // Score
      Positioned(top:35,left:0,right:0,child: Center(child: Container(padding: EdgeInsets.symmetric(horizontal:18,vertical:6), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)), child: Text("$youScore : $aiScore EQUAL + REAL CONTROLS", style: TextStyle(color: Colors.white, fontSize:14, fontWeight: FontWeight.bold))))),
      // Power bar
      if(shootPower>0) Positioned(top:70,left:w*0.35,right:w*0.35,child: Container(height:8, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: shootPower, child: Container(decoration: BoxDecoration(color: shootPower>0.7?Colors.red:Colors.yellow, borderRadius: BorderRadius.circular(4)))))),
      // Ball
      Positioned(left: w*ballX-11, top: h*ballY-11, child: Container(width:22,height:22,decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 4)], border: Border.all(color: Colors.black)), child: Center(child: Container(width:6,height:6, decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle))))),
      // YOU
      Positioned(left: w*youX-22, top: h*youY-22, child: Column(children:[Container(width:44,height:44,decoration: BoxDecoration(color: Colors.blue[700], shape: BoxShape.circle, border: Border.all(color: Colors.white,width:3), boxShadow: [BoxShadow(color: sprinting?Colors.yellow:Colors.transparent, blurRadius: 8)]), child: Center(child: Text("YOU", style: TextStyle(color: Colors.white, fontSize:9, fontWeight: FontWeight.bold)))), if(ballWithYou) Container(margin: EdgeInsets.only(top:2), padding: EdgeInsets.symmetric(horizontal:4,vertical:1), decoration: BoxDecoration(color: Colors.yellow, borderRadius: BorderRadius.circular(4)), child: Text("BALL", style: TextStyle(fontSize:7, fontWeight: FontWeight.bold)))])),
      // AI
      Positioned(left: w*aiX-20, top: h*aiY-20, child: Container(width:40,height:40,decoration: BoxDecoration(color: Colors.red[700], shape: BoxShape.circle, border: Border.all(color: Colors.white,width:2)), child: Center(child: Text("AI", style: TextStyle(color: Colors.white, fontSize:9))))),
      // JOYSTICK - REAL 360
      Positioned(bottom:20,left:15,child: Container(width:125,height:125,decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)), child: GestureDetector(onPanUpdate: (d){var dx=d.localPosition.dx-62.5, dy=d.localPosition.dy-62.5, dist=sqrt(dx*dx+dy*dy); setState((){joyDist=(dist/55).clamp(0,1); joyX= (dx/55).clamp(-1,1); joyY= (dy/55).clamp(-1,1);});}, onPanEnd: (_)=>setState((){joyX=0; joyY=0; joyDist=0;}), child: Stack(alignment: Alignment.center, children:[if(joyDist>0.1) Positioned(left: 62.5+joyX*30-15, top: 62.5+joyY*30-15, child: Container(width:30,height:30,decoration: BoxDecoration(color: Colors.white70, shape: BoxShape.circle))), Icon(Icons.gamepad, color: Colors.white38, size:40)])))),
      // SPRINT
      Positioned(bottom:150,left:20,child: GestureDetector(onTapDown: (_)=>setState(()=>sprinting=true), onTapUp: (_)=>setState(()=>sprinting=false), onTapCancel: ()=>setState(()=>sprinting=false), child: Container(width:60,height:60,decoration: BoxDecoration(color: sprinting?Colors.orange:Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white30)), child: Center(child: Text("SPRINT", style: TextStyle(color: Colors.white, fontSize:8, fontWeight: FontWeight.bold)))))),
      // SHOOT - HOLD FOR POWER
      Positioned(bottom:100,right:15,child: GestureDetector(onTapDown: (_)=>startShootPower(), onTapUp: (_)=>doShoot(), onTapCancel: ()=>doShoot(), child: Container(width:85,height:85,decoration: BoxDecoration(color: Colors.red[600], shape: BoxShape.circle, border: Border.all(color: Colors.white, width:2), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: shootPower*10)]), child: Center(child: Text("SHOOT\nHOLD=POWER", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:9)))))),
      // PASS - DIRECTIONAL
      Positioned(bottom:15,right:15,child: GestureDetector(onTap: doPass, child: Container(width:85,height:85,decoration: BoxDecoration(color: Colors.blue[600], shape: BoxShape.circle, border: Border.all(color: Colors.white, width:2)), child: Center(child: Text("PASS\n→ JOY DIR", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:9)))))),
    ]));
  }
}
class PitchPainter extends CustomPainter{
  @override void paint(Canvas c, Size s){
    var p=Paint()..color=Colors.white38..style=PaintingStyle.stroke..strokeWidth=1.5;
    c.drawLine(Offset(0,s.height/2), Offset(s.width,s.height/2), p);
    c.drawCircle(Offset(s.width/2,s.height/2), 70, p);
    c.drawRect(Rect.fromCenter(center: Offset(s.width/2,s.height*0.08), width: s.width*0.4, height: 60), p);
    c.drawRect(Rect.fromCenter(center: Offset(s.width/2,s.height*0.92), width: s.width*0.4, height: 60), p);
  }
  @override bool shouldRepaint(_)=>false;
}
