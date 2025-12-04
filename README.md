# PantheRun: The Great Space Escape!

## Description
PantheRun aims to gamify the running workout experience by using the user's physiological state to control a game experience. The game rewards good user performance in two branches: cardiovascular and biomechanical:
**Cardiovascular:** Time-series PPG data is used to evaluate cardiovascular performance with respect to the user's target workout zone. Both over- and under-exertion are punished by the game, encouraging performance and pacing.
**Biomechanical:** Accelerometry data is processed and used to evaluate the user's biomechanical performance. Adherence to good running practices helps the user avoid injury, run more efficiently, and is ultimately rewarded by the game experience.

This combination of metrics is processed in real-time by a number of non-linear transformations, and the dimension is reduced by projection onto a game control space. All parameters, including the user's desired targets, along with transformation functions and coefficients are editable within the app or the code respectively.

## Use Instructions & Pin Connections
1. Navigate to the /build/ directory and download all contents. Supporting scripts and assets are located in the same directory.
2. Navigate to /build/arduino_setup/ and upload the sketch to the connected Arduino device.
3. Run BIOENG_2351_Project.mlapp

Other directories within the repository hold old builds or development tools.


### BIOENG 1351/2351: Biosignal Acquisition & Analysis
Authors: Paul Kullmann, Domenic Rivetti, Emily Heyman, & Rishi Raturi
Professor: Dr Helen Schwerdt
