void setup() {
  Serial.begin(9600);
}

void loop() {
  int sensor1 = analogRead(A0);
  int sensor2 = analogRead(A1);

  // send the two values separated by a comma
  Serial.print(sensor1);
  Serial.print(",");
  Serial.println(sensor2);

  delay(1); // small delay to keep things readable
}