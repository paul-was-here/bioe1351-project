void setup() {
  Serial.begin(115200);
}

void loop() {
  int fs = 100;
  int sensor1 = analogRead(A0);
  int sensor2 = analogRead(A1);
  float delay_time = 1000/fs;

  Serial.print(sensor1);
  Serial.print(",");
  Serial.println(sensor2);

  delay(delay_time);
}