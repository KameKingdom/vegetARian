// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*; 

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー
String[] vegetableFiles = {"greenpepper", "apple", "eggplant", "caterpie"}; // 材料のファイル名
int fps = 60; // 60fps
int frameCounter = 0; // 汎用的なフレームカウンタ

// 辞書型の作成
HashMap<String, Integer> myIngredient;

Character[] cards; // キャラクターカードの配列変数
int n_vegetable = 3; // 野菜カードの数
int n_status = 0; // ステータスカードの数
int n_cards = n_vegetable + n_status; // カードの総数
int n_marker = n_cards; // マーカーの数

int index_status = 4; // ステータスカードのインデックス
int windowHandler = 0; // ウィンドウチェンジ
int currentImageIndex = 0; // 対応インデックス
int elapsedCount = 0; // 

int TimeHarvest = 30;

int loadingPosition = 100;
PImage[] ImageTitel; // 画面画像
PImage ImageSubtitle; // サブタイトル
PImage ImageLoading;
PImage ImageGreenPepper;
PImage ImageApple;
PImage[] ImageCooking;

// 音源 //
boolean isChangedMusic = true; // 音源変更時フラグ
SoundFile BGMopening; // Opening
SoundFile BGMharvest; // Harvest
SoundFile BGMcooking; // Harvest
SoundFile BGMloading; // Harvest
SoundFile BGMresult; // Harvest
SoundFile BGMget; // Get

// 初期設定 //
void setup() {
  //ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  print(cameras);
  camera = new Capture(this, cameras[0]); // カメラを設定
  camera.start(); // カメラ起動
  frameRate(fps); // 60fps
  
  //ARの設定 //
  markers = new MultiMarker[n_cards];
  for (int i = 0; i < n_cards; i++) {
      markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
      markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }

  // 画像のインポート //
  ImageTitel = new PImage[2];
  ImageTitel[0] = loadImage("images/vegetARian1.png");
  ImageTitel[1] = loadImage("images/vegetARian2.png");
  ImageSubtitle = loadImage("images/subTitle.png");
  ImageLoading = loadImage("images/nowLoading.png");
  ImageGreenPepper = loadImage("images/greenpepper.png");
  ImageApple = loadImage("images/apple.png");
  ImageCooking = new PImage[4];
  ImageCooking[0] = loadImage("images/cooking1.png");
  ImageCooking[1] = loadImage("images/cooking2.png");
  ImageCooking[2] = loadImage("images/cooking1.png");
  ImageCooking[3] = loadImage("images/cooking3.png");

  // 音源のインポート //
  BGMopening = new SoundFile(this, "sound/opening.wav");
  BGMharvest = new SoundFile(this, "sound/harvest.wav");
  BGMcooking = new SoundFile(this, "sound/cooking.wav"); // Harvest
  BGMloading = new SoundFile(this, "sound/loading.wav"); // Harvest
  BGMresult = new SoundFile(this, "sound/result.wav"); // Harvest

  // 効果音のインポート //
  BGMget = new SoundFile(this, "sound/get.wav");

  //キャラクターの作成 //
  cards = new Character[n_cards];
  for (int i = 0; i < n_cards; i++){
    cards[i] = new Character("greenpepper.obj");
  } 

  // 辞書型の作成
  myIngredient = new HashMap<String, Integer>();
  for(int i = 0; i < vegetableFiles.length; i++){
    myIngredient.put(vegetableFiles[i], 0);
  }
}


// キャラクターのクラス //
class Character {
  PShape shape;
  String name;
  int detectedFrame = 0; // AR検出フレーム
  int totalFrame = 0; // 出現総数フレーム
  int maxFrame = fps * 2; // 出現総数フレーム
  float scale; // ARのスケール
  float angle = 0.0; // 角度
  int height = 0; // 高度

  boolean isVegetableExsit = false; // 自分が存在したフラグ
  boolean isHidden = false; // 隠されたフラグ
  boolean startDetection = false; // 検出を可能にするか
  
  //動きに関するパラメータ //
  float rotate_value = 0.0;
  int updown_value = 0;
  
  Character(String filename) {
    this.name = filename;
    filename = filename + ".obj";
    shape = loadShape(filename);
    setParameter(filename);
  }
  
  void setParameter(String filename){
    if(filename.equals("greenpepper.obj")){ this.scale = 0.2; this.rotate_value = 0.05;}
    else if(filename.equals("apple.obj")){ this.scale = 150; this.rotate_value = 0.05;}
    else if(filename.equals("caterpie.obj")){ this.scale = 30; this.rotate_value = 0.05;}
    else if(filename.equals("eggplant.obj")){ this.scale = 20; this.rotate_value = 0.05; this.height = -10;}
  }

  void update(){
    /* キャラクター生成 */
    if(!this.isVegetableExsit && random(1) <= 0.01){
      this.isVegetableExsit = true;
      this.totalFrame = 0;
      this.detectedFrame = 0;
      this.startDetection = false;
    }
    /* 自分が存在する時 */
    if(this.isVegetableExsit){
      this.totalFrame += 1;
      if(this.totalFrame == 10){
        if (this.detectedFrame > 8) this.startDetection = true;
        else{
          this.isVegetableExsit = false;
          this.totalFrame = 0;
          this.detectedFrame = 0;
        }
      }
      if(this.startDetection){
        if(this.totalFrame - this.detectedFrame > 10){
          isHidden = true;
          BGMget.play();
          this.isVegetableExsit = false;
          int count = myIngredient.get(this.name);
          count ++;
          myIngredient.put(this.name, count);
        }
      }
      /* 存在時間終了 */
      if(this.totalFrame > this.maxFrame){
        this.isVegetableExsit = false;
        this.totalFrame = 0;
        this.detectedFrame = 0;
      }
    }
  }

  void move() {
    if (this.height < 10) { this.updown_value = abs(this.updown_value);}
    if (this.height > 50) { this.updown_value = -abs(this.updown_value);}
    this.angle += this.rotate_value;
    this.height += this.updown_value;
  }
} /* キャラクタークラス終了 */


/* 弾丸クラス */
class Bullet{
  String name;
  int x, y;
  char k; 
  color c;
  int speed;

  Bullet(String name, int x, int y, int speed, char k, color c){
    this.name = name;
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.k = k;
    this.c = c;
  }

  void move(){
    this.x += this.speed;
  }

  void update(){
    print("");
  }
}

/* メイン処理 */
void draw() {
  if(windowHandler == 0){
    // 音源変更
    if(isChangedMusic){
      BGMopening.loop();
      isChangedMusic = false;
      frameCounter = 0;
    }

    // 一定の間隔ごとに画像を切り替える
    if (frameCounter >= 50) {
      currentImageIndex = (currentImageIndex + 1) % ImageTitel.length;
      frameCounter = 0;
    }
    image(ImageTitel[currentImageIndex], 0, 0, width, height);
    frameCounter++;
  }


  /* 収穫ゲーム */
  else if(windowHandler == 1){
    // 音源変更
    if (isChangedMusic){
      BGMopening.stop();
      BGMharvest.loop();
      isChangedMusic = false;
      frameCounter = 0;
    }
    if(frameCounter > fps * TimeHarvest){
      isChangedMusic = true;
      windowHandler++;
    }
    frameCounter++;
    image(ImageSubtitle, 0, height - ImageSubtitle.height, width, ImageSubtitle.height);
    String message = myIngredient.toString() + "\n" + (TimeHarvest * fps - frameCounter) / fps; // myIngredientの内容を文字列に変換
    fill(0);textSize(20);
    text(message, (width - textWidth(message)) / 2, height - ImageSubtitle.height / 2);
    fill(255);

    // 画像処理 //
    if(camera.available()) {
      camera.read();
      lights();

      for (int i = 0; i < n_marker; i++) {
        markers[i].detect(camera);
        markers[i].drawBackground(camera);
        if (random(1) < 0.05 && !cards[i].isVegetableExsit) {
          int randomIndex = (int) random(0, n_cards);
          cards[i] = new Character(vegetableFiles[randomIndex]);
        }
        if (markers[i].isExist(0)) {
          markers[i].beginTransform(0); // マーカー中心を原点に設定
          cards[i].detectedFrame += 1;
          if(cards[i].startDetection == true){
            cards[i].move();
            pushMatrix();
            translate(0, 0, cards[i].height);
            scale(cards[i].scale);
            rotateX(PI / 2);
            rotateY(cards[i].angle);
            shape(cards[i].shape);
            popMatrix();
            fill(255); // 初期化
          }
          markers[i].endTransform(); // マーカー中心を原点に設定
        }
        cards[i].update();
      }
    }
  }


  else if(windowHandler == 2){
    // 音源変更
    if (isChangedMusic){
      BGMharvest.stop();
      BGMloading.loop();
      isChangedMusic = false;
      frameCounter = 0;
    }
    frameCounter++;
    if(frameCounter > fps * 5){
      windowHandler++;
      isChangedMusic = true;
    }
    loading();
  }


  else if(windowHandler == 3){
    if (isChangedMusic){
      BGMloading.stop();
      BGMcooking.loop();
      isChangedMusic = false;
      frameCounter = 0;
    }
    // 一定の間隔ごとに画像を切り替える
    if (elapsedCount >= 50) {
      currentImageIndex = (currentImageIndex + 1) % ImageCooking.length;
      elapsedCount = 0;
    }
    elapsedCount += 1;
    image(ImageCooking[currentImageIndex], 0, 0, width, height);
  }


  else if(windowHandler == 4){
    exit();
  }
}

void keyReleased() {
  if (key == 'n' || keyCode == ENTER){
    windowHandler++;
    isChangedMusic = true;
  }
}

void loading(){
  image(ImageLoading, 0, 0, width, height);
  image(ImageGreenPepper, loadingPosition, height - ImageGreenPepper.height);
  image(ImageApple, loadingPosition + ImageGreenPepper.width * 2, height - ImageApple.height);
  loadingPosition += 5;
  if(loadingPosition > width * 2) loadingPosition = -width;
}

void mouseClicked() {
  // クリックした位置の座標を取得
  int x = mouseX;
  int y = mouseY;
  
  // 取得した座標を表示
  println("クリック位置の座標: (" + x + ", " + y + ")");
}