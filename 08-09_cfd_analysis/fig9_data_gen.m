% generateMeshgridData.m
% Runs CFD data extraction, parallel model calculations, and fmincon fitting.
% Saves the final plotting arrays to a .mat file.
clear; clc; close all;

% Add path to parent directory to load cBestFitVars and other functions
addpath('../');
addpath('subroutines\')

%% ========================= User controls =========================
W = 10;              % mass of explosive [kg]
mach2ms = 343;       % mach to m/s

% Mesh window controls
x0  = 7.5;           % minimum distance [m]
xf  = 15.0;          % maximum distance [m]
t00 = 0.01;          % initial time [s]
tf  = 0.035;          % maximum time [s]
N   = 500;           % mesh resolution

% Load the best fit propagation speed
propSpeedData = load("cBestFitVars.mat");
cF = propSpeedData.f;

% BlastFoam data directory
blastDataDir = 'blastFoam10kgFine';

%% ========================= Load BlastFoam data =========================
blastData.Umag = table2array(readtable(fullfile(blastDataDir, "Umag.csv"), 'NumHeaderLines', 1));
blastData.overpressure = table2array(readtable(fullfile(blastDataDir, "overpressure.csv"), 'NumHeaderLines', 1));
blastData.radii = table2array(readtable(fullfile(blastDataDir, "radii.csv"), 'NumHeaderLines', 1));
blastData.radii = blastData.radii(:,1);
blastData.times = table2array(readtable(fullfile(blastDataDir, "times.csv"), 'NumHeaderLines', 1));

blastData.Umag = blastData.Umag(:,1:length(blastData.times));
blastData.overpressure = blastData.overpressure(:,1:length(blastData.times));

xMask = blastData.radii >= x0 & blastData.radii <= xf;
tMask = blastData.times >= t00 & blastData.times <= tf;

blastRadiiCrop = blastData.radii(xMask);
blastTimesCrop = blastData.times(tMask);

blastPressure_kPa = 0.001 * blastData.overpressure(xMask, tMask)';   
blastVelocity_ms = blastData.Umag(xMask, tMask)';                    

[Xbf, Tbf] = meshgrid(blastRadiiCrop, blastTimesCrop);

%% ========================= Parallel model calculations =========================
pool = gcp('nocreate');
if isempty(pool)
    parpool;
end

% Non-propagated model (propFlag = 0)
[Xnp, Tnp, pressureNP, velocityNP, ~, ~, ~, ~, ~, ~] = ...
    calcModelGrid(W, cF, x0, xf, t00, tf, N, 0);

% Propagated model (propFlag = 1)
[Xp, Tp, pressureP, velocityP, ~, ~, ~, ~, ~, ~] = ...
    calcModelGrid(W, cF, x0, xf, t00, tf, N, 1);

%% ========================= Fit model parameters with fmincon =========================
theta0 = ones(1, 9);      
lb = [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.80, 0.50, 0.50];
ub = [4.00, 4.00, 4.00, 4.00, 4.00, 4.00, 1.20, 1.50, 1.50];

objFun = @(theta) fitObjective(theta, W, cF, x0, xf, t00, tf, N, ...
    Xbf, Tbf, blastPressure_kPa, blastVelocity_ms, mach2ms);

opts = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp', ...
    'MaxFunctionEvaluations', 2000, 'MaxIterations', 300);

thetaFit = fmincon(objFun, theta0, [], [], [], [], lb, ub, [], opts);

% Build fitted model grid
[Xfit, Tfit, pressureFit, velocityFit, ~, ~, ~, ~, ~, ~] = ...
    calcModelGridFitted(W, cF, x0, xf, t00, tf, N, 1, thetaFit);

% Convert units for saving
pressureNP_kPa = 0.001 * pressureNP;
pressureP_kPa  = 0.001 * pressureP;
pressureFit_kPa = 0.001 * pressureFit;

velocityNP_ms  = mach2ms * velocityNP;
velocityP_ms   = mach2ms * velocityP;
velocityFit_ms = mach2ms * velocityFit;

% Interpolate the high-res fitted model onto the CFD grid for 1:1 error comparison
pressureFit_onBF = interp2(Xfit, Tfit, pressureFit_kPa, Xbf, Tbf, 'linear', NaN);
velocityFit_onBF = interp2(Xfit, Tfit, velocityFit_ms,  Xbf, Tbf, 'linear', NaN);

% Calculate error metrics and save to TXT file
saveModelMetrics(blastPressure_kPa, pressureFit_onBF, blastVelocity_ms, velocityFit_onBF, 'Fitted_Model_Metrics.txt');

% Save workspace arrays to MAT file
save('meshgridData.mat', 'Xnp', 'Tnp', 'pressureNP_kPa', 'velocityNP_ms', ...
    'Xp', 'Tp', 'pressureP_kPa', 'velocityP_ms', ...
    'Xfit', 'Tfit', 'pressureFit_kPa', 'velocityFit_ms', ...
    'Xbf', 'Tbf', 'blastPressure_kPa', 'blastVelocity_ms', ...
    'x0', 'xf', 't00', 'tf'); 

disp('Data successfully generated and saved to meshgridData.mat');

%% ========================= Local functions =========================
function [X, T, pressure, velocity, all_Ps, all_tau, all_V, all_alpha, all_beta, all_a] = ...
    calcModelGrid(W, c, x0, xf, t00, tf, N, propFlag)

    x = linspace(x0, xf, N);
    tspan = linspace(t00, tf, N);
    [X, T] = meshgrid(x, tspan);

    pressure  = zeros(N, N);
    velocity  = zeros(N, N);
    all_Ps    = zeros(N, N);
    all_tau   = zeros(N, N);
    all_V     = zeros(N, N);
    all_alpha = zeros(N, N);
    all_beta  = zeros(N, N);
    all_a     = zeros(N, N);

    nPts = numel(X);

    parfor idx = 1:nPts
        d = X(idx);
        t = T(idx);

        if propFlag == 1
            t0_local = t00 + (d - x0) / c(d);
        else
            t0_local = t00;
        end
        Dt = t - t0_local;

        cubeRootWInv = W^(-1/3);
        scaledDist = d * cubeRootWInv;
        scaledTime = c(d) * max(Dt, 0) * cubeRootWInv;

        [Ps, tau] = sadovskiy(W, scaledDist);
        currP = Pmodel([Ps, t0_local, tau], t);

        [v, alpha, beta, a, ~] = deweyParams(scaledDist);
        hval = custHeaviside(Dt);
        currV = Vmodel([v, alpha, beta, a], scaledTime, hval);

        pressure(idx)   = currP;
        velocity(idx)   = currV;
        all_Ps(idx)     = Ps;
        all_tau(idx)    = tau;
        all_V(idx)      = v;
        all_alpha(idx)  = alpha;
        all_beta(idx)   = beta;
        all_a(idx)      = a;
    end
end

function J = fitObjective(theta, W, ~, x0, xf, t00, tf, N, Xbf, Tbf, blastPressure_kPa, blastVelocity_ms, mach2ms)
    
    % Pass the expanded theta; we ignore the 'c' argument by passing [] since
    % calcModelGridFitted will now calculate it internally
    [Xf, Tf, pressureF, velocityF] = calcModelGridFitted(W, [], x0, xf, t00, tf, N, 1, theta);

    pressureF_kPa = 0.001 * pressureF;
    velocityF_ms  = mach2ms * velocityF;

    % Interpolate fitted model onto CFD grid
    pressureF_onBF = interp2(Xf, Tf, pressureF_kPa, Xbf, Tbf, 'linear', NaN);
    velocityF_onBF = interp2(Xf, Tf, velocityF_ms,  Xbf, Tbf, 'linear', NaN);

    validP = ~isnan(pressureF_onBF) & ~isnan(blastPressure_kPa);
    validV = ~isnan(velocityF_onBF) & ~isnan(blastVelocity_ms);

    pErr = pressureF_onBF(validP) - blastPressure_kPa(validP);
    vErr = velocityF_onBF(validV) - blastVelocity_ms(validV);

    rmseP = sqrt(mean(pErr.^2));
    rmseV = sqrt(mean(vErr.^2));

    % Normalize so pressure and velocity both matter
    pScale = max(blastPressure_kPa(:)) - min(blastPressure_kPa(:));
    vScale = max(blastVelocity_ms(:))  - min(blastVelocity_ms(:));

    if pScale == 0, pScale = 1; end
    if vScale == 0, vScale = 1; end

    J = rmseP/pScale + rmseV/vScale;
end

function [X, T, pressure, velocity, all_Ps, all_tau, all_V, all_alpha, all_beta, all_a] = ...
    calcModelGridFitted(W, ~, x0, xf, t00, tf, N, propFlag, theta)

    % Extract scale factors
    kPs    = theta(1);
    kTau   = theta(2);
    kV     = theta(3);
    kAlpha = theta(4);
    kBeta  = theta(5);
    kA     = theta(6);
    
    % Decode propagation speed coefficients based on their initial cF values
    c_a    = theta(7) * 1698;      
    c_b    = theta(8) * -0.6454;    
    c_c    = theta(9) * 73.96;     

    x = linspace(x0, xf, N);
    tspan = linspace(t00, tf, N);
    [X, T] = meshgrid(x, tspan);

    pressure  = zeros(N, N);
    velocity  = zeros(N, N);
    all_Ps    = zeros(N, N);
    all_tau   = zeros(N, N);
    all_V     = zeros(N, N);
    all_alpha = zeros(N, N);
    all_beta  = zeros(N, N);
    all_a     = zeros(N, N);

    nPts = numel(X);

    parfor idx = 1:nPts
        d = X(idx);
        t = T(idx);
        
        % Calculate local propagation speed dynamically based on fitted coefficients
        local_c = c_a * (d^c_b) + c_c;

        if propFlag == 1
            t0_local = t00 + (d - x0) / local_c;
        else
            t0_local = t00;
        end
        Dt = t - t0_local;

        cubeRootWInv = W^(-1/3);
        scaledDist = d * cubeRootWInv;
        scaledTime = local_c * max(Dt, 0) * cubeRootWInv;

        [Ps, tau] = sadovskiy(W, scaledDist);
        [v, alpha, beta, a, ~] = deweyParams(scaledDist);

        % Apply fitted scale factors
        Ps    = kPs    * Ps;
        tau   = kTau   * tau;
        v     = kV     * v;
        alpha = kAlpha * alpha;
        beta  = kBeta  * beta;
        a     = kA     * a;

        currP = Pmodel([Ps, t0_local, tau], t);

        hval = custHeaviside(Dt);
        currV = Vmodel([v, alpha, beta, a], scaledTime, hval);

        pressure(idx)   = currP;
        velocity(idx)   = currV;
        all_Ps(idx)     = Ps;
        all_tau(idx)    = tau;
        all_V(idx)      = v;
        all_alpha(idx)  = alpha;
        all_beta(idx)   = beta;
        all_a(idx)      = a;
    end
end

function saveModelMetrics(pressureTrue, pressurePred, velocityTrue, velocityPred, filename)
    % saveModelMetrics: Calculates error metrics and saves them to a text file.
    
    % 1. Calculate metrics for both models
    pressureMetrics = calculateMetrics(pressureTrue, pressurePred);
    velocityMetrics = calculateMetrics(velocityTrue, velocityPred);

    % 2. Open the text file for writing 
    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file %s for writing.', filename);
    end

    % 3. Write the header
    fprintf(fid, '==================================================\n');
    fprintf(fid, '             MODEL ERROR METRICS REPORT           \n');
    fprintf(fid, '==================================================\n');
    fprintf(fid, 'Date Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));

    % 4. Write Pressure Metrics
    fprintf(fid, '--- PRESSURE MODEL ---\n');
    fprintf(fid, 'RMSE     : %.4f\n', pressureMetrics.RMSE);
    fprintf(fid, 'MAE      : %.4f\n', pressureMetrics.MAE);
    fprintf(fid, 'Max Error: %.4f\n', pressureMetrics.MaxError);
    fprintf(fid, 'R-squared: %.4f\n\n', pressureMetrics.R2);

    % 5. Write Velocity Metrics
    fprintf(fid, '--- VELOCITY MODEL ---\n');
    fprintf(fid, 'RMSE     : %.4f\n', velocityMetrics.RMSE);
    fprintf(fid, 'MAE      : %.4f\n', velocityMetrics.MAE);
    fprintf(fid, 'Max Error: %.4f\n', velocityMetrics.MaxError);
    fprintf(fid, 'R-squared: %.4f\n', velocityMetrics.R2);
    fprintf(fid, '==================================================\n');

    % 6. Close the file
    fclose(fid);
    
    fprintf('Metrics successfully saved to %s\n', filename);
end

function metrics = calculateMetrics(y_true, y_pred)
    % Force data into column vectors to handle 2D meshgrid data properly
    y_true = y_true(:);
    y_pred = y_pred(:);
    
    % Ensure no NaNs ruin the calculation (important since we interpolated)
    validIdx = ~isnan(y_true) & ~isnan(y_pred);
    y_true = y_true(validIdx);
    y_pred = y_pred(validIdx);

    % Error array
    err = y_true - y_pred;

    % 1. Root Mean Square Error (RMSE)
    metrics.RMSE = sqrt(mean(err.^2));

    % 2. Mean Absolute Error (MAE)
    metrics.MAE = mean(abs(err));

    % 3. Maximum Error
    metrics.MaxError = max(abs(err));

    % 4. R-squared (Coefficient of Determination)
    SS_res = sum(err.^2);
    SS_tot = sum((y_true - mean(y_true)).^2);
    if SS_tot == 0 
        metrics.R2 = NaN;
    else
        metrics.R2 = 1 - (SS_res / SS_tot);
    end
end