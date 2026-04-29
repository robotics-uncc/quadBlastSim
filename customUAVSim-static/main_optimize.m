% main_optimize.m
% Clear things for a clean simulation
clc; clearvars; close all;

% --- CLEANUP STALE SIMULINK CACHE ---
if exist('slprj', 'dir')
    rmdir('slprj', 's');
end
if exist('UAVSim.slxc', 'file')
    delete('UAVSim.slxc');
end

% --- Start Parallel Pool ---
poolobj = gcp('nocreate');
if ~isempty(poolobj) && ~isa(poolobj, 'parallel.ProcessPool')
    disp('Closing thread-based pool to start a process-based pool...');
    delete(poolobj);
    poolobj = [];
end
if isempty(poolobj)
    disp('Starting Process-based parallel pool. This may take a minute...');
    parpool('Processes');
end

% --- Select Target Dataset for Optimization ---
corvidFilename = 'corvidData/near.txt'; 
T = readtable(corvidFilename);

% Ensure the sim runs long enough for the blast to arrive and pass     
params.t0 = 0.024056;
params.sampleTime = 0.0001;
params.W = 4.98952;         
params.d0 = 8.66025;   
params.motorRPM = 5000;
params.c = 360; 
params.mdl = 'UAVSim';
% params.simTime = params.t0 + max(T.Time) + 0.05;
params.simTime = 0.2;

% --- DEFINE BOUNDARIES ---
% Order: [thetaB, phiB, rBody, rMotors, L, mBody, mMotor, mArm, t0]
lb_real = [-180,   0, 0.05, 0.01, 0.10, 0.20, 0.01, 0.01, 0.00];
ub_real = [ 180, 360, 0.30*3, 0.10*3, 0.50*3, 2.00*3, 0.20*3, 0.30*3, 0.1];

% Normalize parameters for the optimizer [0, 1] for stable gradients
lb_norm = zeros(1, 9);
ub_norm = ones(1, 9);

% --- Pre-calculate Logsout Indices ---
disp('Performing initialization run to cache model data and indices...');
x0_dummy = lb_real + 0.5 .* (ub_real - lb_real);

% Push dummy parameters to base workspace
pushParamsToBase(x0_dummy, params);

load_system(params.mdl);
set_param(params.mdl, 'SimulationMode', 'normal');
set_param(params.mdl, 'UnitsInconsistencyMsg', 'none');
out_dummy = sim(params.mdl, 'SimulationMode', 'normal', 'SrcWorkspace', 'base');

% Cache indices based on pltSetup.m signal names
idx.bodyDrag = find(matches(out_dummy.logsout.getElementNames, 'bodyDragInertialFrame'));
idx.motorDrag = find(matches(out_dummy.logsout.getElementNames, 'motorDragInertial'));
idx.totalM = find(matches(out_dummy.logsout.getElementNames, 'totalM')); 

% Sanity check
if isempty(idx.bodyDrag) || isempty(idx.motorDrag) || isempty(idx.totalM)
    error('Could not find drag or totalM signals in logsout. Check signal logging names!');
end

% --- Optimization Settings (Particle Swarm) ---
x0_real = [-45, 125.26, 0.1375, 0.022, 0.275, 0.8, 0.055, 0.1755, 0.024056];
x0_norm = (x0_real - lb_real) ./ (ub_real - lb_real);
options = optimoptions('particleswarm', ...
    'UseParallel', true, ...
    'Display', 'iter', ...
    'SwarmSize', 60, ...
    'MaxIterations', 1000, ...
    'FunctionTolerance', 1e-8, ...
    'InitialSwarmMatrix', x0_norm);

disp('Starting Particle Swarm Optimization...');
tic;
% Run particleswarm on normalized variables
objFun = @(x_norm) blastCostFunction(x_norm, lb_real, ub_real, T, params);
x_norm_opt = particleswarm(objFun, 9, lb_norm, ub_norm, options);
optTime = toc;

% Decode optimized parameters back to physical scales
x_opt = lb_real + x_norm_opt .* (ub_real - lb_real);

% --- Save Results to Disk ---
disp('Saving data to .mat files...');

% 1. Save the static simulation settings and environment constants
save('sim_config.mat', 'params', 'lb_real', 'ub_real');

% 2. Save the final optimized variables and the result vector
% Creating a struct for the optimized values for easier access later
optimized_results.thetaB = x_opt(1);
optimized_results.phiB   = x_opt(2);
optimized_results.rBody  = x_opt(3);
optimized_results.rMotors = x_opt(4);
optimized_results.L      = x_opt(5);
optimized_results.mBody  = x_opt(6);
optimized_results.mMotor = x_opt(7);
optimized_results.mArm   = x_opt(8);
optimized_results.t0     = x_opt(9);
optimized_results.full_vector = x_opt;
optimized_results.final_cost = x_norm_opt; % The best f(x) achieved

save('optimized_params.mat', 'optimized_results');

fprintf('Files saved: sim_config.mat and optimized_params.mat\n');

fprintf('\n--- Optimization Complete in %.2f seconds ---\n', optTime);
fprintf('Fixed W:           %.4f kg\n', params.W);
fprintf('Fixed d0:          %.4f m\n', params.d0);
fprintf('Fixed t0:          %.6f s\n\n', params.t0);
fprintf('Optimized thetaB:  %.4f deg\n', x_opt(1));
fprintf('Optimized phiB:    %.4f deg\n', x_opt(2));
fprintf('Optimized rBody:   %.4f m\n', x_opt(3));
fprintf('Optimized rMotors: %.4f m\n', x_opt(4));
fprintf('Optimized L:       %.4f m\n', x_opt(5));
fprintf('Optimized mBody:   %.4f kg\n', x_opt(6));
fprintf('Optimized mMotor:  %.4f kg\n', x_opt(7));
fprintf('Optimized mArm:    %.4f kg\n', x_opt(8));

% Decode optimized parameters back to physical scales
x_opt = lb_real + x_norm_opt .* (ub_real - lb_real);

fprintf('\n--- Optimization Complete in %.2f seconds ---\n', optTime);
% ... [Existing Print Statements] ...

%% --- Final Visualization ---
disp('Generating final comparison plots...');

% 1. Run the simulation one last time with optimal parameters
pushParamsToBase(x_opt, params);
out_final = sim(params.mdl, 'SimulationMode', 'normal', 'SrcWorkspace', 'base');

% 2. Extract Data
t_sim = out_final.logsout.get('totalM').Values.Time;

% --- Force Extraction ---
bodyDrag = squeeze(out_final.logsout.get('bodyDragInertialFrame').Values.Data)';
mDragData = out_final.logsout.get('motorDragInertial').Values.Data;
allForce = bodyDrag + squeeze(mDragData(1,:,:))' + squeeze(mDragData(2,:,:))' + ...
           squeeze(mDragData(3,:,:))' + squeeze(mDragData(4,:,:))';

simF = [allForce(:,1), allForce(:,2), -allForce(:,3)]; % Fx, Fy, Fz

% --- Moment Extraction (The Fix) ---
simM_raw = out_final.logsout.get('totalM').Values.Data;
if ndims(simM_raw) == 3
    % Converts 1x3xN or 3x1xN to Nx3
    simM = squeeze(simM_raw);
    if size(simM, 1) == 3 && size(simM, 2) ~= 3
        simM = simM'; 
    end
else
    simM = simM_raw;
end

% 3. Plotting
figure('Name', 'Optimization Results', 'Color', 'w', 'Position', [100, 100, 1200, 800]);

% --- Subplot 1: Forces ---
subplot(2,1,1);
hold on; grid on;
% Empirical (near.txt) - Shifted by optimized t0 (x_opt(9))
plot(T.Time + x_opt(9), T.FA, 'r--', 'LineWidth', 1.2);
plot(T.Time + x_opt(9), T.FS, 'g--', 'LineWidth', 1.2);
plot(T.Time + x_opt(9), T.FN, 'b--', 'LineWidth', 1.2);
% Simulated
plot(t_sim, simF(:,1), 'r-', 'LineWidth', 1.5);
plot(t_sim, simF(:,2), 'g-', 'LineWidth', 1.5);
plot(t_sim, simF(:,3), 'b-', 'LineWidth', 1.5);

title('Force Comparison (Inertial Frame)');
ylabel('Force (N)');
legend('Empirical Fx', 'Empirical Fy', 'Empirical Fz', 'Sim Fx', 'Sim Fy', 'Sim Fz', 'Location', 'bestoutside');

% --- Subplot 2: Moments (Using simM correctly) ---
subplot(2,1,2);
hold on; grid on;
% Empirical (near.txt) - Shifted by optimized t0
plot(T.Time + x_opt(9), T.M_roll,  'r--', 'LineWidth', 1.2);
plot(T.Time + x_opt(9), T.M_pitch, 'g--', 'LineWidth', 1.2);
plot(T.Time + x_opt(9), T.M_yaw,   'b--', 'LineWidth', 1.2);

% Simulated Moments from simM matrix
plot(t_sim, simM(:,1), 'r-', 'LineWidth', 1.5);
plot(t_sim, simM(:,2), 'g-', 'LineWidth', 1.5);
plot(t_sim, simM(:,3), 'b-', 'LineWidth', 1.5);

title('Moment Comparison (Body Frame)');
xlabel('Time (s)');
ylabel('Moment (N-m)');
legend('Empirical Mx', 'Empirical My', 'Empirical Mz', 'Sim Mx', 'Sim My', 'Sim Mz', 'Location', 'bestoutside');

% Align the view to the blast window
xlim([x_opt(9) - 0.005, x_opt(9) + max(T.Time) + 0.005]);

% --- Save Final Artifacts ---
exportgraphics(gcf, 'OptimizationResults.png', 'Resolution', 300);
exportgraphics(gcf, 'OptimizationResults.pdf', 'ContentType', 'vector');

% Zoom into the relevant blast window
% xlim([params.t0, params.t0 + max(T.Time)]);

%% --- Objective Function ---
function cost = blastCostFunction(x_norm, lb_real, ub_real, T, params)
    
    % Force load the model on the worker so SimulationInput doesn't crash
    if ~bdIsLoaded(params.mdl)
        load_system(params.mdl);
    end

    % Decode normalized optimization variables
    x_real = lb_real + x_norm .* (ub_real - lb_real);
    
    % Get physical variables
    thetaB_try = x_real(1);
    phiB_try   = x_real(2);
    rBody      = x_real(3);
    rMotors    = x_real(4);
    L          = x_real(5);
    mBody      = x_real(6);
    mMotor     = x_real(7);
    mArm       = x_real(8);
    t0_try     = x_real(9);

    % Convert blast orientation to radians
    phiB_rad = deg2rad(phiB_try);
    thetaB_rad = deg2rad(thetaB_try);

    % Calculate initial condition
    IC = [params.d0*sin(phiB_rad)*cos(thetaB_rad), ...
          params.d0*sin(phiB_rad)*sin(thetaB_rad), ...
          params.d0*cos(phiB_rad)];

    % blastParams = [thetaB_rad, phiB_rad, params.c, params.W, params.t0];
    blastParams = [thetaB_rad, phiB_rad, params.c, params.W, t0_try];

    % Set general vehicle constants
    beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
    dQuad = (rBody*2)+(rMotors*2)+(L*2);

    RMOTOR_iG = zeros(4,3);
    for k = 1:height(RMOTOR_iG)
        RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
        RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
    end

    quadDims = [rBody, rMotors, L];
    desRPM = params.motorRPM*ones(4,1);

    % Set mass/aerodynamic constants
    g = 9.81;
    m = mBody + 4*mMotor + 4*mArm;
    rpm_max  = 10000;
    rpm_nom = rpm_max/2; 
    CT = m*g/4/rpm_nom^2; 
    rho = 1.225; 
    bodyA = pi*rBody^2; 
    motorA = pi*rMotors^2; 
    CD = 1.17;
    dragConstsMotor = -1/2*rho*motorA*CD;
    dragConstsBody = -1/2*rho*bodyA*CD;

    % Calculate inertia
    Ibody = (2/5) * mBody * (rBody^2)*eye(3);
    alpha_val = 2*(L+rBody)^2;
    Imotors = mMotor*diag([alpha_val alpha_val 2*alpha_val]);
    gamma_val = ((L^2)/6) + 2*((L/2) + rMotors)^2;
    Iarms = mArm*diag([gamma_val gamma_val 2*gamma_val]);
    Iquad = Ibody + Iarms + Imotors;

    % Motor mixer 
    rpm2bodyMomentRollPitch = [-L L L -L; 
                               L -L L -L]; 
    CM = 0.1; 

    % --- CREATE THREAD-SAFE SIMULATION INPUT ---
    simIn = Simulink.SimulationInput(params.mdl);
    simIn = setModelParameter(simIn, 'SimulationMode', 'normal');
    simIn = setModelParameter(simIn, 'UnitsInconsistencyMsg', 'none');

    % Inject all variables directly into the object (Bypasses the Base Workspace bug)
    simIn = setVariable(simIn, 'simTime', params.simTime);
    simIn = setVariable(simIn, 'sampleTime', params.sampleTime);
    simIn = setVariable(simIn, 'IC', IC);
    simIn = setVariable(simIn, 'blastParams', blastParams);
    simIn = setVariable(simIn, 'beta', beta);
    simIn = setVariable(simIn, 'dQuad', dQuad);
    simIn = setVariable(simIn, 'RMOTOR_iG', RMOTOR_iG);
    simIn = setVariable(simIn, 'quadDims', quadDims);
    simIn = setVariable(simIn, 'desRPM', desRPM);
    simIn = setVariable(simIn, 'g', g);
    simIn = setVariable(simIn, 'm', m);
    simIn = setVariable(simIn, 'rpm_max', rpm_max);
    simIn = setVariable(simIn, 'rpm_nom', rpm_nom);
    simIn = setVariable(simIn, 'CT', CT);
    simIn = setVariable(simIn, 'rho', rho);
    simIn = setVariable(simIn, 'bodyA', bodyA);
    simIn = setVariable(simIn, 'motorA', motorA);
    simIn = setVariable(simIn, 'CD', CD);
    simIn = setVariable(simIn, 'dragConstsMotor', dragConstsMotor);
    simIn = setVariable(simIn, 'dragConstsBody', dragConstsBody);
    simIn = setVariable(simIn, 'Ibody', Ibody);
    simIn = setVariable(simIn, 'alpha', alpha_val);
    simIn = setVariable(simIn, 'Imotors', Imotors);
    simIn = setVariable(simIn, 'gamma', gamma_val);
    simIn = setVariable(simIn, 'Iarms', Iarms);
    simIn = setVariable(simIn, 'Iquad', Iquad);
    simIn = setVariable(simIn, 'rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch);
    simIn = setVariable(simIn, 'CM', CM);

    % try
    % Run the isolated simulation object
    out = sim(simIn);

    % --- SAFELY EXTRACT DATA USING .get() ---
    bDragObj = out.logsout.get('bodyDragInertialFrame');
    if iscell(bDragObj), bDragObj = bDragObj{1}; end
    bodyDrag = squeeze(bDragObj.Values.Data)';
    
    mDragObj = out.logsout.get('motorDragInertial');
    if iscell(mDragObj), mDragObj = mDragObj{1}; end
    mDragData = mDragObj.Values.Data;
    motor1Drag = squeeze(mDragData(1,:,:))';
    motor2Drag = squeeze(mDragData(2,:,:))';
    motor3Drag = squeeze(mDragData(3,:,:))';
    motor4Drag = squeeze(mDragData(4,:,:))';
    
    allForce = bodyDrag + motor1Drag + motor2Drag + motor3Drag + motor4Drag;
    simFx = allForce(:, 1);
    simFy = allForce(:, 2);
    simFz = -allForce(:, 3); 

    totMObj = out.logsout.get('totalM');
    if iscell(totMObj), totMObj = totMObj{1}; end
    t_sim = totMObj.Values.Time;
    simMx = squeeze(totMObj.Values.Data(1,1,:));
    simMy = squeeze(totMObj.Values.Data(1,2,:));
    simMz = squeeze(totMObj.Values.Data(1,3,:));

    % Find indices where the empirical data overlaps with the simulation time
    validIdx = T.Time <= params.simTime;
    % cTime = T.Time + params.t0;
    cTime = T.Time + t0_try;
    
    % Interpolate sim data onto the shifted empirical timestamps
    simFx_int = interp1(t_sim, simFx, cTime, 'linear', 'extrap');
    simFy_int = interp1(t_sim, simFy, cTime, 'linear', 'extrap');
    simFz_int = interp1(t_sim, simFz, cTime, 'linear', 'extrap');
    simMx_int = interp1(t_sim, simMx, cTime, 'linear', 'extrap');
    simMy_int = interp1(t_sim, simMy, cTime, 'linear', 'extrap');
    simMz_int = interp1(t_sim, simMz, cTime, 'linear', 'extrap');

    % Normalize errors (Added 1e-4 floor to prevent zero-division NaNs)
    eFx = sum( ((simFx_int - T.FA(validIdx)) ./ max(max(abs(T.FA(validIdx))), 1e-4)).^2 , 'omitnan');
    eFy = sum( ((simFy_int - T.FS(validIdx)) ./ max(max(abs(T.FS(validIdx))), 1e-4)).^2 , 'omitnan');
    eFz = sum( ((simFz_int - T.FN(validIdx)) ./ max(max(abs(T.FN(validIdx))), 1e-4)).^2 , 'omitnan');
    
    eMx = sum( ((simMx_int - T.M_roll(validIdx)) ./ max(max(abs(T.M_roll(validIdx))), 1e-4)).^2 , 'omitnan');
    eMy = sum( ((simMy_int - T.M_pitch(validIdx)) ./ max(max(abs(T.M_pitch(validIdx))), 1e-4)).^2 , 'omitnan');
    eMz = sum( ((simMz_int - T.M_yaw(validIdx)) ./ max(max(abs(T.M_yaw(validIdx))), 1e-4)).^2 , 'omitnan');

    % Add a heavy penalty if the drone geometry is physically impossible
    geomPenalty = 0;
    if (rBody + rMotors) >= L
        geomPenalty = 1e5 * ((rBody + rMotors) - L); 
    end
    
    cost = eFx + eFy + eFz + eMx + eMy + eMz + geomPenalty;

    % catch ME
    %     % Disp error just in case it is failing mathematically
    %     disp(['Sim failed | Error: ', ME.message]);
    %     cost = 1e9; 
    % end
end

%% --- Helper Function ---
function pushParamsToBase(x_real, params)
    % Extract physical variables
    thetaB_try = x_real(1);
    phiB_try   = x_real(2);
    rBody      = x_real(3);
    rMotors    = x_real(4);
    L          = x_real(5);
    mBody      = x_real(6);
    mMotor     = x_real(7);
    mArm       = x_real(8);

    % Convert blast orientation to radians
    phiB_rad = deg2rad(phiB_try);
    thetaB_rad = deg2rad(thetaB_try);

    % Calculate initial condition
    IC = [params.d0*sin(phiB_rad)*cos(thetaB_rad), ...
          params.d0*sin(phiB_rad)*sin(thetaB_rad), ...
          params.d0*cos(phiB_rad)];

    blastParams = [thetaB_rad, phiB_rad, params.c, params.W, params.t0];

    % Set general vehicle constants
    beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
    dQuad = (rBody*2)+(rMotors*2)+(L*2);

    RMOTOR_iG = zeros(4,3);
    for k = 1:height(RMOTOR_iG)
        RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
        RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
    end

    quadDims = [rBody, rMotors, L];
    desRPM = params.motorRPM*ones(4,1);

    % Set mass/aerodynamic constants
    g = 9.81;
    m = mBody + 4*mMotor + 4*mArm;
    rpm_max  = 10000;
    rpm_nom = rpm_max/2; 
    CT = m*g/4/rpm_nom^2; 
    rho = 1.225; 
    bodyA = pi*rBody^2; 
    motorA = pi*rMotors^2; 
    CD = 1.17;
    dragConstsMotor = -1/2*rho*motorA*CD;
    dragConstsBody = -1/2*rho*bodyA*CD;

    % Calculate inertia
    Ibody = (2/5) * mBody * (rBody^2)*eye(3);
    alpha_val = 2*(L+rBody)^2;
    Imotors = mMotor*diag([alpha_val alpha_val 2*alpha_val]);
    gamma_val = ((L^2)/6) + 2*((L/2) + rMotors)^2;
    Iarms = mArm*diag([gamma_val gamma_val 2*gamma_val]);
    Iquad = Ibody + Iarms + Imotors;

    % Motor mixer 
    rpm2bodyMomentRollPitch = [-L L L -L; 
                               L -L L -L]; 
    CM = 0.1; 

    % --- PUSH VARIABLES TO WORKER BASE WORKSPACE ---
    varsToAssign = {
        'simTime', params.simTime;
        'sampleTime', params.sampleTime;
        'IC', IC;
        'blastParams', blastParams;
        'beta', beta;
        'dQuad', dQuad;
        'RMOTOR_iG', RMOTOR_iG;
        'quadDims', quadDims;
        'desRPM', desRPM;
        'g', g;
        'm', m;
        'rpm_max', rpm_max;
        'rpm_nom', rpm_nom;
        'CT', CT;
        'rho', rho;
        'bodyA', bodyA;
        'motorA', motorA;
        'CD', CD;
        'dragConstsMotor', dragConstsMotor;
        'dragConstsBody', dragConstsBody;
        'Ibody', Ibody;
        'alpha', alpha_val;
        'Imotors', Imotors;
        'gamma', gamma_val;
        'Iarms', Iarms;
        'Iquad', Iquad;
        'rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch;
        'CM', CM
    };

    for i = 1:size(varsToAssign, 1)
        assignin('base', varsToAssign{i,1}, varsToAssign{i,2});
    end
end

% % main_optimize.m
% % Clear things for a clean simulation
% clc; clearvars; close all;
% 
% % --- CLEANUP STALE SIMULINK CACHE ---
% % We must delete the cache before parallel runs to prevent locked file errors
% if exist('slprj', 'dir')
%     disp('Deleting stale slprj cache folder...');
%     rmdir('slprj', 's');
% end
% if exist('UAVSim.slxc', 'file')
%     delete('UAVSim.slxc');
% end
% 
% % --- Start Parallel Pool ---
% poolobj = gcp('nocreate');
% if ~isempty(poolobj) && ~isa(poolobj, 'parallel.ProcessPool')
%     disp('Closing thread-based pool to start a process-based pool...');
%     delete(poolobj);
%     poolobj = [];
% end
% if isempty(poolobj)
%     disp('Starting Process-based parallel pool. This may take a minute...');
%     parpool('Processes');
% end
% 
% % --- Select Target Dataset for Optimization ---
% corvidFilename = 'corvidData/near.txt'; 
% T = readtable(corvidFilename);
% 
% % Group static baseline vehicle and simulation parameters
% params.simTime = 0.1;
% params.sampleTime = 0.0001;
% params.W = 4.98952;         
% params.d0 = 8.66025;        
% params.t0 = 0.024056;
% params.motorRPM = 5000;
% params.c = 360; 
% params.mdl = 'UAVSim';
% 
% % --- Initial Guesses ---
% % Order: [thetaB, phiB, rBody, rMotors, L, mBody, mMotor, mArm]
% thetaB0  = -134.75;
% phiB0    = 389.51;
% rBody0   = 0.55/4;      % 0.1375
% rMotors0 = 0.022;
% L0       = 0.55/2;      % 0.275
% mBody0   = 800/1000;    % 0.8
% mMotor0  = 55/1000;     % 0.055
% mArm0    = ((1282/1000)-(mBody0-(mMotor0*4)))/4; % 0.1755
% 
% x0_real = [thetaB0, phiB0, rBody0, rMotors0, L0, mBody0, mMotor0, mArm0];
% 
% % --- DEFINE BOUNDARIES ---
% lb_real = [-180,   0, 0.05, 0.01, 0.10, 0.20, 0.01, 0.01];
% ub_real = [ 180, 720, 0.30, 0.10, 0.50, 2.00, 0.20, 0.30];
% 
% % Normalize parameters for the optimizer [0, 1] for stable gradients
% x0_norm = (x0_real - lb_real) ./ (ub_real - lb_real);
% lb_norm = zeros(1, 8);
% ub_norm = ones(1, 8);
% 
% % --- Pre-calculate Logsout Indices (Massive Speedup) ---
% disp('Performing initialization run to cache model data and indices...');
% load_system(params.mdl);
% set_param(params.mdl, 'FastRestart', 'off');           % <--- ADD THIS LINE
% set_param(params.mdl, 'SimulationMode', 'accelerator');
% 
% % Push initial parameters to base workspace for the dummy run
% pushParamsToBase(x0_real, params);
% out_dummy = sim(params.mdl, 'SimulationMode', 'accelerator');
% idx.bForce = find(matches(out_dummy.logsout.getElementNames, 'blastForces'));
% idx.bMoment = find(matches(out_dummy.logsout.getElementNames, 'blastMoments'));
% 
% % --- Optimization Settings ---
% options = optimoptions('patternsearch', ...
%     'UseParallel', true, ...
%     'Display', 'iter', ...
%     'MeshTolerance', 1e-4, ...
%     'StepTolerance', 1e-4);
% 
% disp('Starting parallel optimization routine...');
% tic;
% % Run patternsearch on normalized variables
% objFun = @(x_norm) blastCostFunction(x_norm, lb_real, ub_real, T, params, idx);
% x_norm_opt = patternsearch(objFun, x0_norm, [], [], [], [], lb_norm, ub_norm, [], options);
% optTime = toc;
% 
% % Decode optimized parameters back to physical scales
% x_opt = lb_real + x_norm_opt .* (ub_real - lb_real);
% 
% fprintf('\n--- Optimization Complete in %.2f seconds ---\n', optTime);
% fprintf('Fixed W:           %.4f kg\n', params.W);
% fprintf('Fixed d0:          %.4f m\n', params.d0);
% fprintf('Fixed t0:          %.6f s\n\n', params.t0);
% fprintf('Optimized thetaB:  %.4f deg\n', x_opt(1));
% fprintf('Optimized phiB:    %.4f deg\n', x_opt(2));
% fprintf('Optimized rBody:   %.4f m\n', x_opt(3));
% fprintf('Optimized rMotors: %.4f m\n', x_opt(4));
% fprintf('Optimized L:       %.4f m\n', x_opt(5));
% fprintf('Optimized mBody:   %.4f kg\n', x_opt(6));
% fprintf('Optimized mMotor:  %.4f kg\n', x_opt(7));
% fprintf('Optimized mArm:    %.4f kg\n', x_opt(8));
% 
% %% --- Objective Function ---
% function cost = blastCostFunction(x_norm, lb_real, ub_real, T, params, idx)
%     % Decode normalized optimization variables
%     x_real = lb_real + x_norm .* (ub_real - lb_real);
% 
%     % Push parameters to the Parallel Worker's local base workspace
%     pushParamsToBase(x_real, params);
% 
%     try
%         % Ensure model is loaded and Fast Restart is OFF on this parallel worker
%         if ~bdIsLoaded(params.mdl)
%             load_system(params.mdl);
%             set_param(params.mdl, 'FastRestart', 'off');
%         end
% 
%         % Run simulation silently using Accelerator mode
%         out = sim(params.mdl, 'SimulationMode', 'accelerator', 'SrcWorkspace', 'base');
% 
%         % Extract sim data using the pre-cached indices
%         t_sim = out.logsout{idx.bForce}.Values.Time;
%         blastFx = squeeze(out.logsout{idx.bForce}.Values.Data(1,1,:));
%         blastFy = squeeze(out.logsout{idx.bForce}.Values.Data(1,2,:));
%         blastFz = -squeeze(out.logsout{idx.bForce}.Values.Data(1,3,:)); 
% 
%         blastMx = squeeze(out.logsout{idx.bMoment}.Values.Data(1,1,:));
%         blastMy = squeeze(out.logsout{idx.bMoment}.Values.Data(1,2,:));
%         blastMz = squeeze(out.logsout{idx.bMoment}.Values.Data(1,3,:));
% 
%         % Interpolate sim data onto the exact timestamps of the Corvid data
%         cTime = T.Time;
%         simFx_int = interp1(t_sim, blastFx, cTime, 'linear', 0);
%         simFy_int = interp1(t_sim, blastFy, cTime, 'linear', 0);
%         simFz_int = interp1(t_sim, blastFz, cTime, 'linear', 0);
%         simMx_int = interp1(t_sim, blastMx, cTime, 'linear', 0);
%         simMy_int = interp1(t_sim, blastMy, cTime, 'linear', 0);
%         simMz_int = interp1(t_sim, blastMz, cTime, 'linear', 0);
% 
%         % Normalize the errors by dividing by the max absolute value of the empirical data
%         eFx = sum( ((simFx_int - T.FA) ./ max(abs(T.FA))).^2 , 'omitnan');
%         eFy = sum( ((simFy_int - T.FS) ./ max(abs(T.FS))).^2 , 'omitnan');
%         eFz = sum( ((simFz_int - T.FN) ./ max(abs(T.FN))).^2 , 'omitnan');
% 
%         eMx = sum( ((simMx_int - T.M_roll) ./ max(abs(T.M_roll))).^2 , 'omitnan');
%         eMy = sum( ((simMy_int - T.M_pitch) ./ max(abs(T.M_pitch))).^2 , 'omitnan');
%         eMz = sum( ((simMz_int - T.M_yaw) ./ max(abs(T.M_yaw))).^2 , 'omitnan');
% 
%         cost = eFx + eFy + eFz + eMx + eMy + eMz;
% 
%     catch ME
%         % Print the error to the worker's console output
%         disp(['Sim failed for parameters | Error: ', ME.message]);
%         cost = 1e9; % Heavy penalty for failure
%     end
% end
% 
% %% --- Helper Function to Replace generalParams.m ---
% function pushParamsToBase(x_real, params)
%     % Extract physical variables
%     thetaB_try = x_real(1);
%     phiB_try   = x_real(2);
%     rBody      = x_real(3);
%     rMotors    = x_real(4);
%     L          = x_real(5);
%     mBody      = x_real(6);
%     mMotor     = x_real(7);
%     mArm       = x_real(8);
% 
%     % Convert blast orientation to radians
%     phiB_rad = deg2rad(phiB_try);
%     thetaB_rad = deg2rad(thetaB_try);
% 
%     % Calculate initial condition
%     IC = [params.d0*sin(phiB_rad)*cos(thetaB_rad), ...
%           params.d0*sin(phiB_rad)*sin(thetaB_rad), ...
%           params.d0*cos(phiB_rad)];
% 
%     blastParams = [thetaB_rad, phiB_rad, params.c, params.W, params.t0];
% 
%     % Set general vehicle constants
%     beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
%     dQuad = (rBody*2)+(rMotors*2)+(L*2);
% 
%     RMOTOR_iG = zeros(4,3);
%     for k = 1:height(RMOTOR_iG)
%         RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
%         RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
%     end
% 
%     quadDims = [rBody, rMotors, L];
%     desRPM = params.motorRPM*ones(4,1);
% 
%     % Set mass/aerodynamic constants
%     g = 9.81;
%     m = mBody + 4*mMotor + 4*mArm;
%     rpm_max  = 10000;
%     rpm_nom = rpm_max/2; 
%     CT = m*g/4/rpm_nom^2; 
%     rho = 1.225; 
%     bodyA = pi*rBody^2; 
%     motorA = pi*rMotors^2; 
%     CD = 1.17;
%     dragConstsMotor = -1/2*rho*motorA*CD;
%     dragConstsBody = -1/2*rho*bodyA*CD;
% 
%     % Calculate inertia
%     Ibody = (2/5) * mBody * (rBody^2)*eye(3);
%     alpha_val = 2*(L+rBody)^2;
%     Imotors = mMotor*diag([alpha_val alpha_val 2*alpha_val]);
%     gamma_val = ((L^2)/6) + 2*((L/2) + rMotors)^2;
%     Iarms = mArm*diag([gamma_val gamma_val 2*gamma_val]);
%     Iquad = Ibody + Iarms + Imotors;
% 
%     % Motor mixer 
%     rpm2bodyMomentRollPitch = [-L L L -L; 
%                                L -L L -L]; 
%     CM = 0.1; 
% 
%     % --- PUSH VARIABLES TO WORKER BASE WORKSPACE ---
%     varsToAssign = {
%         'simTime', params.simTime;
%         'sampleTime', params.sampleTime;
%         'IC', IC;
%         'blastParams', blastParams;
%         'beta', beta;
%         'dQuad', dQuad;
%         'RMOTOR_iG', RMOTOR_iG;
%         'quadDims', quadDims;
%         'desRPM', desRPM;
%         'g', g;
%         'm', m;
%         'rpm_max', rpm_max;
%         'rpm_nom', rpm_nom;
%         'CT', CT;
%         'rho', rho;
%         'bodyA', bodyA;
%         'motorA', motorA;
%         'CD', CD;
%         'dragConstsMotor', dragConstsMotor;
%         'dragConstsBody', dragConstsBody;
%         'Ibody', Ibody;
%         'alpha', alpha_val;
%         'Imotors', Imotors;
%         'gamma', gamma_val;
%         'Iarms', Iarms;
%         'Iquad', Iquad;
%         'rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch;
%         'CM', CM
%     };
% 
%     for i = 1:size(varsToAssign, 1)
%         assignin('base', varsToAssign{i,1}, varsToAssign{i,2});
%     end
% end