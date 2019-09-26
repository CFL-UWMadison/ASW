#include <SD.h> //add the SD library
#include "RTClib.h"
RTC_PCF8523 rtc;

//The SD uses pin 10 on the Feather;
const int SDchipSelect = 10;
//Timer
#define DONEPIN 11


void setup() {
 // Initialize the SD Card:
 SD.begin(SDchipSelect);

 // Configure the done pin
 pinMode(DONEPIN,OUTPUT); 
 digitalWrite(DONEPIN,LOW);

 rtc.begin();
}

void loop() {

  //Give 3 quick blinks just to see it's alive.
  pinMode(13, OUTPUT);  //Chip Select
  for (int blink=0; blink < 3; blink++) {
      digitalWrite(13, HIGH);
      delay(500);
      digitalWrite(13, LOW);
      delay(500);
  }
  
  DateTime now = rtc.now();
  String timeStamp = formatTimestamp(now);

  // Open the output file for writing/appending
  File dataFile = SD.open("testfile.txt", FILE_WRITE);
  dataFile.println(timeStamp);
  dataFile.close(); //close the CSV file
  delay(1000); //wait 5 seconds and do it again
  //Shut it down
  digitalWrite(DONEPIN,HIGH);
}


// Format the timestamp to %Y-%m-%d %H:%M:%S
String formatTimestamp(DateTime now) { 
  String result = "";
  result += now.year();
  result += "-" + addleadZero(now.month()) + "-";
  result += addleadZero(now.day()) + " ";
  result += addleadZero(now.hour()) + ":";;
  result += addleadZero(now.minute()) + ":";
  result += addleadZero(now.second());
  return (result);
}

// This just adds a leading zeros to the timestamp if needed
String addleadZero(int value) {
  String result = "0";
  if (value < 10) {
    result += value;
  }
  else {
    result = value;
  }
  return (result);
}
