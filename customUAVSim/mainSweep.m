% mainSweep.m
% Clear things for a clean simulation
clc; clf; clear all; close all;

% If you have stack trace errors, uncomment the following line:
% load_sl_glibc_patch 

% Simulation parameters
simTime = 0.1;
sampleTime = 0.0001;

% Fixed Vehicle & Blast properties from the specifications
rBody = 0.05;    % r = 0.05 m
rMotors = 0.05;  % R = 0.05 m
L = 0.15;        % Arm length (m)
mBody = 1;       % Body mass (kg)
mMotor = 0.2;    % Motor mass (kg)
mArm = 0.05;     % Arm mass (kg)
motorRPM = 5000; % Hover thrust

% Sweep parameters based on the paper excerpt
d0_vec = [2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20]; % Distances (m)
alpha_i_vec = 1:7;                              % Blast angle indices

% Create Meshgrid for the sweep
[alphaMesh, d0Mesh] = meshgrid(alpha_i_vec, d0_vec);

% Setup variables for contourStates.m (12 subplots matching the 3x4 grid)
nSubplots = 12;
states = cell(1, nSubplots);
for k = 1:nSubplots
    states{k} = zeros(size(alphaMesh));
end

% Preallocate time-series data storage for the other scripts
timeSeriesData = cell(size(alphaMesh));

% Directory information
addpath('subroutines/')
paramSweepFigDir = 'sweepResults/';
if ~exist(paramSweepFigDir, 'dir')
    mkdir(paramSweepFigDir);
end

% Labels for the 3x4 grid in contourStates.m
plotLabs = ["$\Delta X$ (m)", "$\dot{X}$ (m/s)", "$\theta$ (deg)", "$p$ (deg/s)", ...
            "$\Delta Y$ (m)", "$\dot{Y}$ (m/s)", "$\phi$ (deg)", "$q$ (deg/s)", ...
            "$\Delta Z$ (m)", "$\dot{Z}$ (m/s)", "$\psi$ (deg)", "$r$ (deg/s)"];

titleLabs = ["\Delta X", "\dot{X}", "\theta", "p", ...
             "\Delta Y", "\dot{Y}", "\phi", "q", ...
             "\Delta Z", "\dot{Z}", "\psi", "r"];

tic
for rowIdx = 1:size(alphaMesh, 1)
    for colIdx = 1:size(alphaMesh, 2)
        
        % =======================================================
        % Restore ALL constants that get overwritten by pltSetup.m
        % =======================================================
        W = 10;          % Explosive mass (Overwritten by Body Z velocity)
        L = 0.15;        % Arm length (Overwritten by 3x3 Euler matrix)
        
        rBody = 0.05;    
        rMotors = 0.05;  
        mBody = 1;       
        mMotor = 0.2;    
        mArm = 0.05;     
        motorRPM = 5000; 
        % =======================================================
        
        % Current sweep variables
        d0 = d0Mesh(rowIdx, colIdx);
        i_val = alphaMesh(rowIdx, colIdx);
        
        % Calculate Blast Angles for this alpha_i
        thetaB = 90 - 30 * (i_val - 1);
        phiB = 150 - 30 * (i_val - 1);

        % Update directory dynamically
        mainFigDirName = sprintf('d0_%.1f_alpha_%d', d0, i_val);
        if ~exist(mainFigDirName, 'dir')
            mkdir(mainFigDirName);
        end
        
        % Load common constants (calculates IC, sets up model)
        generalParams;
        
        % Run the simulation
        fprintf('Running Sim: d0 = %.1f m, alpha_i = %d (theta: %d, phi: %d)\n', d0, i_val, thetaB, phiB);
        out = sim(mdl);
        
        % Run the user's plotting/extraction script
        pltSetup; 
        
        % Get time series data for the 12 plotted states
        % Note: \Delta X = X - IC(1), etc.
        deltaX = X - IC(1);
        deltaY = Y - IC(2);
        deltaZ = Z - IC(3);
        
        allVars = [deltaX, XDot, rad2deg(theta), rad2deg(p), ...
                   deltaY, YDot, rad2deg(phi),   rad2deg(q), ...
                   deltaZ, ZDot, rad2deg(psi),   rad2deg(r)];
               
        % Save time series data for secondary plotting scripts
        ts = struct();
        ts.t = t;
        ts.vars = allVars;
        timeSeriesData{rowIdx, colIdx} = ts;
        
        % Extract TERMINAL states for the contour plot grid
        for k = 1:nSubplots
            states{k}(rowIdx, colIdx) = allVars(end, k);
        end
    end
end
toc

% Save data for the plotting scripts
save(fullfile(paramSweepFigDir, 'sweepDataWorkspace.mat'), 'alphaMesh', 'd0Mesh', 'alpha_i_vec', 'd0_vec', ...
     'timeSeriesData', 'plotLabs', 'titleLabs');

% Map variables so contourStates.m plots alpha on X-axis and d0 on Y-axis
angleMesh = alphaMesh;   
dMesh = d0Mesh;
angMesh = alpha_i_vec;     
d0Range = d0_vec;    

% Call the original contour script
contourStates;

% Make the other plots
plotAllTimeSeries;
plotSelectedTimeSeries;