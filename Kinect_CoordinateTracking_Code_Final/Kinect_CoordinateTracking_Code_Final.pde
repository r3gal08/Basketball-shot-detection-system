/*
 *This sketch follows an average point that is withen the minimum and maximum threshold 
 *specified in the variable below by finding the average "centroid" or "centre" of the 
 *pixels being tracked by the kinect sensor. A postion vector is then created based on
 *this average point and the average z position is found by the kinects capability to
 *preform depth tracking. Useing this average point and serial communication with an 
 *arduino wired to a servo motor opens up the function of following a user fully around 
 *a basketball court by writing the correct angle to the arduinos COM port when a user
 *goes out of frame to the left or right of them so tracking can be continued. Shot data
 *is also read via bluetooth serial communcation from houseing unit #2. Useing this data,
 *and splitting the court into 3 seperate sections, this sketch is able to determine what
 *average position a user is on the court aswell as determining whether a made or missed
 *field goal has occured from that position. Data is also printed to an excel data file
 *so users can keep track of their scores and try to improve their game!
 */

import org.openkinect.freenect.*;   // Open kinect processing libraries created by Daniel Shiffman
import org.openkinect.processing.*; // " "
import processing.serial.*;         // Serial communication processing library

// Library specific objects
Table HeatMap;
Kinect kinect;  
Serial BTPort; 
Serial UNOPort;
            
PImage img;  // Creates an image variable for the raw kinect image  
PImage dimg; // Image variable for the raw kinect depth image 

float minThresh; // Min camera threshold
float maxThresh; // Max camera threshold

int FG;          // Variable that store read bluetooth data
int Section = 2; // Variable to store the servo angle in

// Variables for court section 1A
int FGShotA2 = 0;
int FGMakeA2 = 0;
int FGShotA3 = 0;
int FGMakeA3 = 0;

// Variables for court section 1B
int FGShotB2 = 0;
int FGMakeB2 = 0;
int FGShotB3 = 0;
int FGMakeB3 = 0;

// Variables for court section 2Ca 
int FGShotCa2 = 0;
int FGMakeCa2 = 0;
int FGShotCa3 = 0;
int FGMakeCa3 = 0;

// Variables for court section 2Cb
int FGShotCb2 = 0;
int FGMakeCb2 = 0;
int FGShotCb3 = 0;
int FGMakeCb3 = 0;

// Variables for court section 3D
int FGShotD2 = 0;
int FGMakeD2 = 0;
int FGShotD3 = 0;
int FGMakeD3 = 0;

// Variables for court section 3E
int FGShotE2 = 0;
int FGMakeE2 = 0;
int FGShotE3 = 0;
int FGMakeE3 = 0;

void setup() {
  size(640, 480);
  printArray(Serial.list());           // Prints active serial ports 
  String portName1 = Serial.list()[1]; // Grabs active serial port for COM4 (Arduino UNO)
  String portName2 = Serial.list()[2]; // Grabs active serial port for COM18 (Bluetooth module)
  
  // Iitalizeing objects
  kinect = new Kinect(this);
  UNOPort = new Serial(this, portName1, 9600);
  BTPort = new Serial(this, portName2, 9600);

  kinect.initDepth();       // Initalizes kinect depth tracking 
  kinect.activateDevice(0); // Activates kinect camera

  img = createImage(kinect.width, kinect.height, RGB); // Creates blank image. Parameters: (width in pixels, height in pixels, format)
  
  HeatMap = new Table();
  HeatMap.addColumn("A2");
  HeatMap.addColumn("A3");
  HeatMap.addColumn("B2");
  HeatMap.addColumn("B3");
  HeatMap.addColumn("Ca2");
  HeatMap.addColumn("Ca3");
  HeatMap.addColumn("Cb2");
  HeatMap.addColumn("Cb3");
  HeatMap.addColumn("D2");
  HeatMap.addColumn("D3");
  HeatMap.addColumn("E2");
  HeatMap.addColumn("E3");
  
  // Options
  kinect.enableColorDepth(false); // Enables or disables color depth
  kinect.setTilt(10);             // Set the angle of the kinect
  minThresh = 300;                // Set min camera threshold
  maxThresh = 500;                // Set max camera threshold
}

void draw() {
  background(0);
  img.loadPixels(); // Loads kinect img pixel data

  int[] depth = kinect.getRawDepth(); // Begins the raw depth data analysis
  dimg = kinect.getDepthImage();
  
  // Variables used for finding the average centroid/position vector
  float sumX = 0;
  float sumY = 0;
  float avgZ = 2048;
  float totalPixels = 0;

  // Function loop that calculates the raw depth data and sum of x and y pixels. As well as color codeing the depth threshold 
  for (int x = 0; x < kinect.width; x++) {
    for (int y = 0; y < kinect.height; y++) {
      int offset =  x + y*kinect.width; // grabs the raw depth data from the integer array "depth"
      int d = depth[offset]; 
      
      if (d > minThresh && d < maxThresh) {
        img.pixels[offset] = color(255, 0, 0); // Changes the colors of the "offset" or "depth" pixels that are in range of the max and min threshold to the color red
        
        // Loop that finds the average Z coordinate
        if (d < avgZ) {
          avgZ = d; 
        }
        sumX += x;     // Summing all the x pixels
        sumY += y;     // Summing all the y pixels
        totalPixels++; // Summing all the x and y pixels
      } else {
        img.pixels[offset] = dimg.pixels[offset]; // Shows depth image outside of "color zone". use the color(); function to disable depth image
      }
    }
  }
  img.updatePixels(); // Updates the images pixels if any changes has occured in the code (needed when useing the function .loadPixels
  image(img, 0, 0);   // Displays image

  float avgX = sumX/totalPixels; // Finding the average x coordinate
  float avgY = sumY/totalPixels; // Finding the average y coordinate
  fill(150, 0, 255);             // "Fills" the objects color on an RGB scale 
  ellipse(avgX, avgY, 64, 64);   // Draws an ellipse at the position of the average x and y coordinate

  fill(255); 
  textSize(32);
  text("<" + avgX + ", " + avgY + ", " + avgZ + ">", 10, 64); // Prints the average position vector to the display window

  // ****** end of coordinate tracking code ****** //

  // Checking for houseing unit 2 data 
  if ( BTPort.available() > 0) { 
    FG = BTPort.read(); // read it and store it in FG variable 
  } else {
    FG = 3;
  }
  
  // 
  switch (Section) {
    // Kinect is in Section 2
    case (2):
    UNOPort.write('2');
      // If user goes out of frame to the left of them
      if (avgX > 620) {
        UNOPort.write('3'); // Sends data to arduino to rotate the servo to angle 45 degrees to section 3
        Section = 3;        // Sets angle variable to 3 (for case statement)
        println("Moving to section 3");
        delay(2500);
      } 
      // If user goes out of frame to the right of them
      else if ( avgX < 10) {
        UNOPort.write('1');
        Section = 1;
        println("Moving to section 1");
        delay(2500);
      }
      // If user is in section Ca2 
      else if (avgX > 10 && avgX < 310 && avgZ < 1200) {
        if (FG == 1){
          FGShotCa2++;
          FGMakeCa2++;
          println("made shot Ca2");
        } else if (FG == 0) {
          FGShotCa2++;
          println("missed shot Ca2");
        }
      }
      // If user is in section Ca3
      else if (avgX > 10 && avgX < 310 && avgZ > 1200) {
        if (FG == 1){
          FGShotCa3++;
          FGMakeCa3++;
          println("made shot Ca3");
        } else if (FG == 0) {
          FGShotCa3++;
          println("missed shot Ca3");
        }
      }
      // If user is in section Cb2
      else if (avgX > 310 && avgX < 620 && avgZ < 1200) {
        if (FG == 1){
          FGShotCb2++;
          FGMakeCb2++;
          println("made shot Cb2");
        } else if (FG == 0) {
          FGShotCb2++;
          println("missed shot Cb2");
        }
      }
      // If user is in section Cb3
      else if (avgX > 310 && avgX < 620 && avgZ > 1200) {
        if (FG == 1){
          FGShotCb3++;
          FGMakeCb3++;
          println("made shot Cb3");
        } else if (FG == 0) {
          FGShotCb3++;
          println("missed shot Cb3");
        }
      }
      break;
 
   // Kinect is in Section 1
    case (1):
    UNOPort.write('1');
      if (avgX > 620) {
        UNOPort.write('2');
        Section = 2;
        println("Moving to section 2");
        delay(2500);
      }        
      // If user is in section A2 
      else if (avgX > 10 && avgX < 310 && avgZ < 1200) {
        if (FG == 1){
          FGShotA2++;
          FGMakeA2++;
          println("made shot A2");
        } else if (FG == 0) {
          FGShotA2++;
          println("missed shot A2");
        }
      }
      // If user is in section A3
      else if (avgX > 10 && avgX < 310 && avgZ > 1200) {
        if (FG == 1){
          FGShotA3++;
          FGMakeA3++;
          println("made shot A3");
        } else if (FG == 0) {
          FGShotA3++;
          println("missed shot A3");
        }
      }
      // If user is in section B2
      else if (avgX > 310 && avgX < 620 && avgZ < 1200) {
        if (FG == 1){
          FGShotB2++;
          FGMakeB2++;
          println("made shot B2");
        } else if (FG == 0) {
          FGShotB2++;
          println("missed shot B2");
        }
      }
      // If user is in section B3
      else if (avgX > 310 && avgX < 620 && avgZ > 1200) {
        if (FG == 1){
          FGShotA3++;
          FGMakeA3++;
          println("made shot B3");
        } else if (FG == 0) {
          FGShotA3++;
          println("missed shot B3");
        }
      }
      break;
    
    // Kinect is in Section 3
    case (3):
    UNOPort.write('3');
      if (avgX < 10) {
        UNOPort.write('2');
        Section = 2;
        println("Moving to section 2");
        delay(2500);
      }
      // If user is in section E2 
      else if (avgX > 310 && avgX < 620 && avgZ < 1200) {
        if (FG == 1){
          FGShotE2++;
          FGMakeE2++;
          println("made shot E2");
        } else if (FG == 0) {
          FGShotE2++;
          println("missed shot E2");
        }
      }
      // If user is in section E3
      else if (avgX > 310 && avgX < 620 && avgZ > 1200) {
        if (FG == 1){
          FGShotE3++;
          FGMakeE3++;
          println("made shot E3");
        } else if (FG == 0) {
          FGShotE3++;
          println("missed shot E3");
        }
      }
      // If user is in section D2
      else if (avgX > 10 && avgX < 310 && avgZ < 1200) {
        if (FG == 1){
          FGShotD2++;
          FGMakeD2++;
          println("made shot D2");
        } else if (FG == 0) {
          FGShotD2++;
          println("missed shot D2");
        }
      }
      // If user is in section D3
      else if (avgX > 10 && avgX < 310 && avgZ > 1200) {
        if (FG == 1){
          FGShotD3++;
          FGMakeD3++;
          println("made shot D3");
        } else if (FG == 0) {
          FGShotD3++;
          println("missed shot D3");
        }
      }

    default:
    break;
  }
  
  // Printing heat map data to excel file "HeatMap.csv
  HeatMap.addRow();                                       // Creates an empty row
  HeatMap.setString(0, "A2",  FGMakeA2 + "|" + FGShotA2); // prints data to excel file parameters: (row, column, value, columnName) 
  HeatMap.setString(0, "A3",  FGMakeA3 + "|" + FGShotA3);
  HeatMap.setString(0, "B2",  FGMakeB2 + "|" + FGShotB2);
  HeatMap.setString(0, "B3",  FGMakeB3 + "|" + FGShotB3);
  HeatMap.setString(0, "Ca2",  FGMakeCa2 + "|" + FGShotCa2);
  HeatMap.setString(0, "Ca3",  FGMakeCa3 + "|" + FGShotCa3);
  HeatMap.setString(0, "Cb2",  FGMakeCb2 + "|" + FGShotCb2);
  HeatMap.setString(0, "Cb3",  FGMakeCb3 + "|" + FGShotCb3);
  HeatMap.setString(0, "D2",  FGMakeD2 + "|" + FGShotD2);
  HeatMap.setString(0, "D3",  FGMakeD3 + "|" + FGShotD3);
  HeatMap.setString(0, "E2",  FGMakeE2 + "|" + FGShotE2);
  HeatMap.setString(0, "E3",  FGMakeE3 + "|" + FGShotE3);
  saveTable(HeatMap, "data/HeatMap.csv");
}

void keyPressed() {
  saveTable(HeatMap, "data/HeatMap.csv");
  exit();
}