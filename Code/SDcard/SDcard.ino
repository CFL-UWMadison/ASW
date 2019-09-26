#include <SD.h> //add the SD library

//The SD uses pin 10 on the Feather;
const int SDchipSelect = 10;

void setup() {
 // Initialize the SD Card:
 SD.begin(SDchipSelect); 
}

void loop() {
  // Open the output file for writing/appending
  File dataFile = SD.open("testfile.txt", FILE_WRITE);
  dataFile.println("Some text on the SD card");
  dataFile.close(); //close the CSV file
  delay(1000); //wait 5 seconds and do it again
}
