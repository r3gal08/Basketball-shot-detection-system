/*
 *Created: January 2016 - April 2016
 *Modified: 7 April 2016
 *Author: Brett Leard <126114>
 *-------------------------------------------------------------*
 *This sketch is in control of the servo unit's position.     
 *Data is read over threw the main processing program via     
 *serial communication.                                       
 *Update March 24 2016: Added in a series of functions in      
 *order to slow down the speed of the servo motor. The grooves
 *on the motor were starting to break down due to the weight
 *and tourque created by the Kinect sensor.
 *-------------------------------------------------------------*
 *Update March 31 2016: Added a variable for the increment at
which the servo rotates at.
*/

#include <Servo.h> // Arduino custom servo libary

Servo KinectServo; // Servo motor object

int POSData;    // Postion data being fed over serially from the kinect processing code
int angle = 90; // Servo 'angle' variable
int i = 20;     // Servo 'increment' or 'speed' variable 

void setup() {
  Serial.begin(9800);
  KinectServo.attach(9); // Defineing what digital pin the servo is attatched to
  KinectServo.write(angle);
  delay(5000);
}

void loop() {
  //Function used to read serial data being sent over from the sketch "Kinect_CoordinateTracking_Code_V7"
  if (Serial.available() > 0) {
    int POSData = Serial.read();
    switch (POSData) {
      // Section 1 (135 degrees)
      case '1' :
      while (angle == 90) {
        for (angle=90; angle<=134; angle++) {
          Serial.println(angle);
          KinectServo.write(angle);
          delay(i);
        }
      }
      break;

      // Section 2 (90 degrees);
      case '2' : 
      if (angle == 45) {
        while (angle == 45) {    
          for (angle=45; angle<=89; angle++) {
            Serial.println(angle);
            KinectServo.write(angle);
            delay(i);
          }
        }
      } else if (angle == 135) {
        while (angle == 135) {
          for (angle=135; angle>=91; angle--) {
            Serial.println(angle);
            KinectServo.write(angle);
            delay(i);
          }
        }
      }
      break;
      
      // Section 3 (90 degrees)
      case '3':
      while(angle == 90) {
        for (angle=90; angle>=46; angle--) {
          Serial.println(angle);
          KinectServo.write(angle);
          delay(i);
        }
      }
      
      default : 
      break;
    }
  } 
}
