
#include <SD.h>
#include <SPI.h>
#include "RTClib.h"
#include <Wire.h>
#include <DallasTemperature.h>
#include <Adafruit_VEML7700.h>


// Link to RTC
RTC_PCF8523 rtc;

//The One Wire bus is D6
#define ONE_WIRE_BUS 6
// Link to One Wire
OneWire oneWire(ONE_WIRE_BUS); 
// Link dallasTemp sensor to One Wire bus
DallasTemperature dallasTemp(&oneWire);

// Calibration result for dallasTemp - value in ice water (assume 0.1C)
#define T0 1.06

// Lux Sensor
Adafruit_VEML7700 veml = Adafruit_VEML7700();

// pH analog pin
#define pHpin A3
// thermister pin
#define thermPin A5

// Calibration results - values from 10-bit ADC 
#define pH4 620
#define pH7 429

//The SD uses pin 10 on the Feather;
const int SDchipSelect = 10;

void setup() {

  delay(1000); //give everything a second to start up
  pinMode(13, OUTPUT);  //LED for blinking
  Serial.begin(57600);

  // Initialize the SD Card:
  if (SD.begin(SDchipSelect)) {
    Serial.println("SD card initialized.");
  } else 
    Serial.println("SD card NOT initialized.");

 // Initialize the RTC:
  if (rtc.begin()) {
    Serial.println("RTC initialized.");
  } else 
    Serial.println("RTC NOT initialized."); 

  // Initialize the VEML Lux sensor
  if (veml.begin()) {
    Serial.println("Lux sensor found");
  } else
  Serial.println("Lux sensor NOT found");

  // Initialize the DS18B20 dallasTemp sensor - returns null
  dallasTemp.begin();

}//setup

void loop() {

  // 2 quick blinks
  for (int blink=0; blink < 2; blink++) {
      digitalWrite(13, HIGH); delay(300);
      digitalWrite(13, LOW); delay(200);
  }

  // Make a string for assembling the data to log:
  String timeStamp;
  String dataSample = "";
  DateTime now = rtc.now();

  // Format the timestamp  
  timeStamp = formatTimestamp(now);
  //Serial.println(timeStamp);

  // Simple read of the lux value
  float lux = veml.readLux();
  //Serial.print("Lux: "); Serial.println(lux);

  // Get the pH ADC output from A5 (pHpin)
  float pHread = analogRead(pHpin); //0-1024 digital
  //Serial.print("pH Read: "); Serial.println(pHread);

  // Convert ADC output to corrected pH using two-point calibration results
  //corr =  (((rawValue-rawLow)*referenceRange)/(rawRange)) + referenceLow
  //where referenceRange = -3 and rawRange= pH4-pH7
  float pHcorr = (((pHread-pH7)*(-3))/(pH4-pH7)) + 7;
  //Serial.print("pHcorr: "); Serial.println(pHcorr,2);

  // Get the Dallas dallasTemperature data
  dallasTemp.requestTemperatures();
  float dallasTempRaw= dallasTemp.getTempCByIndex(0);
  float dallasTempCorr = dallasTempRaw - T0; //single point calibration correction
  //Serial.print("dallasTemp: "); Serial.println(dallasTempCorr,2);

  // Get the thermister temp data
  //get the value from the ADC (0-1023)
  int thermADC = analogRead(thermPin);
  //calc thermister R
  float rTherm = 10000.*thermADC/(1023. - thermADC);
  //calc inverted T in Kelvin
  float Tinv = (1/298.15) + (1/3950.)*log(rTherm/10000.);
  //convert the centigrade
  float thermTemp = (1/Tinv) - 273.15;

  // Assemble the data string in CSV format
  dataSample += timeStamp;
  dataSample += ",";
  dataSample += lux;
  dataSample += ",";
  dataSample += pHcorr;
  dataSample += ",";
  dataSample += dallasTempCorr;
  dataSample += ",";
  dataSample += thermTemp;


  // Open the output file for writing/appending
  File dataFile = SD.open("asw_log.txt", FILE_WRITE);

  if (dataFile) {
    dataFile.println(dataSample);  delay(100);
    //Serial.println("Writing data record to SD");    
    dataFile.close(); //close the CSV file
  } else  {
    Serial.println("SD card file did not open");
  }
  Serial.println(dataSample);
  
  delay(5000);//wait 5 seconds and do it again

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
 
