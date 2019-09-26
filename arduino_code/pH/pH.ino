
// pH analog pin
#define pHpin A3
// Calibration results - values from 10-bit ADC 
#define pH4 620
#define pH7 429

void setup() {
  Serial.begin(9600);
}

void loop() {

  // Get the pH ADC output from A5 (pHpin)
  float pHread = analogRead(pHpin); //0-1024 digital
  Serial.print("pH Read: "); Serial.println(pHread);

  // Convert ADC output to corrected pH using two-point calibration results
  //corr =  (((rawValue-rawLow)*referenceRange)/(rawRange)) + referenceLow
  //where referenceRange = -3 and rawRange= pH4-pH7
  float pHcorr = (((pHread-pH7)*(-3))/(pH4-pH7)) + 7;
  Serial.print("pHcorr: "); Serial.println(pHcorr,2);
  delay(2000);
 
}
