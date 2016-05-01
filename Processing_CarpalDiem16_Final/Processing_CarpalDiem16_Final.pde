/* This is the master Processing code for the Carpal Diem Device. This code is used 
 *  to diplay a user friendly GUI, where the user can send a motor command to Arduino
 *  and see the resulting sensor responses through a visual pressure distribution map 
 *  and through calculated froce in, force out and force efficiency. The user can also
 *  choose to see this display for 3 different sensored objects. There are several libraries
 *  involved in this code. ControlP5 is that main library used to create the functional 
 *  aspects of the GUI (buttons, toggle switches etc). Serial is the way in which Processing
 *  and arduino communicate. 
 *
 *  The corresponding Arduino code is Arduino_CarpalDiem16_Final
 *
 * Created by Rachel Sterling, May 2016
 */

// ********************* IMPORT LIBRARIES *************************
// GUI
import controlP5.*;
ControlP5 cp5;
DropdownList d1;
controlP5.Button b;
Table table;

// Arduino and motor 
import processing.serial.*;
Serial myPort;
boolean firstContact = false; 

// ********************* INITIALIZE VARIABLES *************************
// DATA TO SEND 
int run = 0;
float command; 
int Direction; 
float Angle = 1;


// DATA RECEIVED 

//// String of data from Arduino ready to parse
String data = null;
String sensors;

//// Variables used to determine motor position and homing 
float EEPROM_NUM; 
float Home;                                                            
float CurrentAngle = 0;                             

//// Original Arduino FSR readings
float ofsr0;     
float ofsr1;     
float ofsr2;     
float ofsr3;     
float ofsr4;
float ofsr5;
float ofsr6;     
float ofsr7;     
float ofsr8;     
float ofsr9;     
float ofsr10;
float ofsr11;     
float ofsr12;     
float ofsr13;     
float ofsr14;
float ofsr15;
float ofsr16;     
float ofsr17;     
float ofsr18;     
float ofsr19; 
float ofsr20;    
float ofsr21; 

//// Calibrated FSR readings (reading in lbs)
float fsr0;     
float fsr1;     
float fsr2;     
float fsr3;     
float fsr4;
float fsr5;
float fsr6;     
float fsr7;     
float fsr8;     
float fsr9;     
float fsr10;
float fsr11;
float fsr12;     
float fsr13;     
float fsr14;     
float fsr15;     
float fsr16;
float fsr17;
float fsr18;     
float fsr19;
float fsr20;     
float fsr21;

//// Variables used to read data into .csv file 
int PrevTableTime;
float time;

// OTHER VARIABLES 

//// Aesthetics 
int g=200; // Multiplier for visual output coloring 
String Gfiglisted = "Choose a Shape!";
String DirText = "Flexion";

//// GUI Allignment 
int xpos = 140;
int ypos = 250; 
int lypos = 150;

// Dropdown List 
int selectedImage = 0 ; 


//// Calculations 
float forcein = 1;
float forceout = 1;
float eff = 0;

//// Fonts
PFont titlefont;
PFont textfont;
PFont buttonfont;

//// Arrays 
String [] shapes = {"cylinder", "sphere", "pinch prism"}; 
String [] Gfig = {"Cylindrical Grip", "Spherical Grip", "Pinch"};
String [] buttons = {"Clear", "Run", "Home"};
int [] buttonypos = {80, 120, 160};
PImage[] images = new PImage[3]; // array of images

//// Toggle 
boolean toggleValue = false;


void setup() {
  size(1000, 800);  /// size of GUI
  cp5 = new ControlP5(this); //instantiate ControlP5
  smooth ();

  // Arduino - initialize pins for motor and sensors 
  myPort = new Serial(this, "COM4", 9600);  // instantiate Arduino and connect with arduino board
  myPort.bufferUntil('\n');

  // Fonts
  titlefont = createFont("Arial", 49, true); // create font (main text)
  textfont = createFont("arial", 20); // (font in text field)
  buttonfont = createFont("Arial", 15, true); // use true/false for smooth/no-smooth

  // Textfields
  cp5.addTextfield("")
    .setPosition(xpos, ypos-20)
    .setSize(200, 40)
    .setFont(textfont)
    .setAutoClear(false);      
  ;

  // Buttons
  for (int i=0; i<3; i++) {  /// tell P # of Buttons to make 
    cp5.addBang(buttons[i])
      .setPosition(xpos, ypos+buttonypos[i])
      .setSize(200, 30)
      .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
      .setFont(buttonfont);
  }

  // Save Buttons
  cp5.addBang("Save")
    .setPosition(647, lypos+463)
    .setSize(200, 30)
    .getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER)
    .setFont(buttonfont);

  // Dropdownlist 
  d1 = cp5.addDropdownList("DropdownList")
    .setPosition(650, lypos)                                                         
    .setSize(200, 200);
  customize(d1); // customize the first list

  // Load images in setup
  images[0] = loadImage("Sensors2.jpg");
  images[1] = loadImage("sphere_all.jpg");
  images[2] = loadImage("PP_sensored.jpg");

  // Toggle
  cp5.addToggle("toggle")
    .setPosition(xpos, ypos-75)
    .setSize(50, 20)
    .setValue(true)
    .setMode(ControlP5.SWITCH)
    .setCaptionLabel("");

  // Table 
  table = new Table();
  table.addColumn("Time (s)");         // addColumn setups up table headers
  table.addColumn("Angle (degrees)");
  table.addColumn("Force IN");
  table.addColumn("Force OUT");
  table.addColumn("Force Efficiency");
  table.addColumn("Sensor A1");
  table.addColumn("Sensor A2");
  table.addColumn("Sensor A3");
  table.addColumn("Sensor A4");
  table.addColumn("Sensor A5");
  table.addColumn("Sensor B1");
  table.addColumn("Sensor B2");
  table.addColumn("Sensor B3");
  table.addColumn("Sensor B4");
  table.addColumn("Sensor B5");
  table.addColumn("Sensor C1");
  table.addColumn("Sensor C2");
  table.addColumn("Sensor C3");
  table.addColumn("Sensor C4");
  table.addColumn("Sensor C5");  
  table.addColumn("Sensor D1");
  table.addColumn("Sensor D2");
  table.addColumn("Sensor D3");
  table.addColumn("Sensor D4");
  table.addColumn("Sensor D5");
}

// This method is called in the "SENSORS" section below to parse data by specified char 
float parseValueFromPort(char d) {
  while ((sensors = myPort.readStringUntil(d)) == null) {
  } 
  sensors = sensors.substring(0, sensors.length()-1);
  return float(sensors);
}


void draw() {
  background(0);

  // Titles
  textFont(titlefont, 49);                  
  fill(255);                         
  textAlign(CENTER);
  text("Motor Control", width/4, 75);  
  text("Sensor Results", 3*width/4, 75);   

  // ********************* SENSORS *************************
  // Parsing Sensor Readings 
  if (firstContact == true && myPort.available()>75) { 

    ofsr0 = parseValueFromPort('a');
    ofsr1 = parseValueFromPort('b');
    ofsr2 = parseValueFromPort('c');
    ofsr3 = parseValueFromPort('d');
    ofsr4 = parseValueFromPort('e');
    ofsr5 = parseValueFromPort('f');
    ofsr6 = parseValueFromPort('g');
    ofsr7 = parseValueFromPort('h');
    ofsr8 = parseValueFromPort('i');
    ofsr9 = parseValueFromPort('j');
    ofsr10 = parseValueFromPort('k');
    ofsr11 = parseValueFromPort('l');
    ofsr12 = parseValueFromPort('m');
    ofsr13 = parseValueFromPort('n');
    ofsr14 = parseValueFromPort('o');
    ofsr15 = parseValueFromPort('p');
    ofsr16 = parseValueFromPort('q');
    ofsr17 = parseValueFromPort('r');
    ofsr18 = parseValueFromPort('s');
    ofsr19 = parseValueFromPort('t');
    ofsr20 = parseValueFromPort('u');
    ofsr21 = parseValueFromPort('v');
    EEPROM_NUM = parseValueFromPort('w');
    sensors= myPort.readStringUntil('\n');

    // OPTIONAL - To Print Specific Sensor Readings to 
    //            Processing Monitor write in your desired variables 

    print(millis()/1000); // time in seconds 
    print("   ");
    //print(fsr10);
    //print("   ");
    //print(fsr11);
    //print("   ");
    //print(fsr12);
    //println("   ");
    print(EEPROM_NUM);
    print("   ");
    println(EEPROM_NUM/12);
  }

  // Adds new data row to .csv table 
  if (millis()-1000 > PrevTableTime) { // write a new column every 1000 milliseconds 
    TableRow newRow = table.addRow();
    newRow.setFloat("Time (s)", int(millis()/1000));
    newRow.setFloat("Angle (degrees)", CurrentAngle);
    newRow.setFloat("Force IN", forcein);
    newRow.setFloat("Force OUT", forceout);
    newRow.setFloat("Force Efficiency", eff);
    newRow.setFloat("Sensor A1", fsr0);
    newRow.setFloat("Sensor A2", fsr1);
    newRow.setFloat("Sensor A3", fsr2);
    newRow.setFloat("Sensor A4", fsr3);
    newRow.setFloat("Sensor A5", fsr4);
    newRow.setFloat("Sensor B1", fsr5);
    newRow.setFloat("Sensor B2", fsr6);
    newRow.setFloat("Sensor B3", fsr7);
    newRow.setFloat("Sensor B4", fsr8);
    newRow.setFloat("Sensor B5", fsr9);
    newRow.setFloat("Sensor C1", fsr10);
    newRow.setFloat("Sensor C2", fsr11);
    newRow.setFloat("Sensor C3", fsr12);
    newRow.setFloat("Sensor C4", fsr13);
    newRow.setFloat("Sensor C5", fsr14);
    newRow.setFloat("Sensor D1", fsr15);
    newRow.setFloat("Sensor D2", fsr16);
    newRow.setFloat("Sensor D3", fsr17);
    newRow.setFloat("Sensor D4", fsr18);
    newRow.setFloat("Sensor D5", fsr19);
    PrevTableTime= millis();
  }

  // Selected Image for DropdownList
  image(images[selectedImage], 575, lypos+50);   

  // CYLINDAR 
  if (selectedImage == 0) {

    // Calibration Equations 
    fsr0 = (ofsr0-199)/186.97;
    fsr1 = (ofsr1-197)/199.38;
    fsr2 = (ofsr2-198)/192.37;
    fsr3 = (ofsr3-198)/209.65;
    fsr4 = (ofsr4-199)/243.44;
    fsr5 = (ofsr5-199)/211.02;
    fsr6 = (ofsr6-201)/247.74;
    fsr7 = (ofsr7-202)/198.07;
    fsr8 = (ofsr8-205)/242.71;
    fsr9 = (ofsr9-199)/240.63;
    fsr10 = (ofsr10-199)/208.04;
    fsr11 = (ofsr11-198)/197.76;
    fsr12 = (ofsr12-203)/272.88;
    fsr13 = (ofsr13-207)/185.26;
    fsr14 = (ofsr14-206)/275.2;
    fsr15 = (ofsr15-186)/276.23;
    fsr16 = (ofsr16-201)/223.29;
    fsr17 = (ofsr17-198)/269.51;
    fsr18 = (ofsr18-198)/214.73;
    fsr19 = (ofsr19-198)/246.22;
    fsr20 = (ofsr20-186)/276.23;
    fsr21 = (ofsr21-186)/276.23;

    // Visual Output 
    //// Column A
    fill(255 - fsr0*g, 255, 255);
    ellipse(637, lypos+133, 25, 25);
    fill(255 - fsr1*g, 255, 255);
    ellipse(637, lypos+172, 25, 25);
    fill(255 - fsr2*g, 255, 255);
    ellipse(637, lypos+214, 25, 25);
    fill(255 - fsr3*g, 255, 255);
    ellipse(637, lypos+255, 25, 25);
    fill(255 - fsr4*g, 255, 255);
    ellipse(637, lypos+295, 25, 25);
    //// Column B
    fill(255 - fsr5*g, 255, 255);
    ellipse(677, lypos+133, 25, 25);
    fill(255 - fsr6*g, 255, 255);
    ellipse(677, lypos+172, 25, 25);
    fill(255 - fsr7*g, 255, 255);
    ellipse(675, lypos+214, 25, 25);
    fill(255 - fsr8*g, 255, 255);
    ellipse(678, lypos+255, 25, 25);
    fill(255 - fsr9*g, 255, 255);
    ellipse(679, lypos+296, 25, 25);
    //// Column C
    fill(255 - fsr10*g, 255, 255);
    ellipse(814, lypos+133, 25, 25);
    fill(255 - fsr11*g, 255, 255);
    ellipse(814, lypos+175, 25, 25);
    fill(255 - fsr12*g, 255, 255);
    ellipse(814, lypos+214, 25, 25);
    fill(255 - fsr13*g, 255, 255);
    ellipse(814, lypos+255, 25, 25);
    fill(255 - fsr14*g, 255, 255);
    ellipse(814, lypos+294, 25, 25);
    //// Column D
    fill(255- fsr15*g, 255, 255);
    ellipse(852, lypos+133, 25, 25);
    fill(255 - fsr16*g, 255, 255);
    ellipse(852, lypos+172, 25, 25);
    fill(255 - fsr17*g, 255, 255);
    ellipse(851, lypos+211, 25, 25);
    fill(255 - fsr18*g, 255, 255);
    ellipse(851, lypos+253, 25, 25);
    fill(255 - fsr19*g, 255, 255);
    ellipse(852, lypos+292, 25, 25);

    // Force Efficiency Equations 
    forcein = fsr20+fsr21;
    forceout = fsr0+fsr1+fsr2+fsr3+fsr4+fsr5+fsr6+fsr7+fsr8+fsr9+fsr10+fsr11+fsr12+fsr13+fsr14+fsr15+fsr16+fsr17+fsr18+fsr19;
    eff = (forceout)*100/(forcein);

    // SPHERE
  } else if (selectedImage == 1) {

    // Calibration Equation 
    fsr0 = (ofsr0 - 115.31) / 222.12;
    fsr1 = (ofsr1 - 131.69) / 226.81;
    fsr2 = (ofsr2 - 116.73) / 226.5;
    fsr3 = (ofsr3 - 116.15) / 244.02;
    fsr5 = (ofsr5 - 132.79) / 271.25;
    fsr6 = (ofsr6 - 122.04) / 243.34;
    fsr7 = (ofsr7 - 102.75) / 289;
    fsr10 = (ofsr10 - 152.49) / 218.44;
    fsr11 = (ofsr11 - 154.69) / 263.84;
    fsr12 = (ofsr12 - 103.83) / 280.59;

    // Visual Output 
    //// Blue Side 
    fill(255 - fsr0*g, 255, 255);
    rotate(.5);
    ellipse(650, lypos-222, 20, 34);
    rotate(-.5);
    fill(255 - fsr1*g, 255, 255);
    ellipse(638, lypos+116, 33, 33);
    fill(255 - fsr2*g, 255, 255);
    ellipse(685, lypos+98, 30, 30);
    fill(255 - fsr3*g, 255, 255);
    rotate(-.2);
    ellipse(653, lypos+260, 15, 35);
    rotate(.2);
    //// Red Side 
    fill(255 - fsr5*g, 255, 255);
    rotate(.1);
    ellipse(805, lypos+33, 25, 35);
    rotate(-.1);
    fill(255 - fsr6*g, 255, 255);
    ellipse(830, lypos+94, 35, 35);
    fill(255 - fsr7*g, 255, 255);
    rotate(-.2);
    ellipse(812, lypos+280, 27, 35);
    rotate(.2);
    //// Yellow Side 
    fill(255 - fsr10*g, 255, 255);
    rotate(.5);
    ellipse(815, 32, 25, 35);
    rotate(-.5);
    fill(255 - fsr11*g, 255, 255);
    ellipse(746, lypos+286, 35, 35);
    fill(255 - fsr12*g, 255, 255);
    rotate(-.6);
    ellipse(414, lypos+642, 27, 35);
    rotate(.6);

    // Force Efficiency Equations 
    forcein = fsr20+fsr21;
    forceout = fsr0+fsr1+fsr2+fsr3+fsr4+fsr5+fsr6+fsr7+fsr8+fsr9;
    eff = (forceout)*100/(forcein);

    // PINCH
  } else   if (selectedImage == 2) {

    // Calibration Equations 
    fsr0 = (ofsr0 - 326) / 4000;
    fsr1 = (ofsr1 - 6.9231) / 5065.3;
    fsr2 = (ofsr2 - 525.08) / 3192.3;
    fsr3 = (ofsr3 - 180.92) / 716.78;

    //Yellow Side 
    fill(255 - fsr0*g, 255, 255);
    ellipse(630, lypos+212, 45, 45);
    fill(255 - fsr1*g, 255, 255);
    ellipse(695, lypos+209, 45, 45);
    //Blue Side 
    fill(255 - fsr3*g, 255, 255);
    ellipse(804, lypos+205, 45, 45);
    fill(255 - fsr2*g, 255, 255);
    ellipse(870, lypos+205, 45, 45);

    // Force Efficiency Equations 
    forcein = fsr20+fsr21;
    forceout = fsr0+fsr1+fsr2+fsr3;
    eff = (forceout)*100/(forcein);
  } 

  // Sensor Text on GUI
  textFont(textfont, 25);  
  text("Testing = ", 645, lypos+435);
  text(Gfiglisted, 810, lypos+435);
  text("Force Input = ", 675, lypos+540);
  text(str(forcein)+"lbs", 830, lypos+540);
  text("Force Output = ", 665, lypos+570);
  text(str(forceout)+"lbs", 830, lypos+570);
  text("Force Efficiency = ", 650, lypos+600);
  text(str(eff)+"%", 830, lypos+600);

  // ********************* MOTOR *************************
  // Pull User Input for "Angle" from Texfields 
  Angle = float(cp5.get(Textfield.class, "").getText());

  // Motor Text
  textFont(textfont, 20);  
  text(DirText, 270, ypos-59);
  text("ANGLE", width/4, lypos+150);
}

// Toggle Function
void toggle(boolean theFlag) {
  if (theFlag==true) {
    Direction = 1;
    DirText = "Flexion";
  } else {
    Direction = -1;
    DirText = "Extension";
  }
}

// THE HANDSHAKE - lines of code establishing contact between Arduino and Processing
void serialEvent( Serial myPort) {
  data = myPort.readStringUntil('\n');
  if (data !=null) {
    data = trim(data);
    if (firstContact == false) {
      if (data.equals("Hey")) {
        myPort.clear();
        firstContact = true;
        myPort.write("hey");
        println("Arduino and Processing are now friends <3");
      }
    } else { // if we've already established contact, keep getting and parsing data!
    }
  }
}

// Event for clear button 
public void clear() {
  cp5.get(Textfield.class, "help").clear();
}

// Controls "Events" for dropdown list, toggle and all the buttons 
void controlEvent(ControlEvent theEvent) { 
  if (theEvent.getController().getName() == "DropdownList") {
    selectedImage = int(theEvent.getController().getValue());
    Gfiglisted = Gfig[selectedImage];
  } else if (theEvent.getController().getName() == "Toggle") {
  } else if (theEvent.getController().getName() == "Run") {
    
      // right now the code doesn't run the safety angle function b/c problems with tensioning would require constant updating of the Home variable.
      // once homing is reliable and you are confident the code "knows" where the motor is at, uncomment the variable "run" in the if else statement. 

    command = Angle*Direction;
    CurrentAngle = -(Home - EEPROM_NUM)*.12;  // When clicked FIRST determine current location                                                      
    print(CurrentAngle);
    print("  ");
    print(CurrentAngle+command);
    run = 1;
    if ( CurrentAngle+command >= -45 && CurrentAngle+command <= 45) { // SECOND determine whether the command goes outside set bounds
      print("I would run");
      //run = 1;
    } else {
      // run = 0;
      print("I wouldn't run");
    } 
    if (run == 1) { // if the command is safe, run the command
      cp5.get(Textfield.class, "").clear();
      println("Motor is moving, please wait.");
      String s = str(command);
      myPort.write(s);
      } else if (run == 0) {
       println("Sorry, the angle you requested is outside a safe travel range");
    }
  } else if (theEvent.getController().getName() == "Home") {
    Home = 12746;                                                                                                                                  /// HERE IS WHERE YOU HOME!! 
    command = (Home - EEPROM_NUM)*.12;  // Writes command to be distance from home moving towards home when clicked                      
    String s =str(command);
    myPort.write(s);
  } else if (theEvent.getController().getName() == "Save") {
    saveTable(table, "SensorData.csv"); // Save Table to CSV File  when clicked
  }
}


// Key events to change the properties of DropdownList d1
void keyPressed() {
  if (key=='1') {
    d1.setHeight(150);
  }
}

// Customize look of dropdown list
void customize(DropdownList ddl) {
  /// customize DropdownList
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(30);
  ddl.setBarHeight(30);
  ddl.getCaptionLabel().set("Choose a Shape");
  for (int i=0; i<3; i++) { /// tell P # of Dropdownlist options to make 
    ddl.addItem(shapes[i], i);
  }
  //ddl.scroll(0);
  ddl.setColorBackground(color(120, 10, 0));
  ddl.setColorActive(color(255, 128));
}
