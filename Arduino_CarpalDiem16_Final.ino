/* This is the master Arduino code for the Carpal Diem Device. This code is used
    to run the motor as well as read from the analog pins using a 2 multiplexers.
    In addition, a function called "EEPROM" is used to help with motor homing.

    The corresponding Processing code is Processing_CarpalDiem16_Final

    Created by Rachel Sterling, May 2016
*/

#include <EEPROM.h>

// Data coming in
int Direction; // will come in as 1 = flexion, -1 = extension
float NumSteps; // translated
String Response; // will always be "GO" if 'Run' button was pressed
float command;


// Motorshield Setup
int DirectionA = 12;
int DirectionB = 13;
int Dir = 0;
int BrakeA = 9;
int BrakeB = 8;
int StepA = 3;
int StepB = 11;
int Speed = 10; //Control how fast to "step" the motor (delay between pulses)

// EEPROM
int EEPROM_NUM;
int addr = 0;

//Mux control pins
int s0 = 8;
int s1 = 9;
int s2 = 10;
int s3 = 11;
long int PrevPrintTime;
int s4 = 4;
int s5 = 5;
int s6 = 6;
int s7 = 7;

//Mux in "SIG" pin
int SIG_pin = 15;
int SIG_pin2 = 14;

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.println("Hey");  // Send a salutation
    delay(100);
  }
}

void setup() {

  // HANDSHAKE - Connect Processing and Arduino
  Serial.begin(9600);
  establishContact(); //send a byte to establish contact until receiver responds

  // Setup Sensor Pins
  pinMode(s0, OUTPUT);
  pinMode(s1, OUTPUT);
  pinMode(s2, OUTPUT);
  pinMode(s3, OUTPUT);
  pinMode(s4, OUTPUT);
  pinMode(s5, OUTPUT);
  pinMode(s6, OUTPUT);
  pinMode(s7, OUTPUT);

  digitalWrite(s0, LOW);
  digitalWrite(s1, LOW);
  digitalWrite(s2, LOW);
  digitalWrite(s3, LOW);
  digitalWrite(s4, LOW);
  digitalWrite(s5, LOW);
  digitalWrite(s6, LOW);
  digitalWrite(s7, LOW);

  // Setup Motor Pins
  pinMode (DirectionA, OUTPUT); //CH A -- HIGH=forward, LOW=backwards
  pinMode (DirectionB, OUTPUT); //CH B -- HIGH=forward, LOW=backwards

  pinMode (BrakeA, OUTPUT);
  pinMode (BrakeB, OUTPUT);

  digitalWrite(DirectionB, HIGH);

  // Pull EEPROM from Arduino addr 0
  EEPROM.get(addr, EEPROM_NUM); // recovers TotalDistance from the disk
}

void loop() {

// Create String of Data for Processing (processing reads in as "data")
  if (millis() - 500 > PrevPrintTime) {
    Serial.print(readMux(0));
    Serial.print("a");
    Serial.print(readMux(1));
    Serial.print("b");
    Serial.print(readMux(2));
    Serial.print("c");
    Serial.print(readMux(3));
    Serial.print("d");
    Serial.print(readMux(4));
    Serial.print("e");
    Serial.print(readMux(5));
    Serial.print("f");
    Serial.print(readMux(6));
    Serial.print("g");
    Serial.print(readMux(7));
    Serial.print("h");
    Serial.print(readMux(8));
    Serial.print("i");
    Serial.print(readMux(9));
    Serial.print("j");
    Serial.print(readMux2(0));
    Serial.print("k");
    Serial.print(readMux2(1));
    Serial.print("l");
    Serial.print(readMux2(2));
    Serial.print("m");
    Serial.print(readMux2(3));
    Serial.print("n");
    Serial.print(readMux2(4));
    Serial.print("o");
    Serial.print(readMux2(5));
    Serial.print("p");
    Serial.print(readMux2(6));
    Serial.print("q");
    Serial.print(readMux2(7));
    Serial.print("r");
    Serial.print(readMux2(8));
    Serial.print("s");
    Serial.print(readMux2(9));
    Serial.print("t");
    Serial.print(readMux(10));
    Serial.print("u");
    Serial.print(readMux(11));
    Serial.print("v");
    Serial.print(EEPROM_NUM);
    Serial.print("w");
    Serial.println("\n");
    PrevPrintTime = millis();
  }

  if (Serial.available() > 0) { // if data is available to read,

    command = Serial.parseFloat(); // read it and store it in command
    NumSteps = abs(command) / .12; // translates command (in degrees) to Number of steps to take


    if ( command > 0) {
      Dir = 1;
      for (int i = 0 ; i < NumSteps; i++) {

        digitalWrite(BrakeA, LOW); // Disengages Channel A brake --> Channel A runs
        digitalWrite(BrakeB, HIGH); // Engages Channel B brake

        //This whole block is the "step" part of the youtube vid

        digitalWrite(DirectionA, HIGH); // Continues pre-set forward direction of Channel A
        analogWrite(StepA, 255); // Spins Channel A motor
        delay(Speed);

        // Phase 1/3____________________________________
        digitalWrite(BrakeA, HIGH); // Engages Channel A brake
        digitalWrite(BrakeB, LOW); // Disengages Channel B brake --> Channel B runs

        digitalWrite(DirectionB, LOW); // Change
        analogWrite(StepB, 255);

        delay(Speed);
        // Phase 2/3__________________________________
        digitalWrite(BrakeA, LOW);
        digitalWrite(BrakeB, HIGH);

        digitalWrite(DirectionA, LOW);
        analogWrite(StepA, 255);

        delay(Speed);
        // Phase 3/3____________________________
        digitalWrite(BrakeA, HIGH);
        digitalWrite(BrakeB, LOW);

        digitalWrite(DirectionB, HIGH);
        analogWrite(StepB, 255);

        delay(Speed);
      }
      EEPROM_NUM = NumSteps * Dir + EEPROM_NUM; // Determine new position
      EEPROM.put(addr, EEPROM_NUM); // Write new position to Arduino Memory 
    }
    else if (command <= 0) { 
      Dir = -1;
      for (int i = 0 ; i < NumSteps; i++) {
        //  if (stop == false) {
        digitalWrite(BrakeA, LOW); // Disengages Channel A brake --> Channel A runs
        digitalWrite(BrakeB, HIGH); // Engages Channel B brake

        //This whole block is the "step" part of the youtube vid

        digitalWrite(DirectionA, HIGH); // Continues pre-set forward direction of Channel A
        analogWrite(StepA, 255); // Spins Channel A motor
        delay(Speed);

        // Phase 1/4____________________________________
        digitalWrite(BrakeA, HIGH); // Engages Channel A brake
        digitalWrite(BrakeB, LOW); // Disengages Channel B brake --> Channel B runs

        digitalWrite(DirectionB, HIGH); // Change
        analogWrite(StepB, 255);

        delay(Speed);
        // Phase 2/4__________________________________
        digitalWrite(BrakeA, LOW);
        digitalWrite(BrakeB, HIGH);

        digitalWrite(DirectionA, LOW);
        analogWrite(StepA, 255);

        delay(Speed);
        // Phase 3/4____________________________
        digitalWrite(BrakeA, HIGH);
        digitalWrite(BrakeB, LOW);

        digitalWrite(DirectionB, LOW);
        analogWrite(StepB, 255);

        delay(Speed);
      }
      EEPROM_NUM = NumSteps * Dir + EEPROM_NUM;
      EEPROM.put(addr, EEPROM_NUM);
    }
  }
}

// Multiplexer 1 Matrix
int readMux(int channel) {
  int controlPin[] = {s0, s1, s2, s3};
  const int muxChannel[16][4] = {
    {0, 0, 0, 0}, //channel 0
    {1, 0, 0, 0}, //channel 1
    {0, 1, 0, 0}, //channel 2
    {1, 1, 0, 0}, //channel 3
    {0, 0, 1, 0}, //channel 4
    {1, 0, 1, 0}, //channel 5
    {0, 1, 1, 0}, //channel 6
    {1, 1, 1, 0}, //channel 7
    {0, 0, 0, 1}, //channel 8
    {1, 0, 0, 1}, //channel 9
    {0, 1, 0, 1}, //channel 10
    {1, 1, 0, 1}, //channel 11
    {0, 0, 1, 1}, //channel 12
    {1, 0, 1, 1}, //channel 13
    {0, 1, 1, 1}, //channel 14
    {1, 1, 1, 1} //channel 15
  };

  //loop through the 4 sig
  for (int i = 0; i < 4; i ++) {
    digitalWrite(controlPin[i], muxChannel[channel][i]);
  }

  //read the value at the SIG pin
  int val = analogRead(SIG_pin);

  //return the value
  return val;
}

// Multiplexer 2 Matrix
int readMux2(int channel2) {
  int controlPin2[] = {s4, s5, s6, s7};
  const int muxChannel2[16][4] = {
    {0, 0, 0, 0}, //channel 16
    {1, 0, 0, 0}, //channel 17
    {0, 1, 0, 0}, //channel 18
    {1, 1, 0, 0}, //channel 19
    {0, 0, 1, 0}, //channel 20
    {1, 0, 1, 0}, //channel 21
    {0, 1, 1, 0}, //channel 22
    {1, 1, 1, 0}, //channel 23
    {0, 0, 0, 1}, //channel 24
    {1, 0, 0, 1}, //channel 25
    {0, 1, 0, 1}, //channel 26
    {1, 1, 0, 1}, //channel 27
    {0, 0, 1, 1}, //channel 28
    {1, 0, 1, 1}, //channel 29
    {0, 1, 1, 1}, //channel 30
    {1, 1, 1, 1} //channel 31
  };

  //loop through the 4 pins
  for (int i = 0; i < 4; i ++) {
    digitalWrite(controlPin2[i], muxChannel2[channel2][i]);
  }

  //read the value at the SIG pin
  int val2 = analogRead(SIG_pin2);

  //return the value
  return val2;
}




