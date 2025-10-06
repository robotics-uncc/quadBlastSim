% Clear things for a clean simulation
clc;clf;clear all;close all;

% If you have either of the following stack trace errors, uncomment the follwoing line
% (https://www.mathworks.com/support/bugreports/2632298?status=SUCCESS)
%      - _dl_allocate_tls_init+00000075 at /lib64/ld-linux-x86-64.so
%      - Inconsistency detected by ld.so: ../elf/dl-tls.c: 517: _dl_allocate_tls_init: Assertion `listp != NULL' failed!
% load_sl_glibc_patch % <--- uncomment this line

% Simulation parameters
simTime = 0.1;
sampleTime = 0.0001;

% Blast parameters
stepAng = 30;
angles = [150:-stepAng:-30; 90:-stepAng:-90];
% phiB = 150;    % Elevation (deg)
% thetaB = 90;   % Azimuth (deg)
W = 10;        % Explosive mass (kg)
d0 = 2.5;      % Standoff distance from blast (m)

% Vehicle parameters
rBody = 0.05;
rMotors = 0.05;
L = 0.15;
motorRPM = 5000; % 0 = no thrust, 5000 = hover thrust, 10000 = max thrust
mBody = 1;
mMotor = 0.2;
mArm = 0.05;

for i = 1:width()
    % Unpack angles
    phiB = angles(1,i);    % Elevation (deg)
    thetaB = angles(2,i);   % Azimuth (deg)

    % Directory information
    addpath('subroutines/')
    mainFigDirName = append('d0_phi', string(phiB), '_theta', string(thetaB));
    mkdir(mainFigDirName)
    
    % Load the common constants for the sim (vehicle params, control constants, etc)
    generalParams;
    
    % Get the values from the simulated model
    tic
    out = sim(mdl);
    toc
    
    % Plotting scripts
    pltSetup;
    statesOverTimeFig;
end