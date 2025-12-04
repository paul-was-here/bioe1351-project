/*
Author: Paul Kullmann
BIOENG 1351/2351 Project

Writes a value to an Arduino PWM pin (since Arduino can't directly write an analog voltage valye)
Run the signal through a low-pass analog filter to obtain a DC analog voltage value
*/

/*
  Optical SP02 Detection (SPK Algorithm) using the MAX30105 Breakout
  By: Nathan Seidle @ SparkFun Electronics
  Date: October 19th, 2016
  https://github.com/sparkfun/MAX30105_Breakout

  * Modifications by Paul Kullmann for BIOENG 1351/2351 Project

  Hardware Connections (Breakoutboard to Arduino):
  -5V = 5V (3.3V is allowed)
  -GND = GND
  -SDA = A4 (or SDA)
  -SCL = A5 (or SCL)
  -INT = Not connected
*/

#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"

MAX30105 particleSensor;

#define MAX_BRIGHTNESS 255

//Arduino Uno doesn't have enough SRAM to store 100 samples of IR led data and red led data in 32-bit format
//To solve this problem, 16-bit MSB of the sampled data will be truncated. Samples become 16-bit data.
uint16_t irBuffer[100]; //infrared LED sensor data
uint16_t redBuffer[100];  //red LED sensor data

int32_t bufferLength; //data length
int32_t spo2; //SPO2 value
int8_t validSPO2; //indicator to show if the SPO2 calculation is valid
int32_t heartRate; //heart rate value
int8_t validHeartRate; //indicator to show if the heart rate calculation is valid

const int outPin1 = 3;         // Must be a PWM-capable pin
const int outPin2 = 11;
// Pins A4/5 reserved for RX/TX
const float vRef = 5.0;       // Reference voltage (e.g., 5V Arduino)
float targetVoltage = 1.75;   // <<< Set target voltage (doubles it for some reason??)

byte pulseLED = 9; //Must be on PWM pin
byte readLED = 13; //Blinks with each data read

void setup()
{
  Serial.begin(115200); // initialize serial communication at 115200 bits per second:

  pinMode(pulseLED, OUTPUT);
  pinMode(readLED, OUTPUT);

  pinMode(outPin1, OUTPUT);
  pinMode(outPin2, OUTPUT);

  // Bump Timer2 (PWM pins 3&11) to 31.25kHz for PWM writing (this is specific to UNO boards)
  TCCR2B = (TCCR2B & 0b11111000) | 0x01;


  // Initialize sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) //Use default I2C port, 400kHz speed
  {
    Serial.println(F("MAX30105 was not found. Please check wiring/power."));
    while (1);
  }

  Serial.read();

  byte ledBrightness = 60; //Options: 0=Off to 255=50mA
  byte sampleAverage = 4; //Options: 1, 2, 4, 8, 16, 32
  byte ledMode = 2; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
  byte sampleRate = 400; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 411; //Options: 69, 118, 215, 411
  int adcRange = 4096; //Options: 2048, 4096, 8192, 16384

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
}

void loop()
{
  bufferLength = 100; //buffer length of 100 stores 4 seconds of samples running at 25sps

  //read the first 100 samples, and determine the signal range
  for (byte i = 0 ; i < bufferLength ; i++)
  {
    while (particleSensor.available() == false) //do we have new data?
      particleSensor.check(); //Check the sensor for new data

    redBuffer[i] = particleSensor.getRed();
    irBuffer[i] = particleSensor.getIR();
    particleSensor.nextSample();
  }

  //calculate heart rate and SpO2 after first 100 samples (first 4 seconds of samples)
  maxim_heart_rate_and_oxygen_saturation(irBuffer, bufferLength, redBuffer, &spo2, &validSPO2, &heartRate, &validHeartRate);

  //Continuously taking samples from MAX30102.  Heart rate and SpO2 are calculated every 1 second
  while (1)
  {
    // Shift old samples
    for (byte i = 25; i < 100; i++)
    {
      redBuffer[i - 25] = redBuffer[i];
      irBuffer[i - 25] = irBuffer[i];
    }

    // Take 25 new samples
    for (byte i = 75; i < 100; i++)
    {
      while (particleSensor.available() == false)
        particleSensor.check();

      digitalWrite(readLED, !digitalRead(readLED));

      redBuffer[i] = particleSensor.getRed();
      irBuffer[i] = particleSensor.getIR();
      particleSensor.nextSample();
    }

    // --- FIND min/max from the updated buffer ---
    uint16_t minPPG = 65535;
    uint16_t maxPPG = 0;

    for (int j = 0; j < bufferLength; j++) {
      if (irBuffer[j] < minPPG) minPPG = irBuffer[j];
      if (irBuffer[j] > maxPPG) maxPPG = irBuffer[j];
    }

    float minMargin = minPPG * 0.9;
    float maxMargin = maxPPG * 1.1;

    static float smoothedMin = minMargin;
    static float smoothedMax = maxMargin;
    smoothedMin = 0.9 * smoothedMin + 0.1 * minMargin;
    smoothedMax = 0.9 * smoothedMax + 0.1 * maxMargin;

    // --- Map values to PWM ---
    for (byte i = 75; i < 100; i++)
    {
      int pwmValue_ppg = ppgToPWM(irBuffer[i], smoothedMin, smoothedMax);
      int pwmValue_spo2 = spo2ToPWM(spo2);

      analogWrite(outPin1, pwmValue_ppg);
      analogWrite(outPin2, pwmValue_spo2);
    }

    // Update heart rate and SpO2
    maxim_heart_rate_and_oxygen_saturation(irBuffer, bufferLength, redBuffer,
                                          &spo2, &validSPO2, &heartRate, &validHeartRate);
  }

}

int spo2ToPWM(float spo2){
  //Serial.print("SpO2 value: ");
  //Serial.print(spo2);
  //Serial.println();
  // Discretize the spo2 value to write to the PWM pin
  if (spo2 >= 91 && spo2 <= 100){
    float digitized = spo2-90;
    int pwmValue = round((digitized/10) * 255.0);
    //Serial.print("SpO2 PWM value: ");
    //Serial.print(pwmValue);
    //Serial.println();
    return pwmValue;

  } else { // Only choose to send 91-100 SpO2 values. Would not expect anyone to have <90, or indicates bad measurement.
    //Serial.print("SpO2 returned 0");
    //Serial.println();
    return (int) 0;

  }
}

int ppgToPWM(uint16_t ppgValue, uint16_t minPPG, uint16_t maxPPG){
  //Serial.print("PPG value: ");
  //Serial.print(ppgValue);
  //Serial.println();
  // Map I2C PPG values to 8-bit PWM values

  if (ppgValue < minPPG) {
    ppgValue = minPPG;
  }
  if (ppgValue > maxPPG) {
    ppgValue = maxPPG;
  }
  int mapped_value = map(ppgValue, minPPG, maxPPG, 0, 255); 
  //Serial.print("Mapped value: ");
  //Serial.print(mapped_value);
  //Serial.println();
  return (mapped_value);
}
