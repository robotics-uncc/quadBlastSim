% main_optimize.m
% Clear things for a clean simulation
clc; clearvars; close all;

disp('--- Initializing Crash-Safe Optimization ---');

% --- CLEANUP STALE SIMULINK CACHE ---
if exist('slprj', 'dir')
    disp('Clearing cache...');
    rmdir('slprj', 's');
    pause(1); % Give the OS time to release file locks
end
if exist('UAVSim.slxc', 'file')
    delete('UAVSim.slxc');
end

% --- Start Restricted Parallel Pool ---
% CRITICAL FIX: Limit workers to leave RAM and CPU headroom for Windows.
maxWorkers = 4; % Do NOT let this exceed half of your physical CPU cores.
poolobj = gcp('nocreate');
if ~isempty(poolobj)
    if poolobj.NumWorkers > maxWorkers
        disp('Closing oversized pool...');
        delete(poolobj);
        poolobj = [];
    end
end
if isempty(poolobj)
    fprintf('Starting Process-based parallel pool with strictly %d workers...\n', maxWorkers);
    parpool('Processes', maxWorkers);
end

% --- Select Target Dataset for Optimization ---
corvidFilename = 'corvidData/near.txt'; 
T = readtable(corvidFilename);

% Group static baseline vehicle and simulation parameters
params.sampleTime = 0.0001;
params.W = 4.98952;         
params.d0 = 8.66025;   
params.motorRPM = 5000;
params.c = 360; 
params.mdl = 'UAVSim';

% Set a fixed, long simTime so the sim doesn't cut off early
params.simTime = 0.2; 

% --- DEFINE BOUNDARIES ---
% Order: [thetaB, phiB, rBody, rMotors, L, mBody, mMotor, mArm, t0]
lb_real = [-180,   0, 0.05, 0.01, 0.10, 0.20, 0.01, 0.01, -0.50];
ub_real = [ 180, 360, 0.90, 0.30, 1.50, 6.00, 0.60, 0.90, 0.50];

% Normalize parameters for the optimizer [0, 1] for stable gradients
lb_norm = zeros(1, 9);
ub_norm = ones(1, 9);

% --- Pre-calculate Logsout Indices ---
disp('Performing initialization run to cache model data...');
x0_real = [-45, 125.26, 0.1375, 0.022, 0.275, 0.8, 0.055, 0.1755, 0.015];
x0_norm = (x0_real - lb_real) ./ (ub_real - lb_real);

% --- Optimization Settings (Particle Swarm) ---
options = optimoptions('particleswarm', ...
    'UseParallel', true, ...
    'Display', 'iter', ...
    'SwarmSize', 30, ... % CRITICAL FIX: Halved to reduce memory footprint
    'MaxIterations', 200, ...
    'FunctionTolerance', 1e-4, ...
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
save('sim_config.mat', 'params', 'lb_real', 'ub_real');

optimized_results = struct(...
    'thetaB', x_opt(1), 'phiB', x_opt(2), 'rBody', x_opt(3), ...
    'rMotors', x_opt(4), 'L', x_opt(5), 'mBody', x_opt(6), ...
    'mMotor', x_opt(7), 'mArm', x_opt(8), 't0', x_opt(9), ...
    'full_vector', x_opt, 'final_cost', x_norm_opt);

save('optimized_params.mat', 'optimized_results');
fprintf('Optimization Complete in %.2f seconds\n', optTime);

%% --- Final Visualization ---
disp('Generating final comparison plots...');
pushParamsToBase(x_opt, params);
out_final = sim(params.mdl, 'SimulationMode', 'normal', 'SrcWorkspace', 'base');

t_sim = out_final.logsout.get('totalM').Values.Time;

% --- Force Extraction ---
bodyDrag = squeeze(out_final.logsout.get('bodyDragInertialFrame').Values.Data)';
mDragData = out_final.logsout.get('motorDragInertial').Values.Data;
allForce = bodyDrag + squeeze(mDragData(1,:,:))' + squeeze(mDragData(2,:,:))' + ...
           squeeze(mDragData(3,:,:))' + squeeze(mDragData(4,:,:))';
simF = [allForce(:,1), allForce(:,2), -allForce(:,3)]; 

% --- Moment Extraction ---
simM_raw = out_final.logsout.get('totalM').Values.Data;
if ndims(simM_raw) == 3
    simM = squeeze(simM_raw);
    if size(simM, 1) == 3 && size(simM, 2) ~= 3
        simM = simM'; 
    end
else
    simM = simM_raw;
end

% --- Plotting ---
figure('Name', 'Optimization Results', 'Color', 'w', 'Position', [100, 100, 1200, 800]);
anchor_time = 0.015;
subplot(2,1,1); hold on; grid on;
plot(T.Time + anchor_time, T.FA, 'r--', 'LineWidth', 1.2);
plot(T.Time + anchor_time, T.FS, 'g--', 'LineWidth', 1.2);
plot(T.Time + anchor_time, T.FN, 'b--', 'LineWidth', 1.2);
plot(t_sim, simF(:,1), 'r-', 'LineWidth', 1.5);
plot(t_sim, simF(:,2), 'g-', 'LineWidth', 1.5);
plot(t_sim, simF(:,3), 'b-', 'LineWidth', 1.5);
title('Force Comparison (Inertial Frame)'); ylabel('Force (N)');
legend('Empirical Fx', 'Empirical Fy', 'Empirical Fz', 'Sim Fx', 'Sim Fy', 'Sim Fz', 'Location', 'bestoutside');

subplot(2,1,2); hold on; grid on;
plot(T.Time + anchor_time, T.M_roll,  'r--', 'LineWidth', 1.2);
plot(T.Time + anchor_time, T.M_pitch, 'g--', 'LineWidth', 1.2);
plot(T.Time + anchor_time, T.M_yaw,   'b--', 'LineWidth', 1.2);
plot(t_sim, simM(:,1), 'r-', 'LineWidth', 1.5); 
plot(t_sim, simM(:,2), 'g-', 'LineWidth', 1.5); 
plot(t_sim, simM(:,3), 'b-', 'LineWidth', 1.5); 
title('Moment Comparison (Body Frame)'); xlabel('Time (s)'); ylabel('Moment (N-m)');
legend('Empirical Mx', 'Empirical My', 'Empirical Mz', 'Sim Mx', 'Sim My', 'Sim Mz', 'Location', 'bestoutside');

xlim([x_opt(9) - 0.005, x_opt(9) + max(T.Time) + 0.005]);
exportgraphics(gcf, 'OptimizationResults.png', 'Resolution', 300);

%% --- Objective Function ---
function cost = blastCostFunction(x_norm, lb_real, ub_real, T, params)
    if ~bdIsLoaded(params.mdl), load_system(params.mdl); end

    x_real = lb_real + x_norm .* (ub_real - lb_real);
    thetaB_try = x_real(1); phiB_try   = x_real(2);
    rBody      = x_real(3); rMotors    = x_real(4);
    L          = x_real(5); mBody      = x_real(6);
    mMotor     = x_real(7); mArm       = x_real(8);
    t0_try     = x_real(9);

    phiB_rad = deg2rad(phiB_try); thetaB_rad = deg2rad(thetaB_try);
    IC = [params.d0*sin(phiB_rad)*cos(thetaB_rad), params.d0*sin(phiB_rad)*sin(thetaB_rad), params.d0*cos(phiB_rad)];
    blastParams = [thetaB_rad, phiB_rad, params.c, params.W, t0_try];

    beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; dQuad = (rBody*2)+(rMotors*2)+(L*2);
    RMOTOR_iG = zeros(4,3);
    for k = 1:4
        RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k)); RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
    end

    quadDims = [rBody, rMotors, L]; desRPM = params.motorRPM*ones(4,1);
    g = 9.81; m = mBody + 4*mMotor + 4*mArm;
    rpm_max = 10000; rpm_nom = rpm_max/2; CT = m*g/4/rpm_nom^2; 
    rho = 1.225; bodyA = pi*rBody^2; motorA = pi*rMotors^2; CD = 1.17;
    dragConstsMotor = -1/2*rho*motorA*CD; dragConstsBody = -1/2*rho*bodyA*CD;

    Ibody = (2/5) * mBody * (rBody^2)*eye(3); alpha_val = 2*(L+rBody)^2;
    Imotors = mMotor*diag([alpha_val alpha_val 2*alpha_val]);
    gamma_val = ((L^2)/6) + 2*((L/2) + rMotors)^2;
    Iarms = mArm*diag([gamma_val gamma_val 2*gamma_val]);
    Iquad = Ibody + Iarms + Imotors;
    rpm2bodyMomentRollPitch = [-L L L -L; L -L L -L]; CM = 0.1; 

    simIn = Simulink.SimulationInput(params.mdl);
    simIn = setModelParameter(simIn, 'SimulationMode', 'normal');
    simIn = setModelParameter(simIn, 'UnitsInconsistencyMsg', 'none');

    vars = {'simTime', params.simTime; 'sampleTime', params.sampleTime; 'IC', IC; 'blastParams', blastParams;
            'beta', beta; 'dQuad', dQuad; 'RMOTOR_iG', RMOTOR_iG; 'quadDims', quadDims; 'desRPM', desRPM;
            'g', g; 'm', m; 'rpm_max', rpm_max; 'rpm_nom', rpm_nom; 'CT', CT; 'rho', rho; 'bodyA', bodyA;
            'motorA', motorA; 'CD', CD; 'dragConstsMotor', dragConstsMotor; 'dragConstsBody', dragConstsBody;
            'Ibody', Ibody; 'alpha', alpha_val; 'Imotors', Imotors; 'gamma', gamma_val; 'Iarms', Iarms;
            'Iquad', Iquad; 'rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch; 'CM', CM};
            
    for i = 1:size(vars, 1), simIn = setVariable(simIn, vars{i,1}, vars{i,2}); end

    out = sim(simIn);

    bDragObj = out.logsout.get('bodyDragInertialFrame'); if iscell(bDragObj), bDragObj = bDragObj{1}; end
    bodyDrag = squeeze(bDragObj.Values.Data)';
    mDragObj = out.logsout.get('motorDragInertial'); if iscell(mDragObj), mDragObj = mDragObj{1}; end
    mDragData = mDragObj.Values.Data;
    
    allForce = bodyDrag + squeeze(mDragData(1,:,:))' + squeeze(mDragData(2,:,:))' + squeeze(mDragData(3,:,:))' + squeeze(mDragData(4,:,:))';
    simFx = allForce(:, 1); simFy = allForce(:, 2); simFz = -allForce(:, 3); 

    totMObj = out.logsout.get('totalM'); if iscell(totMObj), totMObj = totMObj{1}; end
    t_sim = totMObj.Values.Time;
    simMx = squeeze(totMObj.Values.Data(1,1,:)); simMy = squeeze(totMObj.Values.Data(1,2,:)); simMz = squeeze(totMObj.Values.Data(1,3,:));

    validIdx = T.Time <= params.simTime;
    % cTime = T.Time + t0_try;
    expected_arrival_time = 0.015; 
    % expected_arrival_time = 0.024056; 
    cTime = T.Time + expected_arrival_time;
    
    simFx_int = interp1(t_sim, simFx, cTime, 'linear', 'extrap');
    simFy_int = interp1(t_sim, simFy, cTime, 'linear', 'extrap');
    simFz_int = interp1(t_sim, simFz, cTime, 'linear', 'extrap');
    simMx_int = interp1(t_sim, simMx, cTime, 'linear', 'extrap');
    simMy_int = interp1(t_sim, simMy, cTime, 'linear', 'extrap');
    simMz_int = interp1(t_sim, simMz, cTime, 'linear', 'extrap');

    eFx = sum( ((simFx_int - T.FA(validIdx)) ./ max(max(abs(T.FA(validIdx))), 1e-4)).^2 , 'omitnan');
    eFy = sum( ((simFy_int - T.FS(validIdx)) ./ max(max(abs(T.FS(validIdx))), 1e-4)).^2 , 'omitnan');
    eFz = sum( ((simFz_int - T.FN(validIdx)) ./ max(max(abs(T.FN(validIdx))), 1e-4)).^2 , 'omitnan');
    eMx = sum( ((simMx_int - T.M_roll(validIdx)) ./ max(max(abs(T.M_roll(validIdx))), 1e-4)).^2 , 'omitnan');
    eMy = sum( ((simMy_int - T.M_pitch(validIdx)) ./ max(max(abs(T.M_pitch(validIdx))), 1e-4)).^2 , 'omitnan');
    eMz = sum( ((simMz_int - T.M_yaw(validIdx)) ./ max(max(abs(T.M_yaw(validIdx))), 1e-4)).^2 , 'omitnan');

    geomPenalty = 0; if (rBody + rMotors) >= L, geomPenalty = 1e5 * ((rBody + rMotors) - L); end
    
    cost = eFx + eFy + eFz + eMx + eMy + eMz + geomPenalty;

    % CRITICAL FIX: Aggressive Garbage Collection
    clear out simIn bDragObj mDragObj totMObj;
end

%% --- Helper Function ---
function pushParamsToBase(x_real, params)
    thetaB_try = x_real(1); phiB_try   = x_real(2);
    rBody      = x_real(3); rMotors    = x_real(4);
    L          = x_real(5); mBody      = x_real(6);
    mMotor     = x_real(7); mArm       = x_real(8);

    phiB_rad = deg2rad(phiB_try); thetaB_rad = deg2rad(thetaB_try);
    IC = [params.d0*sin(phiB_rad)*cos(thetaB_rad), params.d0*sin(phiB_rad)*sin(thetaB_rad), params.d0*cos(phiB_rad)];
    blastParams = [thetaB_rad, phiB_rad, params.c, params.W, x_real(9)];

    beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; dQuad = (rBody*2)+(rMotors*2)+(L*2);
    RMOTOR_iG = zeros(4,3);
    for k = 1:4
        RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k)); RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
    end

    quadDims = [rBody, rMotors, L]; desRPM = params.motorRPM*ones(4,1);
    g = 9.81; m = mBody + 4*mMotor + 4*mArm;
    rpm_max = 10000; rpm_nom = rpm_max/2; CT = m*g/4/rpm_nom^2; 
    rho = 1.225; bodyA = pi*rBody^2; motorA = pi*rMotors^2; CD = 1.17;
    dragConstsMotor = -1/2*rho*motorA*CD; dragConstsBody = -1/2*rho*bodyA*CD;

    Ibody = (2/5) * mBody * (rBody^2)*eye(3); alpha_val = 2*(L+rBody)^2;
    Imotors = mMotor*diag([alpha_val alpha_val 2*alpha_val]);
    gamma_val = ((L^2)/6) + 2*((L/2) + rMotors)^2;
    Iarms = mArm*diag([gamma_val gamma_val 2*gamma_val]);
    Iquad = Ibody + Iarms + Imotors;
    rpm2bodyMomentRollPitch = [-L L L -L; L -L L -L]; CM = 0.1; 

    vars = {'simTime', params.simTime; 'sampleTime', params.sampleTime; 'IC', IC; 'blastParams', blastParams;
            'beta', beta; 'dQuad', dQuad; 'RMOTOR_iG', RMOTOR_iG; 'quadDims', quadDims; 'desRPM', desRPM;
            'g', g; 'm', m; 'rpm_max', rpm_max; 'rpm_nom', rpm_nom; 'CT', CT; 'rho', rho; 'bodyA', bodyA;
            'motorA', motorA; 'CD', CD; 'dragConstsMotor', dragConstsMotor; 'dragConstsBody', dragConstsBody;
            'Ibody', Ibody; 'alpha', alpha_val; 'Imotors', Imotors; 'gamma', gamma_val; 'Iarms', Iarms;
            'Iquad', Iquad; 'rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch; 'CM', CM};

    for i = 1:size(vars, 1), assignin('base', vars{i,1}, vars{i,2}); end
end