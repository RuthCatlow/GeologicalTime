import java.io.InputStreamReader;
import java.io.File;
import java.util.Date;
import processing.video.*;

PrintWriter log;
PrintWriter camLog;
BufferedReader reader;

Capture cam;
String camLogFilename = "cams.txt";
String logFilename = "log.txt";
String rootDirectory = "/home/furtherfield/Desktop/GeologicalTime/";
String outputDirectory = rootDirectory+"output/";

int imageIntervalShort = 10;                  // seconds
int imageIntervalLong = 360;                   // seconds
int imageInterval = imageIntervalShort;        // seconds
int overThresholdCount = 0;

int freezeDuration = 3000;                     // milliseconds

int cameraIndex = 6;
int outputImageWidth = 720;

long mostRecent;
int camScreenHeight = 0;
int camScreenY = 0;
long delayTime = 0;
PImage latestImage;
int imageCount = 0;
int encodingTime = 0;

void settings() {
	fullScreen();
}

void setup() {
  background(0);
  
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
  
  getJson();
  
  // println(0 + " " + camScreenY + " " + width  + " " + camScreenHeight);
}

void getJson(){
  JSONObject json = null;
  File jsonFile = new File(outputDirectory+"count.json");
  if(jsonFile.exists() == true){
    json = loadJSONObject(outputDirectory+"count.json");
  }
  
  if(json == null){
    imageCount = 0;
    encodingTime = 0;
  } else {
    imageCount = json.getInt("count");
    encodingTime = json.getInt("time");
  }
  
  // Check encoding isn't getting too close to our
  // interval time.
  if(encodingTime > round(imageIntervalShort*0.8)){
    overThresholdCount++;
  }
   //<>//
  if(overThresholdCount > 5){
    imageInterval = imageIntervalLong;
  }
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
  int timeout = imageInterval;
  timeout++; // Add 1 so we can go down to zero.
    
  // Delay after image is saved.
  if (delayTime > 0 && millis() < delayTime + freezeDuration) {
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
  } else if(countdownSeconds <= timeout-round(freezeDuration/1000)){
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

    try { 
      Process tr = Runtime.getRuntime().exec(rootDirectory+"/munge/munge.sh");
      BufferedReader rd = new BufferedReader( new InputStreamReader( tr.getInputStream() ) );
      String s = rd.readLine();
      println(s);
    } 
    catch (IOException e) {
      println(e);
    }
  }
}