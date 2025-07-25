
# Supplemental Code

The simulink file and matlab scripts in this repository act as a supplement to the paper "A Quadrotor Dynamic Model in Response to an Explosive Blast."

#### Description of code

##### UAVSim.slx: Main Simulink file.  Contains models for the blast wave, drag, gravity, and thrust forces/moments. Includes a UAV animation block to help visualize the motion of the vehicle. The inputs are listed below, with brief descriptions.

The following are set in main.m:
* simTime: Controls amount of time the simulation runs.
* sampleTime: Controls the sample time for the simulation.
* phiB: Elevation angle of blast (deg).
* thetaB: Azimuthal angle of blast (deg).
* W: Explosive mass of blast (kg).
* d0: Standoff distance of blast (m).
* rBody: Radius of body sphere (m).
* rMotors: Radius of motor spheres (m).
* L: Length of arms (m).
* motorRPM: Set rpm for vehicle motors.
* mBody: Mass of body sphere (kg).
* mMotor: Mass of motor sphere (kg).
* mArm: Mass of arms (kg).

##### General matlab scripts:

* main.m: Run this script to run the simulation and plot the state/force results.  Pause it on line 39 and open the simulink file to set all necessary variables for the model.
* savePlot.m: Function to save plots in a desired directory
* statesOverTimeFig.m: Script to plot states and forces over time
* pltSetup.m: Unpack output from the simulation
* generalParams.m: Calculate and pack variables for the simulation
