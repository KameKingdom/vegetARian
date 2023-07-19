// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*; 

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー
String[] vegetableFiles = {"greenpepper", "apple", "eggplant", "caterpie"}; // 材料のファイル名
String[] bulletFiles = {"UP", "DOWN"}; // 弾丸のファイル名
int fps = 60; // 60fps
int frameCounter = 0; // 汎用的なフレームカウンタ

// 辞書型の作成
HashMap<String, Integer> myIngredient;

Character[] cards; // キャラクターカードの配列変数
int n_vegetable = 3; // 野菜カードの数
int n_status = 0; // ステータスカードの数
int n_cards = n_vegetable + n_status; // カードの総数
int n_marker = n_cards; // マーカーの数
int n_kind_vegetables = vegetableFiles.length;

int index_status = 4; // ステータスカードのインデックス
int windowHandler = 0; // ウィンドウチェンジ
int currentImageIndex = 0; // 対応インデックス
int elapsedCount = 0; // 

Bullet[] bullets; // 弾丸
int n_bullets = 5;
int n_kind_bullets = bulletFiles.length;

float vegetableGenerationProbability = 0.05;
float bulletGenerationProbability = 0.1;

// フレームインデックス //
int FrameOpening = 0;
int FrameHarvest = 1;
int FrameLoading = 2;
int FrameCooking = 3;
int FrameResult = 4;

// クッキングキーフラグ //
boolean upKeyPressed = false;
boolean downKeyPressed = false;
int point = 0;
int cookingClearPoint = 100;

int TimeHarvest = 30;

int loadingPosition = 100;
PImage[] ImageTitel; // 画面画像
PImage ImageSubtitle; // サブタイトル
PImage ImageLoading;
PImage ImageGreenPepper;
PImage ImageApple;
PImage[] ImageCooking;

// 音源 //
boolean isFrameChanged = true; // 音源変更時フラグ
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
    cards[i] = new Character(vegetableFiles[i % n_kind_vegetables]);
  } 

  // 辞書型の作成
  myIngredient = new HashMap<String, Integer>();
  for(int i = 0; i < vegetableFiles.length; i++){
    myIngredient.put(vegetableFiles[i], 0);
  }

  //弾丸の作成 //
  bullets = new Bullet[n_bullets];
  for (int i = 0; i < n_bullets; i++){
    bullets[i] = new Bullet(bulletFiles[i % n_kind_bullets], width + 100);
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
  
  void setParameter(String filename) {
    if (filename.equals("greenpepper.obj")) {
      this.scale = 0.2;
      this.rotate_value = 0.05;
    } else if (filename.equals("apple.obj")) {
      this.scale = 150;
      this.rotate_value = 0.05;
    } else if (filename.equals("caterpie.obj")) {
      this.scale = 30;
      this.rotate_value = 0.05;
    } else if (filename.equals("eggplant.obj")) {
      this.scale = 20;
      this.rotate_value = 0.05;
      this.height = -10;
    }
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
  PImage image;
  String filename;
  String name;
  int x;
  int y;
  int speed;
  boolean isPressed = false;
  boolean isBulletExist = false;

  Bullet(String name, int x){
    this.name = name;
    this.filename = "images/" + name + ".png";
    this.x = x;
    this.image = loadImage(this.filename);
    this.y = height - this.image.height;
    setParameter(this.name);
  }

  void setParameter(String name){
    if(name.equals("UP")){ this.speed = 3;}
    else if(name.equals("DOWN")){ this.speed = 5;}
  }

  void move(){
    if(this.isBulletExist){
      this.x -= this.speed;
    }
  }

  void update(){
    if(this.isBulletExist == true){
      image(this.image, (float)this.x, (float)this.y);
    }
    if(this.name.equals("UP") && this.x < 100 && upKeyPressed == true){
      point++;
      this.isBulletExist = false;
    }
    else if(this.name.equals("DOWN") && this.x < 100 && downKeyPressed == true){
      point++;
      this.isBulletExist = false;
    }
    if(this.x < -this.image.width){
      this.isBulletExist = false;
    }
  }
}

/* メイン処理 */
void draw() {
  if(windowHandler == FrameOpening){
    // 音源変更
    if(isFrameChanged){
      BGMopening.loop();
      isFrameChanged = false;
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
  else if(windowHandler == FrameHarvest){
    // 音源変更
    if (isFrameChanged){
      BGMopening.stop();
      BGMharvest.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    if(frameCounter > fps * TimeHarvest){
      isFrameChanged = true;
      windowHandler++;
    }
    frameCounter++;
    image(ImageSubtitle, 0, height - ImageSubtitle.height, width, ImageSubtitle.height);
    String message = myIngredient.toString() + "\n" + (TimeHarvest * fps - frameCounter) / fps; // myIngredientの内容を文字列に変換
    fill(0);
    textSize(20);
    text(message, (width - textWidth(message)) / 2, height - ImageSubtitle.height / 2);
    fill(255);

    // 画像処理 //
    if(camera.available()) {
      camera.read();
      lights();

      for (int i = 0; i < n_marker; i++) {
        markers[i].detect(camera);
        markers[i].drawBackground(camera);
        if(random(1) < vegetableGenerationProbability && !cards[i].isVegetableExsit) {
          int randomIndex = (int) random(0, n_kind_vegetables);
          cards[i] = new Character(vegetableFiles[randomIndex]);
          cards[i].isVegetableExsit = true;
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


  else if(windowHandler == FrameLoading){
    // 音源変更
    if (isFrameChanged){
      BGMharvest.stop();
      BGMloading.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    frameCounter++;
    if(frameCounter > fps * 5){
      windowHandler++;
      isFrameChanged = true;
    }
    loading();
  }


  else if(windowHandler == FrameCooking){
    if (isFrameChanged){
      BGMloading.stop();
      BGMcooking.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    // 描画 //
    if (elapsedCount >= 50) {
      currentImageIndex = (currentImageIndex + 1) % ImageCooking.length;
      elapsedCount = 0;
    }
    if (point >= cookingClearPoint){
      windowHandler++;
      isFrameChanged = true;
    }
    image(ImageCooking[currentImageIndex], 0, 0, width, height);
    fill(255);
    ellipse(60, 420, 60, 60);
    rect(0, 0, width, 60);
    fill(255, 0, 0);
    rect(0, 0, width * point / 100, 60);
    elapsedCount++;

    for (int i = 0; i < n_bullets; i++) {
      if (!bullets[i].isBulletExist && random(1) < bulletGenerationProbability) {
        int randomIndex = (int) random(0, n_kind_bullets);
        bullets[i] = new Bullet(bulletFiles[randomIndex], width + 100);
        bullets[i].isBulletExist = true;
      }
      bullets[i].move();
      bullets[i].update();
    }
  }


  else if(windowHandler == FrameResult){
    exit();
  }
}

void keyReleased() {
  /* 変更箇所 */
  if ((key == 'n' || keyCode == ENTER) && (windowHandler == FrameOpening || windowHandler == FrameHarvest)){
    windowHandler++;
    isFrameChanged = true;
  }
  if (keyCode == UP) {
    upKeyPressed = true;
  }
  else if (keyCode == DOWN) {
    downKeyPressed = true;
  }
  else{
    upKeyPressed = false;
    downKeyPressed = false;
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