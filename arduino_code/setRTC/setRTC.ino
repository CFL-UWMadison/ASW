// Set and use the real time clock
#include "RTClib.h"
RTC_PCF8523 rtc;

void setup () {
  Serial.begin(57600);
  rtc.begin();

  //set the clock; comment out if not needed
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

void loop () {
    DateTime now = rtc.now();
    String timeStamp = formatTimestamp(now);
    Serial.println(timeStamp); //print the variable
    delay(1000);
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
