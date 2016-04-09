/*
 *Created: January 2016 - April 2016
 *Modified: 7 April 2016
 *Author: Brett Leard <126114>
 *----------------------------------------------------------------------------------------*
 *This sketch follows an average point that is withen the minimum and maximum threshold 
 *specified in the variable below by finding the average "centroid" or "centre" of the 
 *pixels being tracked by the kinect sensor. A postion vector is then created based on
 *this average point and the average z position is found by the kinects capability to
 *preform depth tracking. Useing this average point and serial communication with an 
 *arduino wired to a servo motor opens up the function of following a user fully around 
 *a basketball court by writing the correct angle to the arduinos COM port when a user
 *goes out of frame to the left or right of them so tracking can be continued. Shot data
 *is also read via bluetooth serial communcation from unit #2. Useing this data, and 
 *splitting the court into 3 seperate sections, this sketch is able to determine what
 *average position a user is on the court as well as determining whether a made or missed 
 *field goal has occured from that position. Data is also printed to an excel data file  
 *so users can keep track of their scores and try to improve their game!                 
 *----------------------------------------------------------------------------------------*
 *Update March 22 2016: added to the "checking unit #2" function to accommodate the newly 
 *added ATtiny85 IC chip. Data from the Bluetooth module when connected to the ATtiny85 
 *comes in as 128 for '0' and 129 for '1', so I simply added a function that sets the
 *FG variable  equal to '0' when the serial data is 128 amd '1' when the serial data is 
 *129.
 *Update March 24 2016: Added in sound effects from the popular arcade game "NBA Jam".
 *Update March 31 2016: Changed the 3-Point z value to be any point that is greatet than
 *1030 due to some recent testing in the Acadia gym.
 *Update March 31 2016 (Version 7): Added in a function for displaying a real time heat
 *map. By pressing, and holding, the 'ENTER' key a heatmap will be displayed includeing 
 *the user's made and attempted shots, along with a percentage of shots made from each
 *section.
 */

import org.openkinect.freenect.*;   // Open kinect processing libraries created by Daniel Shiffman
import org.openkinect.processing.*; // " "
import processing.serial.*;         // Serial communication processing library
import ddf.minim.*;                 // Audio processing library

// Library specific objects
Table HeatMap;
Kinect kinect;  
Serial BTPort; 
Serial UNOPort;
Minim minim;

PImage img;  // Creates an image variable for the raw kinect image  
PImage dimg; // Image variable for the raw kinect depth image 
PImage himg; // Image variable for the 'real time' heat map 

float minThresh; // Min camera threshold
float maxThresh; // Max camera threshold

int FG;          // Variable that store read bluetooth data
int Section = 2; // Variable to store the servo angle in

// Variables for court section 1A
float FGShotA2 = 0;
float FGMakeA2 = 0;
float FGShotA3 = 0;
float FGMakeA3 = 0;

// Variables for court section 1B
float FGShotB2 = 0;
float FGMakeB2 = 0;
float FGShotB3 = 0;
float FGMakeB3 = 0;

// Variables for court section 2Ca 
float FGShotCa2 = 0;
float FGMakeCa2 = 0;
float FGShotCa3 = 0;
float FGMakeCa3 = 0;

// Variables for court section 2Cb
float FGShotCb2 = 0;
float FGMakeCb2 = 0;
float FGShotCb3 = 0;
float FGMakeCb3 = 0;

// Variables for court section 3D
float FGShotD2 = 0;
float FGMakeD2 = 0;
float FGShotD3 = 0;
float FGMakeD3 = 0;

// Variables for court section 3E
float FGShotE2 = 0;
float FGMakeE2 = 0;
float FGShotE3 = 0;
float FGMakeE3 = 0;

AudioPlayer[] SE; // Array used to store soundeffect files in
int r;            // Random number variable

void setup() {
  size(640, 480);
  
  printArray(Serial.list());           // Prints active serial ports 
  String portName1 = Serial.list()[1]; // Grabs active serial port for COM4A rduino UNO
  String portName2 = Serial.list()[2]; // Grabs active serial port for Bluetooth module

  // Iitalizeing objects
  kinect = new Kinect(this);
  UNOPort = new Serial(this, portName1, 9800);
  BTPort = new Serial(this, portName2, 9800);

  minim = new Minim(this);

  kinect.initDepth();       // Initalizes kinect depth tracking 
  kinect.activateDevice(5); // Activates kinect camera

  img = createImage(kinect.width, kinect.height, RGB); // Creates blank image. Parameters: (width in pixels, height in pixels, format)
  himg = loadImage("HeatMapCoordinates.png");

  // Creating excel table
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

  // Loading soundeffect files
  SE = new AudioPlayer[8];
  SE[0] = minim.loadFile("boomshakalaka1.mp3");
  SE[1] = minim.loadFile("boomshakalaka2.mp3");
  SE[2] = minim.loadFile("FromDowntown.mp3");
  SE[3] = minim.loadFile("HeatingUp.mp3");
  SE[4] = minim.loadFile("Kaboom.mp3");
  SE[5] = minim.loadFile("OnFire.mp3");
  SE[6] = minim.loadFile("TheShoes.mp3");
  SE[7] = minim.loadFile("ToFastToBig.mp3"); 

  // Options
  kinect.enableColorDepth(false); // Enables or disables color depth
  kinect.setTilt(0);              // Set the angle of the kinect
  minThresh = 300;                // Set min camera threshold
  maxThresh = 1050;               // Set max camera threshold (1050 is optimal in acadia sized gym)
  delay(5000);
}

void draw() {
  background(0);
  img.loadPixels(); // Loads kinect img pixel data

  int[] depth = kinect.getRawDepth(); // Begins the raw depth data analysis
  dimg = kinect.getDepthImage();

  // Variables used for finding the average centroid/position vector
  float sumX = 0;
  float sumY = 0;
  float avgZ = 2030;
  float totalPixels = 0;

  // Function loop that calculates the raw depth data and sum of x and y pixels. As well as color codeing the depth threshold 
  for (int x = 0; x < kinect.width; x++) {
    for (int y = 0; y < 300; y++) {
      int offset =  x + y*kinect.width; // Formula that grabs the raw depth data from the integer array "depth"
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
        img.pixels[offset] = color(0); // Shows depth image outside of "color zone". use the color(); function to disable depth image
      }
    }
  }
  img.updatePixels(); // Updates the images pixels if any changes has occured in the code (needed when useing the function .loadPixels)
  image(img, 0, 0);   // Displays image

  float avgX = sumX/totalPixels; // Finding the average x coordinate
  float avgY = sumY/totalPixels; // Finding the average y coordinate
  fill(150, 0, 255);             // "Fills" the objects color on an RGB scale 
  ellipse(avgX, avgY, 64, 64);   // Draws an ellipse at the position of the average x and y coordinate

  fill(255); 
  textSize(32);
  text("<" + avgX + ", " + avgY + ", " + avgZ + ">", 10, 64); // Prints the average position vector to the display window

  /**** end of coordinate tracking code ****/

  r = int(random(8)); // Generateing random integer (for soundeffects)

  // Checking for houseing unit 2 data 
  if ( BTPort.available() > 0) { 
    FG = BTPort.read(); // read it and store it in FG variable 
    if (FG == 128) {
      FG = 0;
    } else if (FG == 129) {
      FG = 1;
    }
  } else {
    FG = 3;
  }

  // Switch case statement which runs the servo motor as well as tallying whether a shot has been made or missed (make: FG==1, miss: FG==0) and playing soundeffects
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
    else if (avgX > 10 && avgX < 310 && avgZ < 1300) {
      if (FG == 1) {
        FGShotCa2++;
        FGMakeCa2++;
        SE[r].play();   // Plays random audio file  
        SE[r].rewind(); // Rewinds audio file
        println("made shot Ca2");
      } else if (FG == 0) {
        FGShotCa2++;
        println("missed shot Ca2");
      }
    }
    // If user is in section Ca3
    else if (avgX > 10 && avgX < 310 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotCa3++;
        FGMakeCa3++;
        SE[r].play();
        SE[r].rewind();
        println("made shot Ca3");
      } else if (FG == 0) {
        FGShotCa3++;
        println("missed shot Ca3");
      }
    }
    // If user is in section Cb2
    else if (avgX > 310 && avgX < 620 && avgZ < 1300) {
      if (FG == 1) {
        FGShotCb2++;
        FGMakeCb2++;
        SE[r].play();
        SE[r].rewind();
        println("made shot Cb2");
      } else if (FG == 0) {
        FGShotCb2++;
        println("missed shot Cb2");
      }
    }
    // If user is in section Cb3
    else if (avgX > 310 && avgX < 620 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotCb3++;
        FGMakeCb3++;
        SE[r].play();
        SE[r].rewind();
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
    // If user goes out of frame to the left of them
    if (avgX > 620) {
      UNOPort.write('2');
      Section = 2;
      println("Moving to section 2");
      delay(2500);
    }        
    // If user is in section A2 
    else if (avgX > 10 && avgX < 310 && avgZ < 1300) {
      if (FG == 1) {
        FGShotA2++;
        FGMakeA2++;
        SE[r].play();
        SE[r].rewind();
        println("made shot A2");
      } else if (FG == 0) {
        FGShotA2++;
        println("missed shot A2");
      }
    }
    // If user is in section A3
    else if (avgX > 10 && avgX < 310 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotA3++;
        FGMakeA3++;
        SE[r].play();
        SE[r].rewind();
        println("made shot A3");
      } else if (FG == 0) {
        FGShotA3++;
        println("missed shot A3");
      }
    }
    // If user is in section B2
    else if (avgX > 310 && avgX < 620 && avgZ < 1300) {
      if (FG == 1) {
        FGShotB2++;
        FGMakeB2++;
        SE[r].play();
        SE[r].rewind();
        println("made shot B2");
      } else if (FG == 0) {
        FGShotB2++;
        println("missed shot B2");
      }
    }
    // If user is in section B3
    else if (avgX > 310 && avgX < 620 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotA3++;
        FGMakeA3++;
        SE[r].play();
        SE[r].rewind();
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
    else if (avgX > 310 && avgX < 620 && avgZ < 1300) {
      if (FG == 1) {
        FGShotE2++;
        FGMakeE2++;
        SE[r].play();
        SE[r].rewind();
        println("made shot E2");
      } else if (FG == 0) {
        FGShotE2++;
        println("missed shot E2");
      }
    }
    // If user is in section E3
    else if (avgX > 310 && avgX < 620 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotE3++;
        FGMakeE3++;
        SE[r].play();
        SE[r].rewind();
        println("made shot E3");
      } else if (FG == 0) {
        FGShotE3++;
        println("missed shot E3");
      }
    }
    // If user is in section D2
    else if (avgX > 10 && avgX < 310 && avgZ < 1300) {
      if (FG == 1) {
        FGShotD2++;
        FGMakeD2++;
        SE[r].play();
        SE[r].rewind();
        println("made shot D2");
      } else if (FG == 0) {
        FGShotD2++;
        println("missed shot D2");
      }
    }
    // If user is in section D3
    else if (avgX > 10 && avgX < 310 && avgZ >= 1300) {
      if (FG == 1) {
        FGShotD3++;
        FGMakeD3++;
        SE[r].play();
        SE[r].rewind();
        println("made shot D3");
      } else if (FG == 0) {
        FGShotD3++;
        println("missed shot D3");
      }
    }

  default:
    break;
  }
  
  // Function used to display real-time heatmap 
  if (keyPressed) {
    if (key == ENTER) {
      image(himg, -15, 50); // Displays heatmap image
      textSize(12);
      
      /* Section 1 */
      fill(255, 0, 0); // Sets the text's color
      
      // Position A
      text(round(FGMakeA2) + "/" + round(FGShotA2) + ", " + round((FGMakeA2/FGShotA2)*100) + "%", 145, 410); // A2
      text(round(FGMakeA3) + "/" + round(FGShotA3) + ", " + round((FGMakeA3/FGShotA3)*100) + "%", 50, 410);  //A3
     
      // Position b
      text(round(FGMakeB2) + "/" + round(FGShotB2) + ", " + round((FGMakeB2/FGShotB2)*100) + "%", 145, 320); // B2
      text(round(FGMakeB3) + "/" + round(FGShotB3) + ", " + round((FGMakeB3/FGShotB3)*100) + "%", 50, 320);  // B3
      
      /* Section 2 */
      fill(255, 255, 0);
      
      // Position Ca
      text(round(FGMakeCa2) + "/" + round(FGShotCa2) + ", " + round((FGMakeCa2/FGShotCa2)*100) + "%", 250, 210); // Ca2
      text(round(FGMakeCa3) + "/" + round(FGShotCa3) + ", " + round((FGMakeCa3/FGShotCa3)*100) + "%", 145, 160); // Ca3      
      
      // Position Cb
      text(round(FGMakeCb2) + "/" + round(FGShotCb2) + ", " + round((FGMakeCb2/FGShotCb2)*100) + "%", 350, 210); // Cb2
      text(round(FGMakeCb3) + "/" + round(FGShotCb3) + ", " + round((FGMakeCb3/FGShotCb3)*100) + "%", 430, 160); // Cb3
      
      /* Section 3 */
      fill(0, 0, 255);
      
      // Position D
      text(round(FGMakeD2) + "/" + round(FGShotD2) + ", " + round((FGMakeD2/FGShotD2)*100) + "%" , 430, 320); // D2
      text(round(FGMakeD3) + "/" + round(FGShotD3) + ", " + round((FGMakeD3/FGShotD3)*100) + "%" , 535, 320); // D3
      
      // Position E
      text(round(FGMakeE2) + "/" + round(FGShotE2) + ", " + round((FGMakeE2/FGShotE2)*100) + "%", 430, 410); //E2
      text(round(FGMakeE3) + "/" + round(FGShotE3) + ", " + round((FGMakeE3/FGShotE3)*100) + "%", 535, 410); // E3
    }
  }

  // Printing heat map data to excel file "HeatMap.csv"
  HeatMap.addRow(); // Creates an empty row
  
  // Parameters: (row, column, value, columnName) 
  HeatMap.setString(0, "A2", round(FGMakeA2) + "|" + round(FGShotA2)); 
  HeatMap.setString(0, "A3", round(FGMakeA3) + "|" + round(FGShotA3));
  HeatMap.setString(0, "B2", round(FGMakeB2) + "|" + round(FGShotB2));
  HeatMap.setString(0, "B3", round(FGMakeB3) + "|" + round(FGShotB3));
  HeatMap.setString(0, "Ca2", round(FGMakeCa2) + "|" + round(FGShotCa2));
  HeatMap.setString(0, "Ca3", round(FGMakeCa3) + "|" + round(FGShotCa3));
  HeatMap.setString(0, "Cb2", round(FGMakeCb2) + "|" + round(FGShotCb2));
  HeatMap.setString(0, "Cb3", round(FGMakeCb3) + "|" + round(FGShotCb3));
  HeatMap.setString(0, "D2", round(FGMakeD2) + "|" + round(FGShotD2));
  HeatMap.setString(0, "D3", round(FGMakeD3) + "|" + round(FGShotD3));
  HeatMap.setString(0, "E2", round(FGMakeE2) + "|" + round(FGShotE2));
  HeatMap.setString(0, "E3", round(FGMakeE3) + "|" + round(FGShotE3));
  saveTable(HeatMap, "data/HeatMap.csv");
}