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

% Blast parameters -- below the quad
phiB = 90;      % Elevation (deg)
thetaB = 90;   % Azimuth (deg)
W = 10;        % Explosive mass (kg)
d0 = 2.5;      % Standoff distance from blast (m)

% Vehicle parameters -- rough size from solidworks model and phantom 4 documentation
m = 1.388; % https://www.dji.com/support/product/phantom-4-pro -- listed mass
rBody = 0.0935; % rough size from solidworks
rMotors = 0.014; % rough size from solidworks
L = 0.35/2; % https://www.dji.com/support/product/phantom-4-pro -- half of wheelbase
Iquad = [0.009942,   0.000063,    -0.000016,
	     0.000063,   0.013965,    -0.000309,
	     -0.000016,  -0.000309,  0.009599];

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