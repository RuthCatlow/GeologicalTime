void countdown(int seconds, int timeout, int pauseMs) {

  if(seconds <= 3){
    drawCircle();
    drawLargeCountdown(seconds);
  } else if(seconds <= timeout-round(pauseMs/1000)){
    drawCountdown(seconds);
  }
  
}

void drawCircle() {
  int h = round(height*0.8);
  int w = h;
  int y = height/2;
  int x = width/2;
  noStroke();
  fill(color(65, 200));
  ellipse(x, y, w, h);
}

void smallText(boolean bold){
   int fontSize = 25;
  PFont openSans;
  if(bold == true){
    openSans = createFont("OpenSans-Bold.ttf", fontSize);
  } else {
   openSans = createFont("OpenSans-Semibold.ttf", fontSize);
  }
  textFont(openSans, fontSize);

  fill(255, 255, 255);
  noStroke();
}

void drawImageCount(int imageCount) {
  smallText(false);
  textAlign(RIGHT, BOTTOM);
  text(String.format("image [%05d] in ", imageCount), width-80, height-40);
}

void drawCountdown(int seconds) {
  smallText(true);
  textAlign(RIGHT, BOTTOM);
  int min = round(seconds/60);
  int sec = round(seconds%60);
  String time =  String.format("%02d", min) + ":" + String.format("%02ds", sec);
  text(time, width-2, height-40);
}

void drawLargeCountdown(int seconds) {
  float base = height * 0.5;
  // stroke(255);
  // line(0, base, width, base);

  int fontSize = 500;
  PFont openSans;
  openSans = createFont("OpenSans-Bold.ttf", fontSize);
  textFont(openSans, fontSize);

  // println(textAscent());
  fill(255, 255, 255);
  noStroke();
  textAlign(CENTER, CENTER);
  text(seconds, width/2, base-(textDescent()*0.55));
}