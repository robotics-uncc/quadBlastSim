% --- Optimization Complete ---
% Fixed d0:         8.6602 m
% Optimized W:      17.2383 kg
% Optimized t0:     0.024056 s
% Optimized phiB:   389.5100 deg
% Optimized thetaB: -134.7500 deg

% Clear things for a clean simulation
clc; clf; clear all; close all;

% --- Select Corvid Dataset ---
corvidFilename = 'corvidData/near.txt'; % Update to 'near.txt', 'mid.txt', or 'far.txt'
T = readtable(corvidFilename);

% Simulation parameters
simTime = 0.1;
sampleTime = 0.0001;

% Blast parameters - corvid sim
% thetaB = -135;     % Elevation (deg)
% phiB = 125.26;     % Azimuth (deg)
% W = 2.5;           % Explosive mass (kg)
% d0 = 8.66025;      % Standoff distance from blast (m)
W = 4.98952;         % Explosive mass (kg) - 11 lbs of tnt
d0 = 8.66025;        % Standoff distance from blast (m)

% Optimized W:  2.5000 kg
% Optimized t0: 0.024056 s

% W = 17.2383;
t0 = 0.024056;
thetaB = -134.7500;     % Elevation (deg)
phiB = 389.5100;     % Azimuth (deg)

% Vehicle parameters
rBody = 0.55/4; 
rMotors = 0.022; 
L = 0.55/2; 
motorRPM = 5000; 
mBody = 800/1000;
mMotor = 55/1000;
mArm = ((1282/1000)-(mBody-(mMotor*4)))/4;

% Directory information
addpath('subroutines/')
mainFigDirName = append('d0_phi', string(phiB), '_theta', string(thetaB));
if ~exist(mainFigDirName, 'dir')
    mkdir(mainFigDirName)
end

% Load the common constants for the sim
generalParams;

% Get the values from the simulated model
tic
disp('Running simulation for comparison...');
out = sim(mdl);
toc

% Setup simulation plotting variables
pltSetup;

% --- Plot Sim vs Corvid Data ---
compFig = figure('Name', 'Sim vs Corvid Data', 'Color', 'w', 'Units', 'inches', 'Position', [0 0 16 10]);

% Extract Corvid time
cTime = T.Time;

% Subplot 1: Axial Force (Sim X vs Corvid FA)
subplot(3,2,1); hold on; grid on;
plot(t, blastFx, 'b', 'LineWidth', 1.5);
plot(cTime, T.FA, 'r--', 'LineWidth', 1.5);
ylabel('Axial Force (N)'); xlabel('Time (s)');
legend('Sim $F_x$', 'Corvid FA', 'Interpreter', 'latex');
title('Axial Force Comparison', 'Interpreter', 'latex');

% Subplot 2: Side Force (Sim Y vs Corvid FS)
subplot(3,2,3); hold on; grid on;
plot(t, blastFy, 'b', 'LineWidth', 1.5);
plot(cTime, T.FS, 'r--', 'LineWidth', 1.5);
ylabel('Side Force (N)'); xlabel('Time (s)');
legend('Sim $F_y$', 'Corvid FS', 'Interpreter', 'latex');
title('Side Force Comparison', 'Interpreter', 'latex');

% Subplot 3: Normal Force (Sim Z vs Corvid FN)
subplot(3,2,5); hold on; grid on;
plot(t, blastFz, 'b', 'LineWidth', 1.5);
plot(cTime, T.FN, 'r--', 'LineWidth', 1.5);
ylabel('Normal Force (N)'); xlabel('Time (s)');
legend('Sim $F_z$', 'Corvid FN', 'Interpreter', 'latex');
title('Normal Force Comparison', 'Interpreter', 'latex');

% Subplot 4: Roll Moment (Sim X vs Corvid M_roll)
subplot(3,2,2); hold on; grid on;
plot(t, blastMx, 'b', 'LineWidth', 1.5);
plot(cTime, T.M_roll, 'r--', 'LineWidth', 1.5);
ylabel('Roll Moment (Nm)'); xlabel('Time (s)');
legend('Sim $M_x$', 'Corvid $M_{roll}$', 'Interpreter', 'latex');
title('Roll Moment Comparison', 'Interpreter', 'latex');

% Subplot 5: Pitch Moment (Sim Y vs Corvid M_pitch)
subplot(3,2,4); hold on; grid on;
plot(t, blastMy, 'b', 'LineWidth', 1.5);
plot(cTime, T.M_pitch, 'r--', 'LineWidth', 1.5);
ylabel('Pitch Moment (Nm)'); xlabel('Time (s)');
legend('Sim $M_y$', 'Corvid $M_{pitch}$', 'Interpreter', 'latex');
title('Pitch Moment Comparison', 'Interpreter', 'latex');

% Subplot 6: Yaw Moment (Sim Z vs Corvid M_yaw)
subplot(3,2,6); hold on; grid on;
plot(t, blastMz, 'b', 'LineWidth', 1.5);
plot(cTime, T.M_yaw, 'r--', 'LineWidth', 1.5);
ylabel('Yaw Moment (Nm)'); xlabel('Time (s)');
legend('Sim $M_z$', 'Corvid $M_{yaw}$', 'Interpreter', 'latex');
title('Yaw Moment Comparison', 'Interpreter', 'latex');

saveas(gcf, fullfile(figDir, 'Sim_vs_Corvid.png'));