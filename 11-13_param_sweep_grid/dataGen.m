% mainSweep.m
% Generates sweep data for formatted_sweep.m using parallel processing
clc; clear; close all;

% If you have stack trace errors, uncomment the following line:
% load_sl_glibc_patch 

disp('Initializing workspace and physical constants...');

if isempty(gcp('nocreate'))
    parpool('Processes');
end

%% =======================================================
% 1. STATIC SIMULATION & VEHICLE PARAMETERS (Calculated Once)
% =======================================================
addpath(fullfile(pwd, '../00_subroutines/'));
% mdl = '../00_subroutines/UAVSim.slx';
mdl = 'UAVSim';
simTime = 90/1000;
sampleTime = 0.0001;

% Fixed Vehicle & Blast properties
rBody = 0.05;    
rMotors = 0.05;  
L = 0.15;        
mBody = 1;       
mMotor = 0.2;    
mArm = 0.05;     
motorRPM = 5000; 
W = 10;          % Explosive mass (kg)
c = 343;         % Value from blastfoam data fit

% General vehicle constants (Merged from generalParams.m)
beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
dQuad = (rBody*2)+(rMotors*2)+(L*2);
RMOTOR_iG = zeros(4,3);
for k = 1:height(RMOTOR_iG)
    RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
    RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
end
quadDims = [rBody, rMotors, L];
desRPM = motorRPM*ones(4,1);

% Physics Constants
g = 9.81;
m = mBody + 4*mMotor + 4*mArm;
rpm_max  = 10000;
rpm_nom = rpm_max/2; 
CT = m*g/4/rpm_nom^2; 
rho = 1.225; 
bodyA = pi*rBody^2; 
motorA = pi*rMotors^2; 
CD = 0.47;
dragConstsMotor = -1/2*rho*motorA*CD;
dragConstsBody = -1/2*rho*bodyA*CD;

% Inertia Calculations
Ibody = (2/5) * mBody * (rBody^2)*eye(3);
alpha_inertia = 2*(L+rBody)^2;
Imotors = mMotor*diag([alpha_inertia alpha_inertia 2*alpha_inertia]);
gamma = ((L^2)/6) + 2*((L/2) + rMotors)^2;
Iarms = mArm*diag([gamma gamma 2*gamma]);
Iquad = Ibody + Iarms + Imotors;

% Motor mixer 
rpm2bodyMomentRollPitch = [-L L L -L; L -L L -L]; 
CM = 0.1; 

%% =======================================================
% 2. SWEEP SETUP & PARALLEL SIMULATION PREPARATION
% =======================================================
d0_vec = [2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20]; 
alpha_i_vec = 1:7;

[alphaMesh, d0Mesh] = meshgrid(alpha_i_vec, d0_vec);
numSims = numel(alphaMesh);

% Preallocate storage for contourStates and formatted_sweep
nSubplots = 12;
timeSeriesData = cell(size(alphaMesh));
peakMetrics = struct('force', zeros(size(alphaMesh)), ...
                     'moment', zeros(size(alphaMesh)), ...
                     'impulse', zeros(size(alphaMesh)), ...
                     'runTime', zeros(size(alphaMesh)), ...
                     'angImpulse', zeros(size(alphaMesh)));

% Ensure the model is loaded into memory before building inputs
load_system(mdl);

% Preallocate an array of SimulationInput objects for parallel workers
in = repmat(Simulink.SimulationInput(mdl), 1, numSims);

disp('Configuring simulation inputs...');
for idx = 1:numSims
    d0_val = d0Mesh(idx);
    i_val = alphaMesh(idx);
    
    % Calculate exact blast angles
    thetaB_deg = 90 - 30 * (i_val - 1);
    phiB_deg = 150 - 30 * (i_val - 1);
    
    thetaB_rad = deg2rad(thetaB_deg);
    phiB_rad = deg2rad(phiB_deg);
    
    % Dynamic variables per run
    IC_val = [d0_val*sin(phiB_rad)*cos(thetaB_rad), ...
              d0_val*sin(phiB_rad)*sin(thetaB_rad), ...
              d0_val*cos(phiB_rad)];
              
    blastParams_val = [thetaB_rad, phiB_rad, c, W];
    
    % Inject dynamic variables into the specific parallel worker's workspace
    in(idx) = in(idx).setVariable('IC', IC_val);
    in(idx) = in(idx).setVariable('blastParams', blastParams_val);
end

%% =======================================================
% 3. RUN PARALLEL SIMULATIONS
% =======================================================
disp('Starting Parallel Sweep...');
tic;
% parsim automatically farms out the runs across all available CPU cores
out = parsim(in, 'ShowProgress', 'on', 'TransferBaseWorkspaceVariables', 'on');
toc;
disp('Simulations complete. Extracting data...');

%% =======================================================
% 4. DATA EXTRACTION
% =======================================================
% Loop back through the parallel output objects to extract time series
for idx = 1:numSims
    % Extract the specific iteration variables
    d0_val = d0Mesh(idx);
    
    % Safely extract data from the Simulink output object. 
    % Note: Replace 'out(idx).X' with however your model logs variables 
    % (e.g., out(idx).logsout.get('X').Values.Data) if you use signal logging.
    try
        % Dynamically find the indices just like pltSetup.m
        names = out(idx).logsout.getElementNames;
        posIdx   = find(matches(names, 'quadPos'));
        velIdx   = find(matches(names, 'quadVel'));
        eulIdx   = find(matches(names, 'quadEul'));
        omegaIdx = find(matches(names, 'quadOmega'));
        blastFIdx = find(matches(names, 'blastForces'));
        blastMIdx = find(matches(names, 'blastMoments'));
        
        % --- NEW: Add indices for wind and pressure ---
        bodyWindIdx  = find(matches(names, 'bodyWindI'));
        pressValsIdx = find(matches(names, 'pressureValues'));
        weightIdx     = find(matches(names, 'weightInertial'));
        bodyDragIFIdx = find(matches(names, 'bodyDragInertialFrame'));
        motorDragIdx  = find(matches(names, 'motorDragInertial'));
        thrustIdx     = find(matches(names, 'thrustInertial'));
        
        % Extract Time
        t_sim = out(idx).logsout{posIdx}.Values.Time;
        
        % Quad Position (Note the negative Z from pltSetup!)
        X_sim = out(idx).logsout{posIdx}.Values.Data(:,1);
        Y_sim = out(idx).logsout{posIdx}.Values.Data(:,2);
        Z_sim = -out(idx).logsout{posIdx}.Values.Data(:,3);
        
        % Quad Velocity (Note the negative ZDot from pltSetup!)
        XDot_sim = out(idx).logsout{velIdx}.Values.Data(:,1);
        YDot_sim = out(idx).logsout{velIdx}.Values.Data(:,2);
        ZDot_sim = -out(idx).logsout{velIdx}.Values.Data(:,3);
        
        % Quad Euler Angles
        phi_sim   = out(idx).logsout{eulIdx}.Values.Data(:,1);
        theta_sim = out(idx).logsout{eulIdx}.Values.Data(:,2);
        psi_sim   = out(idx).logsout{eulIdx}.Values.Data(:,3);
        
        % Quad Rotation Rates
        p_sim = out(idx).logsout{omegaIdx}.Values.Data(:,1);
        q_sim = out(idx).logsout{omegaIdx}.Values.Data(:,2);
        r_sim = out(idx).logsout{omegaIdx}.Values.Data(:,3);
        
        % Extract Blast Forces & Moments
        bFx = squeeze(out(idx).logsout{blastFIdx}.Values.Data(1,1,:));
        bFy = squeeze(out(idx).logsout{blastFIdx}.Values.Data(1,2,:));
        bFz = -squeeze(out(idx).logsout{blastFIdx}.Values.Data(1,3,:));
        
        bMx = squeeze(out(idx).logsout{blastMIdx}.Values.Data(1,1,:));
        bMy = squeeze(out(idx).logsout{blastMIdx}.Values.Data(1,2,:));
        bMz = squeeze(out(idx).logsout{blastMIdx}.Values.Data(1,3,:));
        
        % Body velocities (Wind)
        xWind = squeeze(out(idx).logsout{bodyWindIdx}.Values.Data(1,1,:));
        yWind = squeeze(out(idx).logsout{bodyWindIdx}.Values.Data(1,2,:));
        zWind = squeeze(out(idx).logsout{bodyWindIdx}.Values.Data(1,3,:));
        
        % Get pressure values over time for each sphere (Converted to kPa)
        % Data is [5 components, 100 rays, N time steps]. 
        % Collapse the 100 rays to find the maximum peak pressure per time step.
        rawPress = out(idx).logsout{pressValsIdx}.Values.Data;
        maxPress = squeeze(max(rawPress, [], 2)) / 1000; % Yields [5, N_time] array
        
        % Extract as column vectors
        pBody = maxPress(1, :)';
        pM1   = maxPress(2, :)';
        pM2   = maxPress(3, :)';
        pM3   = maxPress(4, :)';
        pM4   = maxPress(5, :)';

        % Extract Inertial Forces (Handling potential 3D vs 2D Simulink arrays)
        rawWeight   = squeeze(out(idx).logsout{weightIdx}.Values.Data);
        rawThrust   = squeeze(out(idx).logsout{thrustIdx}.Values.Data);
        rawBodyDrag = squeeze(out(idx).logsout{bodyDragIFIdx}.Values.Data);
        rawMotDrag  = out(idx).logsout{motorDragIdx}.Values.Data;
        
        % Ensure [N_time, 3] format (Fixing the transpose issue from pltSetup)
        if size(rawWeight, 2) ~= 3;   rawWeight = rawWeight';     end
        if size(rawThrust, 2) ~= 3;   rawThrust = rawThrust';     end
        if size(rawBodyDrag, 2) ~= 3; rawBodyDrag = rawBodyDrag'; end
        
        % Extract individual motor drags (similarly handling 3D arrays)
        if ndims(rawMotDrag) == 3
            m1Drag = squeeze(rawMotDrag(1,:,:))';
            m2Drag = squeeze(rawMotDrag(2,:,:))';
            m3Drag = squeeze(rawMotDrag(3,:,:))';
            m4Drag = squeeze(rawMotDrag(4,:,:))';
        else
            % Fallback if Simulink packed it differently
            m1Drag = rawMotDrag(:, 1:3);
            m2Drag = rawMotDrag(:, 4:6);
            m3Drag = rawMotDrag(:, 7:9);
            m4Drag = rawMotDrag(:, 10:12);
        end
    
        % Calculate Magnitudes
        forceMag  = sqrt(bFx.^2 + bFy.^2 + bFz.^2);
        momentMag = sqrt(bMx.^2 + bMy.^2 + bMz.^2);
    
        % Calculate Impulse (Integrate components, then take magnitude)
        impX = cumtrapz(t_sim, bFx);
        impY = cumtrapz(t_sim, bFy);
        impZ = cumtrapz(t_sim, bFz);
        impulseMag = sqrt(impX.^2 + impY.^2 + impZ.^2);

        % Calculate Angular Impulse (Integrate moments, then take magnitude)
        angImpX = cumtrapz(t_sim, bMx);
        angImpY = cumtrapz(t_sim, bMy);
        angImpZ = cumtrapz(t_sim, bMz);
        angImpulseMag = sqrt(angImpX.^2 + angImpY.^2 + angImpZ.^2);
        
    catch ME
        error('Data Extraction Failed. MATLAB says: %s', ME.message);
    end

    % Initial Conditions for this specific run to calculate Delta
    IC_val = in(idx).Variables(strcmp({in(idx).Variables.Name}, 'IC')).Value;

    % Use the true first time-step value to guarantee all deltas start at exactly 0
    deltaX = X_sim - X_sim(1);
    deltaY = Y_sim - Y_sim(1);
    deltaZ = Z_sim - Z_sim(1);
    
    % Build the combined state matrix matching your formatting script
    % SWAPPED p_sim AND q_sim so they properly align with theta and phi!
    allVars = [deltaX, XDot_sim, rad2deg(theta_sim), rad2deg(q_sim), ... % X, Xdot, Pitch, Pitch Rate
               deltaY, YDot_sim, rad2deg(phi_sim),   rad2deg(p_sim), ... % Y, Ydot, Roll,  Roll Rate
               deltaZ, ZDot_sim, rad2deg(psi_sim),   rad2deg(r_sim)];    % Z, Zdot, Yaw,   Yaw Rate
           
    % Find grid row/col
    [rowIdx, colIdx] = ind2sub(size(alphaMesh), idx);
    peakMetrics.force(rowIdx, colIdx)   = max(forceMag);
    peakMetrics.moment(rowIdx, colIdx)  = max(momentMag);
    peakMetrics.impulse(rowIdx, colIdx) = max(impulseMag);
    peakMetrics.runTime(rowIdx, colIdx) = out(idx).SimulationMetadata.TimingInfo.ExecutionElapsedWallTime;
    peakMetrics.angImpulse(rowIdx, colIdx) = max(angImpulseMag);

    
           
    % Save to cell array
    ts = struct();
    ts.t = t_sim;
    ts.vars = allVars;
    % Enforce column vectors for the newly tracked parameters
    ts.blastForces = [bFx(:), bFy(:), bFz(:)];
    ts.blastWind   = [xWind(:), yWind(:), zWind(:)];
    ts.pressures   = [pBody, pM1, pM2, pM3, pM4];
    ts.weight      = rawWeight;
    ts.thrust      = rawThrust;
    ts.bodyDrag    = rawBodyDrag;
    ts.motor1Drag  = m1Drag;
    ts.motor2Drag  = m2Drag;
    ts.motor3Drag  = m3Drag;
    ts.motor4Drag  = m4Drag;
    
    timeSeriesData{rowIdx, colIdx} = ts;
end

%% =======================================================
% 5. SAVE WORKSPACE
% =======================================================
paramSweepFigDir = 'sweepResults/';
if ~exist(paramSweepFigDir, 'dir')
    mkdir(paramSweepFigDir);
end

% Keep exact labels needed for formatted_sweep.m
plotLabs = ["$\Delta X$ (m)", "$\dot{X}$ (m/s)", "$\theta$ (deg)", "$p$ (deg/s)", ...
            "$\Delta Y$ (m)", "$\dot{Y}$ (m/s)", "$\phi$ (deg)", "$q$ (deg/s)", ...
            "$\Delta Z$ (m)", "$\dot{Z}$ (m/s)", "$\psi$ (deg)", "$r$ (deg/s)"];

titleLabs = ["\Delta X", "\dot{X}", "\theta", "p", ...
             "\Delta Y", "\dot{Y}", "\phi", "q", ...
             "\Delta Z", "\dot{Z}", "\psi", "r"];

save(fullfile(paramSweepFigDir, 'sweepDataWorkspace.mat'), 'alphaMesh', 'd0Mesh', 'alpha_i_vec', 'd0_vec', ...
     'timeSeriesData', 'plotLabs', 'titleLabs', 'peakMetrics');

disp('Data successfully formatted and saved to sweepDataWorkspace.mat!');

% figGen;