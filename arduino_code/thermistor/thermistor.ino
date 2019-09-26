
//set analog pin
#define thermPin A5

void setup() {
}

void loop() {

  //get the value from the ADC (0-1023)
  int thermADC = analogRead(thermPin);
  //calc thermister R
  float rTherm = 10000.*thermADC/(1023. - thermADC);
  //calc inverted T in Kelvin
  float Tinv = (1/298.15) + (1/3950.)*log(rTherm/10000.);
  //convert the centigrade
  float thermTemp = (1/Tinv) - 273.15;
 
}
