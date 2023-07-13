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

// 初期設定 //
void setup() {
  //ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  camera = new Capture(this, cameras[cameras.length - 1]); // カメラを設定
  camera.start(); // カメラ起動
  
  //ARの設定 //
  markers = new MultiMarker[n_marker];
  for (int i = 0; i < n_marker; i++) {
      markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
      markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }
  
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
  int HP;
  int ATK;
  float scale;
  float angle = 0.0; // 角度
  int height = 0; // 高度
  
  //動きに関するパラメータ //
  float rotate_value = 0.0;
  int updown_value = 0;
  
  Character(String filename) {
    shape = loadShape(filename);
    setParameter(filename);
  }
  
  void setParameter(String filename) {
    if (filename.equals("greenpepper.obj")) { this.name = "GreenPepper"; this.HP = 100; this.ATK = 10; this.scale = 0.2; this.rotate_value = 0.05;}
    else if (filename.equals("apple.obj")) { this.name = "apple"; this.HP = 90; this.ATK = 15; this.scale = 200; this.rotate_value = 0.05;}
    else if (filename.equals("Chicken.obj")) { this.name = "Plane"; this.HP = 150; this.ATK = 30; this.scale = 0.7; this.updown_value = 1; }
    else{this.name = "unknown"; this.HP = 0; this.ATK = 0; this.scale = 0;}
  }
  
  void move() {
    if (this.height < 10) { this.updown_value = abs(this.updown_value);}
    if (this.height > 50) { this.updown_value = -abs(this.updown_value);}
    this.angle += this.rotate_value;
    this.height += this.updown_value;
  }
}

void draw() {
  if(camera.available()) {
    camera.read();
    lights();

    for (int i = 0; i < n_marker; i++) {
      markers[i].detect(camera);
      markers[i].drawBackground(camera);
      
      if (markers[i].isExist(0)) {
        markers[i].beginTransform(0); // マーカー中心を原点に設定

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
