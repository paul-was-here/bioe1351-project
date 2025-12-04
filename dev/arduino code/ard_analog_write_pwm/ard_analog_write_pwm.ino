/*
Author: Paul Kullmann
BIOENG 1351/2351 Project

Writes a value to an Arduino PWM pin (since Arduino can't directly write an analog voltage valye)
Run the signal through a low-pass analog filter to obtain a DC analog voltage value
*/
const int pwmPin = 3;         // Must be a PWM-capable pin
const float vRef = 5.0;       // Reference voltage (e.g., 5V Arduino)
float targetVoltage = 1.75;   // <<< Set target voltage (doubles it for some reason??)

void setup() {
  pinMode(pwmPin, OUTPUT);

  // Bumps PWM frequency to 31kHz
  TCCR2B = (TCCR2B & 0b11111000) | 0x01;

  // Calculate duty cycle (0–255)
  int pwmValue = voltageToPWM(targetVoltage);

  // Write the PWM output
  analogWrite(pwmPin, pwmValue);
}

void loop() {
  // None
}

// Helper function
int voltageToPWM(float voltage) {
  // Keeps voltage within a the 0-5V range
  if (voltage < 0) voltage = 0;
  if (voltage > vRef) voltage = vRef;

  // Convert volts to 8-bit PWM (0–255)
  return (int) round((voltage / vRef) * 255.0);
}
