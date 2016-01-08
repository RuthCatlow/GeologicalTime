  import java.io.InputStreamReader;
import java.util.Date;
import processing.video.*;

PrintWriter log;
PrintWriter camLog;
BufferedReader reader;

Capture cam;
String camLogFilename = "cams.txt";
String logFilename = "log.txt";
String outputDirectory = "../output/images/";
int cameraIndex = 14;

long mostRecent;
int camScreenHeight = 0;
int camScreenY = 0;

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
  
  int camWidth = 1280;
  int camHeight = 720;
  float ratio = width/float(camWidth);
  camScreenHeight = round(camHeight*ratio);
  camScreenY = (height - camScreenHeight)/2;
  
  println(0 + " " + camScreenY + " " + width  + " " + camScreenHeight);
}

void draw() {

  // Is camera available
  if (cam.available() == true) {
    cam.read();
  } else {
    return;
  }
  
  // Render on screen
  image(cam, 0, 0, width, camScreenHeight);
  //PImage img = createImage(66, 66, RGB);

  Date d = new Date();
  long currentTime = d.getTime()/1000; // in seconds
  int timeout = 60*1; // x minutes in seconds.

  int countdownSeconds = round(timeout-currentTime%timeout);
  //println(countdownSeconds);
  countdown(countdownSeconds);

  // Have we passed the most recent stored time and is this time
  // divisible by 3 minutes?
  if (currentTime > mostRecent && currentTime%timeout == 0) {
    String directory = year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"/";
    // Store this minute so we don't continually take more images.
    mostRecent = currentTime;
    // Save image with 'year-date-month' directory and 'hour-min' file. 
    saveFrame(outputDirectory+directory+nf(hour(), 2)+"-"+nf(minute(), 2)+".png");
    log = createWriter(logFilename);
    log.println(mostRecent);
    log.flush(); 
    log.close();
    
    try { 
       Process tr = Runtime.getRuntime().exec(sketchPath()+"/../munge/munge.sh");
       BufferedReader rd = new BufferedReader( new InputStreamReader( tr.getInputStream() ) );
       String s = rd.readLine();
       println(s);
     } catch (IOException e) {
       println(e);
     }
  }
}