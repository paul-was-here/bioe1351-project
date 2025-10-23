#include <Wire.h>
#include "MAX30105.h"

MAX30105 particleSensor;

void setup() {
  Serial.begin(115200);
  Serial.println("MAX30102 + IR-based Vibration Control");

  // Initialize MAX30102
  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("MAX30102 not found. Check wiring.");
    while (1);
  }

  // Configure sensor
  particleSensor.setup(); // Default config: 50Hz sampling
  particleSensor.setPulseAmplitudeRed(0x0A);    // Low brightness red
  particleSensor.setPulseAmplitudeIR(0x0F);     // Medium brightness IR
  particleSensor.setPulseAmplitudeGreen(0);     // Green off
}

void loop() {
  long irValue = particleSensor.getIR();

  // Print IR value for plotting/debugging
  Serial.println(irValue);

  delay(20); // 50Hz sample rate
}
