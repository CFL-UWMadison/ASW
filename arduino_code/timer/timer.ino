
//Timer
#define DONEPIN 11

void setup() {
  // Configure the done pin
  pinMode(DONEPIN,OUTPUT); 
  digitalWrite(DONEPIN,LOW);
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
  //Shut it down
  digitalWrite(DONEPIN,HIGH);
}
