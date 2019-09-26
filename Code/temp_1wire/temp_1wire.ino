
//set analog pin
#include <DallasTemperature.h>

//The One Wire bus is on D6
#define ONE_WIRE_BUS 6
// Link to One Wire
OneWire oneWire(ONE_WIRE_BUS); 
// Link temp sensor to One Wire bus
DallasTemperature dallasTemp(&oneWire);

//Let's pretend it was calibrated; Temp reading at 0C
#define T0 1.06

void setup() {
  // Initialize the dallas temp sensor
  dallasTemp.begin();
  Serial.begin(9600);
}

void loop() {

  // Get the dallas temperature data
  dallasTemp.requestTemperatures();
  float tempRaw= dallasTemp.getTempCByIndex(0);
  Serial.print("tempRaw: "); Serial.println(tempRaw,2);

  float tempCorr = tempRaw - T0; //single point calibration correction
  Serial.print("dallasTemp: "); Serial.println(tempCorr,2);
  delay(1000);

 
}
