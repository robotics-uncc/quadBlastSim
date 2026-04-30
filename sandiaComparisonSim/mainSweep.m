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
% Wrange = linspace(0.05,1,n); % Explosive mass (kg)
% d0range = linspace(1,5,n); % Standoff distance from blast (m)
% Wrange = 0.375;
% d0range = 0.170097;
Wrange = [0.226796
0.056699
0.453592
0.056699
0.226796
0.226796
0.226796
0.453592
0.170097
0.907184
0.30844256
0.170097]';
d0range=[2.7432
2.7432
2.7432
1.2192
1.2192
1.2192
2.7432
2.7432
1.2192
1.8288
3.048
1.2192]';

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
% peakPressure = zeros(n, n);
% peakImpulse = zeros(n, n);
% peakPressure = zeros(size(Wrange));
% peakImpulse = zeros(size(Wrange));
peakPressure = zeros(numel(Wrange),1);
peakImpulse = zeros(numel(Wrange),1);

% Setup waitbar
% totalRuns = numel(Wrange) * numel(d0range);
% runCounter = 0;
% h = waitbar(0, 'Running parameter sweep...');

totalRuntime = 0;

for kk = 1:numel(Wrange)
    iterTimer = tic;

    % Select sim parameters
    W = Wrange(kk) * c42tnt;
    d0 = d0range(kk);

    % Blast parameters -- left of the quad
    phiB = 90;
    thetaB = 90;

    % Setup data directory
    mainFigDirName = append('d0_', string(d0), '_phi_', string(phiB), ...
                            '_theta_', string(thetaB), '_mass_', string(W), 'kg');
    mkdir(mainFigDirName)

    % Load common constants
    generalParams;

    % Run simulation
    out = sim(mdl);

    % Plotting scripts
    pltSetup;
    statesOverTimeFig;
    clf; close all;

    % Calculate total pressure and impulse
    totalPressure = bodyPressures + motor1Pressures + motor2Pressures + motor3Pressures + motor4Pressures;
    totalImpulse = impulseBody + impulseMotor1 + impulseMotor2 + impulseMotor3 + impulseMotor4;

    % Store results
    peakPressure(kk) = max(totalPressure(:));
    peakImpulse(kk)  = max(totalImpulse(:));

    % Update runtime
    totalRuntime = totalRuntime + toc(iterTimer);

    % Optional cleanup
    clearvars -except simTime c42tnt n Wrange d0range sampleTime m rBody rMotors L Iquad peakPressure peakImpulse totalRuntime kk

    fprintf('Finished k = %d of %d\n', kk, numel(Wrange));
end

scaleFactor = 1/2.880991328;
T = table(Wrange(:), d0range(:), peakPressure(:)*scaleFactor, peakImpulse(:)*scaleFactor, ...
    'VariableNames', {'Wrange','d0range','peakPressure','peakImpulse'});
writetable(T, 'outputDataSandiaComp-scaled.csv')

% % Loop through the simulation parameters
% totalRuntime = 0;
% % for iii = 1:width(Wrange)
% %     for jjj = 1:width(d0range)
% for k = 1:numel(Wrange)
%     tic
%     % Update progress bar
%     % runCounter = runCounter + 1;
%     % h = waitbar(0, 'Running parameter sweep...');
%     % waitbar(runCounter/totalRuns, h, ...
%     % sprintf('Running %d of %d simulations...', runCounter, totalRuns));
% 
%     % Select sim parameters
%     W = Wrange(k)*c42tnt;
%     d0 = d0range(k);
%     % sprintf('Doing run W = %f and d0 = %f',W,d0)
% 
%     % Blast parameters -- left of the quad
%     phiB = 90;      % Elevation (deg)
%     thetaB = 90;   % Azimuth (deg)
% 
%     % Setup data directory
%     mainFigDirName = append('d0_', string(d0), '_phi_', string(phiB), '_theta_', string(thetaB), '_mass_', string(W), 'kg');
%     mkdir(mainFigDirName)
% 
%     % Load the common constants for the sim (vehicle params, control constants, etc)
%     generalParams;
% 
%     % Get the values from the simulated model
%     % tic
%     out = sim(mdl);
%     % toc
% 
%     % Plotting scripts
%     pltSetup;
%     statesOverTimeFig;
%     clf;close all;
% 
%     % Calculate total pressure and impulse
%     totalPressure = bodyPressures + motor1Pressures + motor2Pressures + motor3Pressures + motor4Pressures;
%     totalImpulse = impulseBody + impulseMotor1 + impulseMotor2 + impulseMotor3 + impulseMotor4;
% 
%     % Store the data
%     peakPressure(k) = max(totalPressure(:));
%     peakImpulse(k) = max(totalImpulse(:));
% 
%     % Clean up for the next iteration
%     clearvars -except simTime c42tnt n Wrange d0range sampleTime m rBody rMotors L Iquad peakPressure peakImpulse totalRuntime k
% 
%     % Update total runtime
%     totalRuntime = totalRuntime + toc;
% 
%     %% Make a plot of all of the forces over time for the simulation
%     % thisFig = figure(654);
%     % set(thisFig,'Color','w','Units','inches','Position',[0 0 8 4.5])
%     % set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
% 
%     % Make a matrix of all plotted variables
%     % plot(t*1000,bodyPressures(1,:),'DisplayName','BP','LineWidth',lw)
%     % hold on
%     % grid on
%     % plot(t*1000,motor1Pressures(1,:),'DisplayName','M1','LineWidth',lw)
%     % plot(t*1000,motor2Pressures(1,:),'DisplayName','M2','LineWidth',lw)
%     % plot(t*1000,motor3Pressures(1,:),'DisplayName','M3','LineWidth',lw)
%     % plot(t*1000,motor4Pressures(1,:),'DisplayName','M4','LineWidth',lw)
%     % plot(t*1000,totalPressure(1,:),'DisplayName','M4','LineWidth',lw)
%     % xlabel("Time (ms)")
%     % ylabel("Ps (kPa)")
% end
% % end
% 
% T = table(Wrange(:), d0range(:), peakPressure(:), peakImpulse(:), ...
%     'VariableNames', {'Wrange','d0range','peakPressure','peakImpulse'});
% writetable(T, 'outputDataSandiaComp.csv')

% Wrange = 0.375;
% d0range = 0.170097;

% % Print out total runtime of sweep
% totalRuntime = seconds(totalRuntime); 
% totalRuntime.Format = 'hh:mm:ss';
% sprintf('Total runtime of the parameter sweep: %s (h:m:s)\n', string(totalRuntime));
% 
% % Prepare plotting variables
% [Wq, d0q] = ndgrid(Wrange, d0range);
% 
% % Plot parameter sweep results for comparison to the table 1 plots
% plotMeshgrid(Wq, d0q, peakPressure, ...
%     "chargeVsDistanceVsPeakpressure.png", ...
%     ["Charge (kg c4)", "Distance from UAV (m)", "Peak Pressure (Pa)"])
% plotMeshgrid(Wq, d0q, peakImpulse, ...
%     "chargeVsDistanceVsPeakimpulse.png", ...
%     ["Charge (kg c4)", "Distance from UAV (m)", "Peak Impulse (Pa-s)"])
% plotMeshgrid(Wq, peakPressure, peakImpulse, ...
%     "chargeVsPeakpressureVsPeakImpulse.png", ...
%     ["Charge (kg c4)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
% plotMeshgrid(d0q, peakPressure, peakImpulse, ...
%     "distanceVsPeakpressureVsPeakImpulse.png", ...
%     ["Distance (m)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
% 
% % Save the data to a mat file for later
% save('sandiaCompSweep.mat','Wrange', 'd0range', 'peakPressure', 'peakImpulse');