# PantheRun: The Great Space Escape!

## Description
PantheRun aims to gamify the running workout experience by using the user's physiological state to control a game experience. The game rewards good user performance in two branches: cardiovascular and biomechanical:  
**Cardiovascular:** Time-series PPG data is used to evaluate cardiovascular performance with respect to the user's target workout zone. Both over- and under-exertion are punished by the game, encouraging performance and pacing.  
**Biomechanical:** Accelerometry data is processed and used to evaluate the user's biomechanical performance. Adherence to good running practices helps the user avoid injury, run more efficiently, and is ultimately rewarded by the game experience.  
This combination of metrics is processed in real-time by a number of non-linear transformations, and the dimension is reduced by projection onto a game control space. All parameters, including the user's desired targets, along with transformation functions and coefficients are editable within the app or the code respectively.  

## Use Instructions & Pin Connections
**Hardware:**  
The PantheRun system is built on real-time data acquisition and 'online' processing via the use of a National Instruments DAQ device. Additionally, a second data stream from an Arduino device provides an I2C interface for a PPG breakout board.

**Pinout:**  
<img width="1987" height="932" alt="Scheme-it-export-1351-RunTrainer-Pinout-2025-12-07-13-36" src="https://github.com/user-attachments/assets/0b7bb310-84d9-412e-99f3-ac2ce94d07d9" />

**Required Libraries:**  
[MAX3010x Library by SparkFun](https://github.com/sparkfun/SparkFun_MAX3010x_Sensor_Library/tree/master) is required to interface with the PPG breakout board via I2C.  
[MATLAB Signal Processing Toolbox](https://www.mathworks.com/products/signal.html)  
[MATLAB Data Acquisition Toolbox](https://www.mathworks.com/products/data-acquisition.html)  
[Data Acquisition Toolbox Support Package for National Instruments NI-DAQmx Devices](https://www.mathworks.com/matlabcentral/fileexchange/45086-data-acquisition-toolbox-support-package-for-national-instruments-ni-daqmx-devices)  

**Running the App:**  
1. [Download](https://github.com/paul-was-here/bioe1351-project/archive/refs/heads/main.zip) the main branch from this GitHub repository.
2. Download and install required libraries (above).
3. Extract the downloaded .zip file and run BIOENG_2351_Project.mlapp from within.  


### BIOENG 1351/2351: Biosignal Acquisition & Analysis  
Authors: Paul Kullmann, Domenic Rivetti, Emily Heyman, & Rishi Raturi  
Professor: Dr Helen Schwerdt
