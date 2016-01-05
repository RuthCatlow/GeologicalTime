import java.util.Date;
import processing.video.*;

PrintWriter log;
BufferedReader reader;

Capture cam;
String logFilename = "log.txt";

long mostRecent;

void setup() {
  size(640, 480);

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
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }

    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
}

void draw() {

  // Is camera available
  if (cam.available() == true) {
    cam.read();
  } else {
    return;
  }
  // Render on screen
  image(cam, 0, 0);

  Date d = new Date();
  long currentTime = d.getTime()/1000; // in seconds
  int timeout = 60*3; // x minutes in seconds.

  // println(currentTime);
  // println(timeout);

  int countdownSeconds = round(timeout-currentTime%timeout);
  //println(countdownSeconds);
  countdown(countdownSeconds);

  // Have we passed the most recent stored time and is this time
  // divisible by 3 minutes?
  if (currentTime > mostRecent && currentTime%timeout == 0) {
    // Store this minute so we don't continually take more images.
    mostRecent = currentTime;
    // Save image with 'year-date-month' directory and 'hour-min' file. 
    saveFrame(year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"/"+nf(hour(), 2)+"-"+nf(minute(), 2)+".png");
    log = createWriter("log.txt");
    log.println(mostRecent);
    log.flush(); 
    log.close();
  }
}