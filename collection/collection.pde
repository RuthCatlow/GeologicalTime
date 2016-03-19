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
// String rootDirectory = "/home/gareth/Dropbox/Projects/GEOLOGICALTIME/";
String rootDirectory = "/home/furtherfield/Desktop/GeologicalTime/";
String outputDirectory = rootDirectory+"output/";

int imageIntervalShort = 180;                  // seconds
int imageIntervalLong = 360;                   // seconds
int imageInterval = imageIntervalShort;        // seconds
int overThresholdCount = 0;

int freezeDuration = 3000;                     // milliseconds

int cameraIndex = 16;
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
  // size(1080, 720);
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

  makeDir(outputDirectory+"tmp/");
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
    println("Over threshold:" + overThresholdCount);
  } else {
    overThresholdCount = 0;
  }

  if(overThresholdCount >= 1){
    // imageInterval = imageIntervalLong;
    // println("Increasing image interval: "+ imageInterval);
  } else if(imageInterval > imageIntervalShort) {
    // imageInterval = imageIntervalShort;
    // println("Decreasing image interval: " + imageInterval);
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

  int startHour = 10; int startMin = 0;
  int endHour = 16; int endMin = 0;
  
  int startTime = startHour*60+startMin;
  int endTime = endHour*60+endMin;
  int now = hour()*60+minute(); 
  // println(endTime-now);
  if(now >= endTime){
    drawMessage("GTP done for the day", 0);
    return;
  }
  if(now < startTime){
    if(startTime-now < 60){
      // (minsRemaining-1*60) + (secondsInMinLeft)
      int startCountdownSeconds = ((startTime-now-1)*60) + (60-second());
      drawMessage("GTP starts in", 120);
      drawCountdown(startCountdownSeconds);
    } else {
      drawMessage("GTP starts at 10am", 0);
    }
    return;  
  }
  
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

    // Save image with 'year-date-month' directory and 'hour-min' file.
    String dateDirectory = outputDirectory+"images/" + year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"/";
    latestImage.save(dateDirectory+nf(hour(), 2)+"-"+nf(minute(), 2)+".png");
    // Save image into tmp directory for copying.

    String copyDirectory = outputDirectory+"tmp/";
    if(imagesInDir(copyDirectory) == 0){
      getJson();
      imageCount++;
      latestImage.save(copyDirectory+String.format("out%05d.png", imageCount));
      // startMunge();
    } else {
       println("Skipping");
    }

    // Save most recent time in case of crash.
    log = createWriter(logFilename);
    log.println(mostRecent);
    log.flush();
    log.close();

    delayTime = millis();
  }
}

void startMunge(){
 try {
    Process tr = Runtime.getRuntime().exec(rootDirectory+"munge/munge.sh");
    BufferedReader rd = new BufferedReader( new InputStreamReader( tr.getInputStream() ) );
    String s = rd.readLine();
    println(s);
  }
  catch (IOException e) {
    println(e);
  }
}

void makeDir(String path){
  File theDir = new File(path);
  try{
    theDir.mkdir();
  } catch(SecurityException se){
    println("Could not make directory:"+path);
    println(se);
  }
}

int imagesInDir(String dirPath){
  File theDir = new File(dirPath);
  if(theDir.exists() == false){
    return 0;
  }
  String[] theList = theDir.list();
  int fileCount = theList.length;
  return fileCount;
}