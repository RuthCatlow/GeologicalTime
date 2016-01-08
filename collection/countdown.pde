void countdown(int seconds) {

  if(seconds <= 3){
    drawCircle();
    drawLargeCountdown(seconds);
  } else if(seconds <= 170){
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

void drawCountdown(int seconds) {
  int fontSize = 25;
  PFont openSans;
  openSans = createFont("OpenSans-Bold.ttf", fontSize);
  textFont(openSans, fontSize);

  // println(textAscent());
  fill(255, 255, 255);
  noStroke();
  textAlign(RIGHT, BOTTOM);
  int min = round(seconds/60);
  int sec = round(seconds%60);
  String time =  min + ":" + String.format("%02ds", sec);
  text(time, width-2, height-20);
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