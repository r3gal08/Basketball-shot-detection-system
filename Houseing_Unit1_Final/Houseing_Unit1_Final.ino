/*
 *This sketch is in control of the servo unit's position.
 *Data is read over threw the main processing program via
 *serial communication.
*/

#include <Servo.h> // Arduino custom servo libary

Servo KinectServo; // Servo motor object

int POSData; // Postion data being fed over serially from the kinect processing code

void setup() {
  Serial.begin(9600);
  KinectServo.attach(9); // Defineing what digital pin the servo is attatched to
  KinectServo.write(90);
  delay(3000);
}

void loop() {
/*Function used to read postion vector data from a seperate processing program 
  and then write data to a servo depending on said position vector */  
  if (Serial.available() > 0) {
    int POSData = Serial.read();
    switch (POSData) {
      case '1' :
      KinectServo.write (135); // Moves servo to section 1
      break;

      case '2' : 
      KinectServo.write (90); // Moves servo to section 2
      break;

      case '3':
      KinectServo.write (45); // Moves servo to section 3
      
      default : 
      break;
    }
  } 
}
