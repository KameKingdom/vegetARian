// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*; 

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー

Character[] cards; // キャラクターカードの配列変数
int n_vegetable = 4; // 野菜カードの数
int n_status = 1; // ステータスカードの数
int n_cards = 5; // カードの総数
int n_marker = n_cards; // マーカーの数

int index_status = 4; // ステータスカードのインデックス
int windowHandler = 0; // ウィンドウチェンジ
int currentImageIndex = 0; // 対応インデックス
int elapsedCount = 0; // フレームカウンタ
PImage[] images; // 画面画像

// 音源 //
boolean isChangedMusic = true; // 音源変更時フラグ
SoundFile BGMopening; // Opening
SoundFile BGMinstruction; // Instruction
SoundFile BGMharvest; // Harvest

// 初期設定 //
void setup() {
  //ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  print(cameras);
  camera = new Capture(this, cameras[0]); // カメラを設定
  camera.start(); // カメラ起動
  
  //ARの設定 //
  markers = new MultiMarker[n_marker];
  for (int i = 0; i < n_marker; i++) {
      markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
      markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }

  // 画像のインポート //
  images = new PImage[2];
  images[0] = loadImage("vegetARian1.png");
  images[1] = loadImage("vegetARian2.png");

  // 音源のインポート //
  BGMopening = new SoundFile(this, "sound/opening.wav");
  BGMinstruction = new SoundFile(this, "sound/instruction.wav");
  BGMharvest = new SoundFile(this, "sound/bgm.wav");

  //キャラクターの作成 //
  cards = new Character[n_cards];
  cards[0] = new Character("greenpepper.obj");
  cards[1] = new Character("greenpepper.obj");
  cards[2] = new Character("greenpepper.obj");
  cards[3] = new Character("greenpepper.obj");
  cards[4] = null; // ステータスカード
}

// キャラクターのクラス //
class Character {
  PShape shape;
  String name;
  int detectedFrame = 0; // AR検出フレーム
  int totalFrame = 0; // 出現総数フレーム
  int maxFrame = 500; // 出現総数フレーム
  float scale; // ARのスケール
  float angle = 0.0; // 角度
  int height = 0; // 高度

  boolean isVegetableExsit = false; // 自分が存在したフラグ
  boolean isHidden = false; // 隠されたフラグ
  
  //動きに関するパラメータ //
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

  void selfBehavior(int countDetectedFrame){
    /* 自分が存在しない時 */
    if(this.isVegetableExsit == false){
      int probability = int(random(100));
      if(probability == 0){
        this.isVegetableExsit = true;
        this.totalFrame = 0;
        this.detectedFrame = 0;
        this.isHidden = false;
      }
    }
    /* 自分が存在する時 */
    else{
      this.totalFrame += 1;
      this.detectedFrame += countDetectedFrame;
      /* 存在時間終了 */
      if(this.totalFrame > this.maxFrame){
        this.isVegetableExsit = false;
        float probability = this.detectedFrame / this.totalFrame;
        if(probability < 0.4){
          isHidden = false;
        }else if(probability < 0.7){
          isHidden = true;
        }else{
          isHidden = false;
        }
        print("isHidden: " + isHidden);
      }
    }
  }

  void move() {
    if (this.height < 10) { this.updown_value = abs(this.updown_value);}
    if (this.height > 50) { this.updown_value = -abs(this.updown_value);}
    this.angle += this.rotate_value;
    this.height += this.updown_value;
  }
}

void draw() {
  if(windowHandler == 0){
    // 音源変更
    if(isChangedMusic){
      BGMopening.loop();
      isChangedMusic = false;
    }

    // 一定の間隔ごとに画像を切り替える
    if (elapsedCount >= 50) {
      currentImageIndex = (currentImageIndex + 1) % images.length;
      elapsedCount = 0;
    }
    elapsedCount += 1;
    image(images[currentImageIndex], 0, 0, width, height);
  }


  else if(windowHandler == 1){
    // 音源変更
    String guideMessage = "PRESS N OR ENTER to continue...";
    String instructionMessage = "[A]  -  ATTACK \n[N]  -  NEXT WINDOW \n[Q]  -  QUIT \nWhen HP is 0, you lose";
    if (isChangedMusic){
      BGMopening.stop();
      BGMinstruction.loop();
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

  /* 収穫ゲーム */
  else if(windowHandler == 2){
    // 音源変更
    if (isChangedMusic){
      BGMinstruction.stop();
      BGMharvest.loop();
      isChangedMusic = false;
    }

    // 画像処理 //
    if(camera.available()) {
      camera.read();
      lights();

      for (int i = 0; i < n_marker; i++) {
        markers[i].detect(camera);
        markers[i].drawBackground(camera);
        
        if (markers[i].isExist(0)) {
          markers[i].beginTransform(0); // マーカー中心を原点に設定
          cards[i].selfBehavior(1); // カードが存在したとき
          // ステータス確認マーカーが認識されたら、ステータスを表示します。
          if (i == index_status) {
            int textSize = 30;
            pushMatrix();
            translate(-textSize/2, 0, 150);
            textMode(SHAPE);
            textSize(textSize);
            rotateX(- PI / 2);
            fill(255);
            text("test", 0, 0); 
            popMatrix();
          }
          else{
            cards[i].move();
            pushMatrix();
            translate(0, 0, cards[i].height);
            scale(cards[i].scale);
            rotateX(PI / 2);
            rotateY(cards[i].angle);
            shape(cards[i].shape);
            popMatrix();
          }
          fill(255); // 初期化
          markers[i].endTransform(); // マーカー中心を原点に設定
        }
      }
    }
  }
}

void keyReleased() {
  if (key == 'n' || keyCode == ENTER){
    windowHandler += 1;
    isChangedMusic = true;
  }
}