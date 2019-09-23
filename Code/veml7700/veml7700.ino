#include <Wire.h>
#include <Adafruit_VEML7700.h>
//Need to install "Adafruit_BusIO" library

// Lux Sensor
Adafruit_VEML7700 veml = Adafruit_VEML7700();

void setup() {
  Serial.begin(9600);
  // Initialize the VEML Lux sensor
  veml.begin();
}

void loop() {

  //get lux value
  float lux = veml.readLux();
  Serial.print("Lux: "); Serial.println(lux);
  delay(2000);

}
