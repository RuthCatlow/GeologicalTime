import java.io.InputStreamReader;
import java.util.Date;
import processing.video.*;

PrintWriter log;
PrintWriter camLog;
BufferedReader reader;

Capture cam;
String camLogFilename = "cams.txt";
String logFilename = "log.txt";
String outputDirectory = "../output/";
int cameraIndex = 14;
int outputImageWidth = 720;
int delayForMs = 3000;

long mostRecent;
int camScreenHeight = 0;
int camScreenY = 0;
long delayTime = 0;
PImage latestImage;
int imageCount = 0;

void settings() {
  fullScreen();
}

void setup() {
  background(0);
  // size(1280, 720);

  String[] cameras = Capture.list();
  String mostRecentLog;

  File file = new File(logFilename);
  if (file.exists() == true) {
    reader = createReader(logFilename);
    try {
      mostRecentLog = reader.readLine();
    } 
    catch (IOException e) {
      e.printStackTrace();
      mostRecentLog = null;
    }
  }

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    camLog = createWriter(camLogFilename);
    //println("Available cameras:");
    camLog.println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      // println(cameras[i]);
      camLog.println(i + " - " + cameras[i]);
    }
    camLog.flush(); 
    camLog.close();

    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[cameraIndex]);
    cam.start();
  }

  // Extract camera resolution from capture string.
  int q = cameras[cameraIndex].indexOf("size=");
  int r = cameras[cameraIndex].indexOf("x");
  int s = cameras[cameraIndex].indexOf(",fps");
  int camWidth = int(cameras[cameraIndex].substring(q+5, r));
  int camHeight = int(cameras[cameraIndex].substring(r  +1, s));

  float ratio = width/float(camWidth);
  camScreenHeight = round(camHeight*ratio);
  camScreenY = (height - camScreenHeight)/2;

  JSONObject json = loadJSONObject(outputDirectory+"count.json");
  if(json.isNull("count") == false){
    imageCount = json.getInt("count");
  }
  println(0 + " " + camScreenY + " " + width  + " " + camScreenHeight);
}

void draw() {

  // Is camera available
  if (cam.available() == true) {
    cam.read();
  } else {
    return;
  }

  // Clear.
  background(0);

  // Countdown calc.
  Date d = new Date();
  long currentTime = d.getTime()/1000;
  int timeout = 180;
  timeout++; // Add 1 so we can go down to zero.
    
  // Delay after image is saved.
  if (delayTime > 0 && millis() < delayTime + delayForMs) {
    // Render latest save images on screen for delay (freeze frame).   
    image(latestImage, 0, camScreenY, width, camScreenHeight);
    return;
  }    
  
  // Render cam on screen
  image(cam, 0, camScreenY, width, camScreenHeight);

  int countdownSeconds = round(timeout-currentTime%timeout);
  if(countdownSeconds <= 3){
    drawCircle();
    drawLargeCountdown(countdownSeconds);
  } else if(countdownSeconds <= timeout-round(delayForMs/1000)){
    drawCountdown(countdownSeconds);
    drawImageCount(imageCount+1);
  }
    
  // Have we passed the most recent stored time and is this time
  // divisible by {timeout} seconds?
  if (currentTime > mostRecent && currentTime%timeout == 0) {
    // Store this minute so we don't continually take more images.
    mostRecent = currentTime;

    // Resize cam image to desired width. 
    float ratio = camScreenHeight/float(width);
    int outputImageHeight = round(outputImageWidth*(ratio));
    latestImage = createImage(outputImageWidth, outputImageHeight, RGB);
    latestImage.copy(cam, 0, camScreenY, width, camScreenHeight, 0, 0, outputImageWidth, outputImageHeight);

    imageCount++;

    // Save image with 'year-date-month' directory and 'hour-min' file. 
    String dateDirectory = outputDirectory+"images/" + year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"/";
    latestImage.save(dateDirectory+nf(hour(), 2)+"-"+nf(minute(), 2)+".png");
    // Save image into tmp directory for copying.
    String copyDirectory = outputDirectory+"tmp/";
    latestImage.save(copyDirectory+String.format("out%05d.png", imageCount));
  
    // Save most recent time in case of crash.
    log = createWriter(logFilename);
    log.println(mostRecent);
    log.flush(); 
    log.close();

    delayTime = millis();

/*
    try { 
      Process tr = Runtime.getRuntime().exec(sketchPath()+"/../munge/munge.sh");
      BufferedReader rd = new BufferedReader( new InputStreamReader( tr.getInputStream() ) );
      String s = rd.readLine();
      println(s);
    } 
    catch (IOException e) {
      println(e);
    }
    */
  }
}