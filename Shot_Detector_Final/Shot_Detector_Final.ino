/*
 *Final sketch used in the kinect basketball shot sensor's houseing unit #2, which was
 *used to detect made and missed basketball field goals with the use of an ultrasonic
 *sensor and a piezo electric vibration sensor. The ultrasonic was used to detect a
 *balls movement threw a basketball netting while the vibration sensor tracked when
 *a vibration occurred on the basketballs rim. If a vibration occurs, but no movement
 *threw the net is detected, a '0' or "miss" is sent down via bluetooth to the main
 *houseing unit (houseing unit #1). If a vibration occurs but movement threw the net
 *is detected (or movement threw the net is detected at any point threw a shooting
 *session) a '1' or "make" is sent down to houseing unit #1.
*/

#include <SoftwareSerial.h>

SoftwareSerial mySerial(0, 1); // RX, TX pins on Arduino UNO
int data[1];

// digital Pin variables
const int VibPin = 2;
const int TrigPin = 3;
const int EchoPin = 4;      

// Ultrasonic sensor variables
int MAXRange = 200; // Maximum ultasonic sensor distance measured
int MINRange = 0;   // Minimum ultrasonic sensor distance measured
int FieldGoal = 0;  // Variable used to detected a "MAKE!"
long t, d;          // time and distance

void setup() {
  mySerial.begin(9800);
  pinMode(TrigPin, OUTPUT);
  pinMode(EchoPin, INPUT);  
  pinMode(VibPin, INPUT);
  delay(3000);
}

void loop() {
  UltraSonic(); // Runs the "UltraSonic" function
  if (FieldGoal == 1) {
    data[0] = 1;             // Sets data array to '1'
    mySerial.write(data[0]); // sends a '1' or "make" down to the houseing unit #1
    FieldGoal = 0;           // Reseting variable
    delay(5000);
  } else if (digitalRead(VibPin) == HIGH) {
    for(int i=0; i<=10; i++) {
      UltraSonic();
      delay(300);  
      if (FieldGoal == 1) {
        data[0] = 1;             // Sets data array to '1'
        mySerial.write(data[0]); // sends a "1" or "make" down to the houseing unit #1
        FieldGoal = 0;           // Reseting variable            
        i = 11;                  // "Breaks" the for loop
        delay(5000);
      } else if (i == 10) {
        data[0] = 0;          // Sets data array to a '0'
        mySerial.write(data[0]); // Sends a "0" or "miss" down to houseing unit #2
      }
    }
  }
}

// Function for the ultra sonic sensor cycle code
void UltraSonic() {
 digitalWrite(TrigPin, LOW); 
 delayMicroseconds(2); 

 digitalWrite(TrigPin, HIGH);
 delayMicroseconds(10); 
 
 digitalWrite(TrigPin, LOW);
 t = pulseIn(EchoPin, HIGH); // Reads how long it takes for a pulse to send in recive in millisecond
 
 d = t/58.2; // Calculateing distance in cm
 
 if (d < 40){       
   FieldGoal = 1; // Sets the variable "FieldGoal" to 1 so that when the for loop above is running knows that movement was detected through the netting
 }
 else if (d > MAXRange || d < MINRange) {
   d = -1;
 }
}
