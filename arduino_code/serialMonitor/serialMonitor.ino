
//declare and initialize integer variable 'count"
int count = 0;

void setup() {
  Serial.begin(57600);
}

void loop() {
  Serial.print("Count= ");
  Serial.println(count); //print the variable
  delay(1000);
  count++;  //increment by 1
}
