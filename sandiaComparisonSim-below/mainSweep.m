% Clear things for a clean simulation
clc;clf;clear all;close all;

% If you have either of the following stack trace errors, uncomment the follwoing line
% (https://www.mathworks.com/support/bugreports/2632298?status=SUCCESS)
%      - _dl_allocate_tls_init+00000075 at /lib64/ld-linux-x86-64.so
%      - Inconsistency detected by ld.so: ../elf/dl-tls.c: 517: _dl_allocate_tls_init: Assertion `listp != NULL' failed!
% load_sl_glibc_patch % <--- uncomment this line

% Simulation parameters
simTime = 0.04; % Changed from 0.1
sampleTime = 0.0001;

% Simulation parameter ranges - based SI converted range from Sandia paper table 1
c42tnt = 1/1.34; % https://en.wikipedia.org/wiki/TNT_equivalent
n = 20;
Wrange = linspace(0.05,1,n); % Explosive mass (kg)
d0range = linspace(1,5,n); % Standoff distance from blast (m)

% Vehicle parameters -- rough size from solidworks model and phantom 4 documentation
m = 1.388; % https://www.dji.com/support/product/phantom-4-pro -- listed mass
rBody = 0.0935; % rough size from solidworks
rMotors = 0.014; % rough size from solidworks
L = 0.35/2; % https://www.dji.com/support/product/phantom-4-pro -- half of wheelbase
Iquad = [0.009942,   0.000063,   -0.000016,
	     0.000063,   0.013965,   -0.000309,
	     -0.000016,  -0.000309,  0.009599];

% Directory information
addpath('subroutines/')

% Initialize plotting variables for comparison
peakPressure = zeros(n, n);
peakImpulse = zeros(n, n);

% Setup waitbar
% totalRuns = numel(Wrange) * numel(d0range);
% runCounter = 0;
% h = waitbar(0, 'Running parameter sweep...');

% Loop through the simulation parameters
warning('off','MATLAB:MKDIR:DirectoryExists')
totalRuntime = 0;
for iii = 1:width(Wrange)
    for jjj = 1:width(d0range)
        tic
        % Update progress bar
        % runCounter = runCounter + 1;
        % h = waitbar(0, 'Running parameter sweep...');
        % waitbar(runCounter/totalRuns, h, ...
        % sprintf('Running %d of %d simulations...', runCounter, totalRuns));

        % Select sim parameters
        W = Wrange(iii)*c42tnt;
        d0 = d0range(jjj);
        % sprintf('Doing run W = %f and d0 = %f',W,d0)

        % Blast parameters -- below quad
        phiB = 180;   % Elevation (deg)
        thetaB = 0;   % Azimuth (deg)

        % Setup data directory
        mainFigDirName = append('d0_phi', string(phiB), '_theta', string(thetaB), '_mass', string(W), 'kg');
        mkdir(mainFigDirName)
        
        % Load the common constants for the sim (vehicle params, control constants, etc)
        generalParams;
        
        % Get the values from the simulated model
        % tic
        out = sim(mdl);
        % toc
        
        % Plotting scripts
        pltSetup;
        statesOverTimeFig;
        clf;close all;

        % Calculate total pressure and impulse
        totalPressure = bodyPressures + motor1Pressures + motor2Pressures + motor3Pressures + motor4Pressures;
        totalImpulse = impulseBody + impulseMotor1 + impulseMotor2 + impulseMotor3 + impulseMotor4;

        % Store the data
        peakPressure(iii,jjj) = max(totalPressure(:));
        peakImpulse(iii,jjj) = max(totalImpulse(:));
        
        % Clean up for the next iteration
        clearvars -except simTime c42tnt n Wrange d0range phiB thetaB m rBody rMotors L Iquad peakPressure peakImpulse totalRuns runCounter iii jjj h sampleTime totalRuntime

        % Update total runtime
        totalRuntime = totalRuntime + toc;
    end
end

% Print out total runtime of sweep
totalRuntime = seconds(totalRuntime); 
totalRuntime.Format = 'hh:mm:ss';
sprintf('Total runtime of the parameter sweep: %s (h:m:s)\n', string(totalRuntime));

% Prepare plotting variables
[Wq, d0q] = ndgrid(Wrange, d0range);

% Plot parameter sweep results for comparison to the table 1 plots
plotMeshgrid(Wq, d0q, peakPressure, ...
    "chargeVsDistanceVsPeakpressure.png", ...
    ["Charge (kg c4)", "Distance from UAV (m)", "Peak Pressure (Pa)"])
plotMeshgrid(Wq, d0q, peakImpulse, ...
    "chargeVsDistanceVsPeakimpulse.png", ...
    ["Charge (kg c4)", "Distance from UAV (m)", "Peak Impulse (Pa-s)"])
plotMeshgrid(Wq, peakPressure, peakImpulse, ...
    "chargeVsPeakpressureVsPeakImpulse.png", ...
    ["Charge (kg c4)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
plotMeshgrid(d0q, peakPressure, peakImpulse, ...
    "distanceVsPeakpressureVsPeakImpulse.png", ...
    ["Distance (m)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])

% Save the data to a mat file for later
save('sandiaCompSweep.mat','Wrange', 'd0range', 'peakPressure', 'peakImpulse');
