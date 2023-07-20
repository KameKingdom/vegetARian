// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*;

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー
String[] vegetableFiles = {"greenpepper", "apple", "eggplant", "caterpie"}; // 材料のファイル名
String[] recipeFiles = {"greenpepper", "apple", "eggplant"}; // レシピのファイル名
String[] bulletFiles = {"PAN", "POT", "KNIFE", "MICROWAVE"}; // 弾丸のファイル名
char[] keys = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}; // アルファベット

int fps = 30; // 30fps
int frameCounter = 0; // 汎用的なフレームカウンタ

// 辞書型の作成
HashMap<String, Integer> myIngredient;

Character[] cards; // キャラクターカードの配列変数
int n_vegetable = 3; // 野菜カードの数
int n_status = 0; // ステータスカードの数
int n_cards = n_vegetable + n_status; // カードの総数
int n_marker = n_cards; // マーカーの数
int n_kind_vegetables = vegetableFiles.length;

String[] recipe; // レシピ
int n_recipe = recipeFiles.length; // レシピ
int n_max_recipe = 10; // レシピ
int correctRecipeCount = 0;
int incorrectRecipeCount = 0;
int harvestScore = 0;

int index_status = 4; // ステータスカードのインデックス
int windowHandler = 0; // ウィンドウチェンジ
int currentImageIndex = 0; // 対応インデックス
int elapsedCount = 0; // 

Bullet[] bullets; // 弾丸
int n_bullets = 5;
int n_kind_bullets = bulletFiles.length;
int n_keys = keys.length;

float vegetableGenerationProbability = 0.05;
float bulletGenerationProbability = 0.1;

// フレームインデックス //
int FrameOpening = 0;
int FrameHarvest = 1;
int FrameLoading = 2;
int FrameCooking = 3;
int FrameResult = 4;
int FrameExit = 5;
int FrameInstruction1 = 6;
int FrameInstruction2 = 7;

int randomIndex = 0;

// クッキングキーフラグ //
boolean isAlreadyPressed = false;
boolean upKeyPressed = false;
boolean downKeyPressed = false;
int point = 0;
int cookingClearPoint = 100;
char pressedKey = ' ';

int TimeHarvest = 30;
int TimeCooking = 30;

char harvestResult = ' ';
char cookingResult = ' ';

int loadingPosition = 0;
PImage[] ImageTitel; // 画面画像
PImage[] ImageRecipe;
PImage[] ImageInstruction;
PImage ImageSubtitle; // サブタイトル
PImage ImageLoading;
PImage ImageGreenPepper;
PImage ImageApple;
PImage[] ImageCooking;
PImage ImageResult;

// 音源 //
boolean isFrameChanged = true; // 音源変更時フラグ
SoundFile BGMopening; // Opening
SoundFile BGMharvest; // Harvest
SoundFile BGMcooking; // Harvest
SoundFile BGMloading; // Harvest
SoundFile BGMresult; // Harvest
SoundFile BGMget; // Get
SoundFile BGMwrong; // Wrong

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
  for(int i = 0; i < 2; i++){ ImageTitel[i] = loadImage("images/vegetARian" + i + ".png"); }
  ImageSubtitle = loadImage("images/subTitle.png");
  ImageLoading = loadImage("images/nowLoading.png");
  ImageInstruction = new PImage[2];
  for(int i = 0; i < 2; i++){ ImageInstruction[i] = loadImage("images/inst" + i + ".png"); }
  ImageRecipe = new PImage[n_max_recipe];
  for(int i = 0; i < n_max_recipe; i++){ ImageRecipe[i] = loadImage("images/" + recipeFiles[i % n_recipe] + ".png");}
  ImageCooking = new PImage[4];
  for(int i = 0; i < 4; i++){ ImageCooking[i] = loadImage("images/cooking" + i + ".png"); }
  ImageResult = loadImage("images/result.png");

  // 音源のインポート //
  BGMopening = new SoundFile(this, "sound/opening.wav");
  BGMharvest = new SoundFile(this, "sound/harvest.wav");
  BGMcooking = new SoundFile(this, "sound/cooking.wav"); // Harvest
  BGMloading = new SoundFile(this, "sound/loading.wav"); // Harvest
  BGMresult = new SoundFile(this, "sound/result.wav"); // Harvest

  // 効果音のインポート //
  BGMget = new SoundFile(this, "sound/get.wav");
  BGMwrong = new SoundFile(this, "sound/wrong.mp3");

  // 材料のインスタンス作成 //
  cards = new Character[n_cards];
  for (int i = 0; i < n_cards; i++){
    cards[i] = new Character(vegetableFiles[i % n_kind_vegetables]);
  } 

  // レシピの作成 //
  recipe = new String[n_max_recipe];
  for (int i = 0; i < n_max_recipe; i++){
    recipe[i] = recipeFiles[i % n_recipe];
  } 

  // 辞書型の作成
  myIngredient = new HashMap<String, Integer>();
  for(int i = 0; i < vegetableFiles.length; i++){
    myIngredient.put(vegetableFiles[i], 0);
  }

  //弾丸のインスタンス作成 //
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
      if(this.totalFrame == 20){
        if (this.detectedFrame > 18){
          this.startDetection = true;
        }
        else{
          this.startDetection = false;
          this.isVegetableExsit = false;
          this.totalFrame = 0;
          this.detectedFrame = 0;
        }
      }
      if(this.startDetection){
        if(this.totalFrame - this.detectedFrame > 5){
          if(this.name == recipe[correctRecipeCount]){ // 隠されたものがあっていた
            BGMget.play();
            correctRecipeCount++;
          }else{
            BGMwrong.play();
            incorrectRecipeCount++;
          }
          this.isVegetableExsit = false;
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
  int selfPoint;
  char key;
  boolean isCountPoint = false;
  boolean isPressed = false;
  boolean isBulletExist = false;

  Bullet(String name, int x){
    this.name = name;
    this.filename = "images/" + name + ".png";
    this.x = x;
    this.image = loadImage(this.filename);
    this.y = height - this.image.height;
    this.key = keys[(int)(random(0, n_keys))];
    setParameter(this.name);
  }

  void setParameter(String name){
    if(name.equals("PAN")){
      this.speed = 3;
      this.selfPoint = 4;
    }
    else if(name.equals("POT")){
      this.speed = 5;
      this.selfPoint = 6;
    }
    else if(name.equals("MICROWAVE")){
      this.speed = 2;
      this.selfPoint = 2;
    }
    else if(name.equals("KNIFE")){
      this.speed = 10;
      this.selfPoint = 10;
    }
  }

  void move(){
    if(this.isBulletExist){
      this.x -= this.speed;
    }
  }

  void update(){
    if(this.isBulletExist){
      image(this.image, (float)this.x, (float)this.y);
      fill(0);
      textSize(50);
      text(str(this.key).toUpperCase(), this.x + this.image.width / 2 - 20, this.y + this.image.height / 2);
      fill(255);
    }
    if(this.key == pressedKey && this.x < this.image.width && !this.isCountPoint){
      point += this.selfPoint; 
      BGMget.play();
      this.isBulletExist = false;
      this.isCountPoint = true;
    }
    if(this.x < -this.image.width){
      this.isBulletExist = false;
    }
  }
}

/* メイン処理 */
void draw() {
  /* Opening */
  if(windowHandler == FrameOpening){
    // 音源変更
    if(isFrameChanged){
      stopBGM();
      BGMopening.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    // 一定の間隔ごとに画像を切り替える
    if (frameCounter >= 50) {
      currentImageIndex = (currentImageIndex + 1) % 2;
      frameCounter = 0;
    }
    image(ImageTitel[currentImageIndex], 0, 0, width, height);
    frameCounter++;
  }

  else if(windowHandler == FrameInstruction1){
    if (isFrameChanged){
      stopBGM();
      BGMloading.loop();
      isFrameChanged = false;
    }
    image(ImageInstruction[0], 0, 0, width, height);
  }

  /* 収穫ゲーム */
  else if(windowHandler == FrameHarvest){
    // 音源変更
    if (isFrameChanged){
      stopBGM();
      BGMharvest.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    frameCounter++;
    if(frameCounter > fps * TimeHarvest || correctRecipeCount >= n_max_recipe){
      isFrameChanged = true;
      windowHandler = FrameInstruction2;
    }
    harvestScore = (correctRecipeCount - incorrectRecipeCount) * 100;
    image(ImageSubtitle, 0, 0, width, ImageSubtitle.height); // Subtitle
    image(ImageRecipe[correctRecipeCount], width - ImageRecipe[correctRecipeCount].width - 10, 10, ImageRecipe[correctRecipeCount].width / 1.2, ImageRecipe[correctRecipeCount].height / 1.2);
    fill(0);
    textSize(40);
    text(harvestScore, 120, ImageSubtitle.height / 2 - 5);
    text(((TimeHarvest * fps - frameCounter) / fps), 120, ImageSubtitle.height / 2 + 40);
    fill(255);

    // 画像処理 //
    if(camera.available()) {
      camera.read();
      lights();

      for (int i = 0; i < n_marker; i++) {
        markers[i].detect(camera);
        markers[i].drawBackground(camera);
        if(random(1) < vegetableGenerationProbability && !cards[i].isVegetableExsit) {
          cards[i] = new Character(vegetableFiles[frameCounter % n_kind_vegetables]);
          cards[i].isVegetableExsit = true;
        }
        if (markers[i].isExist(0)) {
          markers[i].beginTransform(0); // マーカー中心を原点に設定
          cards[i].detectedFrame += 1;
          if(cards[i].startDetection){
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

  else if(windowHandler == FrameInstruction2){
    if (isFrameChanged){
      stopBGM();
      BGMloading.loop();
      isFrameChanged = false;
    }
    image(ImageInstruction[1], 0, 0, width, height);
  }


  else if(windowHandler == FrameCooking){
    if (isFrameChanged){
      stopBGM();
      BGMcooking.loop();
      isFrameChanged = false;
      frameCounter = 0;
    }
    frameCounter++;
    // 描画 //
    if (elapsedCount >= 50) {
      currentImageIndex = (currentImageIndex + 1) % 4;
      elapsedCount = 0;
    }
    if (frameCounter > TimeCooking * fps){
      windowHandler++;
      isFrameChanged = true;
    }
    image(ImageCooking[currentImageIndex], 0, 0, width, height);
    fill(255);
    text((TimeCooking * fps - frameCounter) / fps, width / 2 - 15, height / 2 + 40);
    ellipse(60, 420, 60, 60);
    rect(0, 0, width, 60);
    fill(255, 0, 0);
    rect(0, 0, width * point / 100, 60);
    elapsedCount++;

    for (int i = 0; i < n_bullets; i++) {
      if (!bullets[i].isBulletExist && random(1) < bulletGenerationProbability) {
        bullets[i] = new Bullet(bulletFiles[frameCounter % n_kind_bullets], width + 100);
        bullets[i].isBulletExist = true;
      }
      bullets[i].move();
      bullets[i].update();
    }
  }

  else if(windowHandler == FrameResult){
    if (isFrameChanged){
      stopBGM();
      BGMresult.loop();
      frameCounter = 0;
      int hr = (int)((double)(correctRecipeCount - incorrectRecipeCount) / n_max_recipe * 100);
      int cr = (int)((double)point / cookingClearPoint * 100);

      if(hr <= 10) harvestResult = 'E';
      else if(hr <= 30) harvestResult = 'D';
      else if(hr <= 50) harvestResult = 'C';
      else if(hr <= 70) harvestResult = 'B';
      else if(hr <= 90) harvestResult = 'A';
      else harvestResult = 'S';

      if(cr <= 50) cookingResult = 'E';
      else if(cr <= 60) cookingResult = 'D';
      else if(cr <= 70) cookingResult = 'C';
      else if(cr <= 80) cookingResult = 'B';
      else if(cr <= 90) cookingResult = 'A';
      else cookingResult = 'S';

      isFrameChanged = false;
    }
    image(ImageResult, 0, 0, width, height);
    textSize(50);
    text(harvestResult, 420, 280);
    text(cookingResult, 420, 370);
  }
  
  else if(windowHandler == FrameExit){
    stopBGM();
    exit();
  }

}

void keyPressed() {
  if (windowHandler == FrameCooking) {
    if (key >= 'a' && key <= 'z') {
      pressedKey = key;
    } else {
      pressedKey = ' ';
    }
  }
}

void stopBGM(){
  BGMcooking.stop();
  BGMharvest.stop();
  BGMloading.stop();
  BGMopening.stop();
  BGMresult.stop();
}

void keyReleased() {
  pressedKey = ' ';
  if ((keyCode == ENTER)){
    if(windowHandler == FrameHarvest){
      windowHandler = FrameInstruction1;
    }else if(windowHandler == FrameInstruction1){
      windowHandler = FrameHarvest;
    }else if(windowHandler == FrameInstruction2){
      windowHandler = FrameCooking;
    }else if(windowHandler == FrameResult){
      windowHandler = FrameExit;
    }else if(windowHandler == FrameOpening){
      windowHandler = FrameInstruction1;
    }
    isFrameChanged = true;
  }
  if(windowHandler == FrameCooking){
    if(key == CODED){
      if(keyCode == UP){
        upKeyPressed = false;
      } else if(keyCode == DOWN){
        downKeyPressed = false;
      }
    }
  }
}

void loading(){
  image(ImageLoading, 0, 0, width, height);
  for(int i = 0; i < n_vegetable; i++){
    image(ImageRecipe[i], loadingPosition + ImageRecipe[i].width * (i + 1), height - ImageRecipe[i].height, ImageRecipe[i].width / 2, ImageRecipe[i].height / 2);
  }
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