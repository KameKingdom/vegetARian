// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*; 

SoundFile bgm;
SoundFile instructionSound;
SoundFile openingSound;
SoundFile attackSound;
SoundFile winSound;
SoundFile loseSound;

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー

int windowHandler = 0; // windowのhandler
/**
0: opening
1: instruction
2: battle
3: result
4: exit();
**/

String title = "beastARia";
String guideMessage = "PRESS N OR ENTER to continue...";
String instructionMessage = "[A]  -  ATTACK \n[N]  -  NEXT WINDOW \n[Q]  -  QUIT \nWhen HP is 0, you lose";

// battle window　用変数 //
Character[] cards; // キャラクターの配列変数
int character_num = 3; // キャラクターの数
int cards_num = character_num + 1 + 1 + 1;

int playerIndex = -1;
int enemyIndex = character_num; // 敵のモンスターのインデックス
int checkStatusIndex = enemyIndex + 1; // ステータス確認用マーカーのインデックス
int attackMarkerIndex = checkStatusIndex + 1; // 攻撃用マーカーのインデックス

boolean isAttacking = false; // 攻撃フラグ
boolean isCheckingStatus = false; // ステータス確認フラグ
boolean isFinished = false; // 終了フラグ
boolean isChangedMusic = true; // 音楽変更フラグ
boolean isWin = false; // 勝利フラグ

int turn = 1;
String[] enemyMonsterFiles = {"greenpepper.obj", "apple.obj", "Chicken.obj"}; // 敵モンスターのファイル名
String message = "Scan Your Card !!";

// 初期設定 //
void setup() {
  // ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  camera = new Capture(this, cameras[cameras.length - 1]); // カメラを設定
  camera.start(); // カメラ起動

  // 効果音設定 //
  bgm = new SoundFile(this, "sound/bgm.wav");
  instructionSound = new SoundFile(this, "sound/instruction.wav");
  openingSound = new SoundFile(this, "sound/opening.wav");
  attackSound = new SoundFile(this, "sound/attack.wav");
  winSound = new SoundFile(this, "sound/win.wav");
  loseSound = new SoundFile(this, "sound/lose.wav");

  // ARの設定 //
  int marker_num = 10;
  markers = new MultiMarker[marker_num];
  for (int i = 0; i < marker_num; i++) {
    markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
    markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }

  // キャラクターの作成 //
  cards = new Character[cards_num];
  cards[0] = new Character("greenpepper.obj"); // 自陣モンスターを設定
  cards[1] = new Character("apple.obj");
  cards[2] = new Character("Chicken.obj");
  cards[enemyIndex] = null; // 敵陣モンスターの初期化
  cards[checkStatusIndex] = null; // ステータス確認マーカー
  cards[attackMarkerIndex] = null; // 攻撃用マーカー
}

// キャラクターのクラス //
class Character {
  PShape shape;
  String name;
  int HP;
  int ATK;
  float scale;
  float angle = 0.0; // 角度
  int height = 0; // 高度

  // 動きに関するパラメータ //
  
  float rotate_value = 0.0;
  int updown_value = 0;

  Character(String filename) {
    shape = loadShape(filename);
    setParameter(filename);
  }

  void setParameter(String filename){
    if(filename.equals("greenpepper.obj")){ this.name = "GreenPepper"; this.HP = 100; this.ATK = 10; this.scale = 0.2; this.rotate_value = 0.05;}
    else if(filename.equals("apple.obj")){ this.name = "apple"; this.HP = 90; this.ATK = 15; this.scale = 200; this.rotate_value = 0.05;}
    else if(filename.equals("Chicken.obj")){ this.name = "Plane"; this.HP = 150; this.ATK = 30; this.scale = 0.7; this.updown_value = 1; }
    else{this.name = "unknown"; this.HP = 0; this.ATK = 0; this.scale = 0;}
  }
  
  void takeDamage(int damage) {
    this.HP -= damage;
    if (this.HP <= 0){ // 死んだ際にお墓にする
      shape = loadShape("OBJ.obj");
      this.HP = 0;
      this.ATK = 0;
      this.scale = 0.5;
      this.angle = 0.0;
      this.height = 0;
      this.rotate_value = 0.0;
      this.updown_value = 0;
    }
  }

  void move(){
    if(this.height < 10){ this.updown_value = abs(this.updown_value);}
    if(this.height > 50){ this.updown_value = - abs(this.updown_value);}
    this.angle += this.rotate_value;
    this.height += this.updown_value;
  }
}

void draw() {
  if (windowHandler == 0) { // Opening Window
    if (isChangedMusic){
      openingSound.loop();
      isChangedMusic = false;
    }
    background(0);
    fill(255);
    textSize(48);
    text(title, (width - textWidth(title)) / 2, height / 2);
    fill(200);
    textSize(18);
    text(guideMessage, (width - textWidth(guideMessage)) / 2, 300);
  }
  else if (windowHandler == 1){ // Instruction Window
    if (isChangedMusic){
      openingSound.stop();
      instructionSound.loop();
      isChangedMusic = false;
    }
    background(0);
    fill(255);
    textSize(30);
    text("-- Instruction --", (width - textWidth("-- Instruction --")) / 2, 45);
    text(instructionMessage, 200, 150);
    fill(200);
    textSize(18);
    text(guideMessage, (width - textWidth(guideMessage)) / 2, 400);
  }
  else if (windowHandler == 2){ // Battle Window
    if (isChangedMusic){
      instructionSound.stop();
      bgm.loop();
      isChangedMusic = false;
    }
    if (camera.available()) {
      camera.read();
      lights();

      // メッセージボックスの描画
      fill(220);
      stroke(0);
      rect(0, 0, 640, 40); // 上
      rect(0, 400, 640, 80); // 下

      fill(0);
      textSize(24);
      text("turn " + turn, (width - textWidth("turn " + turn)) / 2, 27);
      text(message, (width - textWidth(message)) / 2, 445);
        
      for (int i = 0; i < markers.length; i++) {
        markers[i].detect(camera);
        markers[i].drawBackground(camera);
        
        if (markers[i].isExist(0)) {
          markers[i].beginTransform(0); // マーカー中心を原点に設定
          
          // キャラクター //
          if (i <= character_num && cards[i] != null) {
            cards[i].move();
            pushMatrix();
            translate(0, 0, cards[i].height);
            scale(cards[i].scale);
            rotateX(PI / 2);
            rotateY(cards[i].angle);
            shape(cards[i].shape);
            popMatrix();

            // HPの表示 //
            if (i == enemyIndex && cards[enemyIndex].HP != 0) {
              int textSize = 60;
              pushMatrix();
              translate(-textSize/2, 0, 100);
              textMode(SHAPE);
              textSize(textSize);
              rotateX(- PI / 2);
              fill(255);
              text(cards[i].HP, 0, 0); 
              popMatrix();
            }
            else if(i != enemyIndex){
              playerIndex = i;
              message = "Your food is " + cards[i].name;
            }
          }

          fill(255); // 初期化

          // ステータス確認マーカーが認識されたら、ステータスを表示します。
          if (i == checkStatusIndex && playerIndex != -1) {
            isCheckingStatus = true;
            int textSize = 30;
            pushMatrix();
            translate(-textSize/2, 0, 150);
            textMode(SHAPE);
            textSize(textSize);
            rotateX(- PI / 2);
            fill(255);
            text(cards[playerIndex].name + "\nHP: " + cards[playerIndex].HP + "\nATK: " + cards[playerIndex].ATK, 0, 0); 
            popMatrix();
            isCheckingStatus = false;
          }
          markers[i].endTransform(); // マーカー中心を原点から解除
        }
      }
      
      if (cards[enemyIndex] == null) {
        int randomIndex = (int) random(0, enemyMonsterFiles.length);
        cards[enemyIndex] = new Character(enemyMonsterFiles[randomIndex]);
      }
      if (isAttacking) { // 攻撃
        isAttacking = false;
        cards[enemyIndex].takeDamage(cards[playerIndex].ATK);
        cards[playerIndex].takeDamage(cards[enemyIndex].ATK);
      }
      if (playerIndex != -1 || (cards[enemyIndex].HP == 0)){ // 結果表示
        if (cards[enemyIndex].HP == 0){
          message = "YOU WIN !! PRESS N or ENTER";
          isFinished = true;
          isWin = true;
        }
        else if (cards[playerIndex].HP == 0){
          message = "YOU LOSE !! PRESS N or ENTER";
          isFinished = true;
          isWin = false;
        }
      }
    }
  }
  else if (windowHandler == 3){ // Result Window
    if (isChangedMusic){
      bgm.stop();
      if (isWin){
        winSound.loop();
        title = "GAME CLEAR";
      }
      else { 
        loseSound.loop();
        title = "GAME OVER";
      }
      isChangedMusic = false;
      background(0);
    }
    fill(255);
    textSize(48);
    text(title, (width - textWidth(title)) / 2, height / 2);
    fill(200);
    textSize(18);
    text(guideMessage, (width - textWidth(guideMessage)) / 2, 400);
  }
  else{
    exit();
  }
}

void keyReleased() {
  if (key == 'a') {
    if (!isFinished){
      attackSound.play();
      isAttacking = true;
      turn += 1;
    }
  }
  if (key == 'q'){
    exit();
  }
  if (key == 'n' || keyCode == ENTER){
    windowHandler += 1;
    isChangedMusic = true;
  }
}

// ダイアログで数字を入力するための関数
String showPrompt(String message) {
  return javax.swing.JOptionPane.showInputDialog(message);
}

// ダイアログでメッセージを表示する関数
void showMessage(String message) {
  javax.swing.JOptionPane.showMessageDialog(null, message);
}
