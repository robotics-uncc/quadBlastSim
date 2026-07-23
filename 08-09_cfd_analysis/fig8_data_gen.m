% generate_data.m
% Generates the pressure, velocity, and propagation speed fits and saves them.
clear; clc; close all;
addpath('../');
figDir = 'figs';

% Ensure subroutines are accessible
addpath('../');
addpath('../00_subroutines/');
% addpath('subroutines'); 

disp('Processing data and running curve fits...');

%% ================== 1. PROCESS BLAST DATA (r = 15m) ==================
W = 10; % kg - weight of explosives
c = 343;
target_d = 15; % Target radius

blastDataDir = 'blastFoam10kgFine';
dirInfo = dir(fullfile(blastDataDir, '*.csv'));

% --- ERROR FIX: Check if files were actually found ---
if isempty(dirInfo)
    error('No CSV files found in "%s". Please ensure your Current Folder in MATLAB is set to the directory containing the "blastFoamDataPlotting" folder.', blastDataDir);
end

filenames = string({dirInfo.name});

% Load CSVs
Umag_raw = table2array(readtable(fullfile(blastDataDir, filenames(1)), 'NumHeaderLines', 1));
overpressure_raw = table2array(readtable(fullfile(blastDataDir, filenames(2)), 'NumHeaderLines', 1));
radii_raw = table2array(readtable(fullfile(blastDataDir, filenames(3)), 'NumHeaderLines', 1));
radii = radii_raw(:,1);
times = table2array(readtable(fullfile(blastDataDir, filenames(4)), 'NumHeaderLines', 1));

Umag = Umag_raw(:, 1:length(times));
overpressure = overpressure_raw(:, 1:length(times));

% Find index for exactly 15m
[~, nearIdx] = min(abs(radii - target_d));
t = times;

% --- Pressure Optimization Setup ---
[PsStd, maxPsIdx] = max(overpressure(nearIdx, :));
t0_P = t(maxPsIdx);
crW = W^(1/3);
scaledDist = target_d / crW;

[Ps_i, tau_i] = sadovskiy(W, scaledDist);
modelPParams = [Ps_i, t0_P, tau_i];
PparamIC = [PsStd, t0_P, 1/200];

% --- Velocity Optimization Setup ---
[Vs_i, alpha_i, beta_i, a_i, ~] = deweyParams(scaledDist);
t0_V = t(maxPsIdx);
DT = t - t0_V;
scaledTime = c * DT / crW;
sympref('HeavisideAtOrigin', 1);
hval = ceil(heaviside(t - t0_V));
VparamIC = [Vs_i, alpha_i, beta_i, a_i];

currParams.times = t;
currParams.W = W;
currParams.t0 = t0_V;
currParams.dataV = Umag(nearIdx, :);

% Base Models
modelP = Pmodel(modelPParams, t);
modelV = Vmodel(VparamIC, scaledTime, hval);

% --- Run Optimizations ---
options = optimoptions('lsqcurvefit', 'Algorithm', 'interior-point', 'Display', 'off');
optParamP = lsqcurvefit(@(x,xdata)(abs(Pmodel(x,xdata))), PparamIC, t', abs(overpressure(nearIdx, :)), [], [], options);
optP = Pmodel(optParamP, t);

lbV = [0, 0, 0, 0];
ubV = [1, 1, 1, 1] * 5;
optParamV = lsqcurvefit(@(x,xdata)deweyOpt2(x,xdata,currParams), VparamIC, scaledTime, currParams.dataV, lbV, ubV, [], [], [], []);
optV = Vmodel(optParamV, scaledTime, hval);

% Store Empirical Data
p_cfd = overpressure(nearIdx, :);
v_cfd = Umag(nearIdx, :);

%% ================== 2. PROCESS C-FIT DATA ==================
load("cBestFitVars.mat");
[~, fitStart] = max(round(cVals(:,1), 1) == 1);
[~, fitEnd] = max(round(cVals(:,1), 1) == 25);
fitEnd = size(cVals,1) - fitEnd;
rows = fitStart:size(cVals,1)-fitEnd;
subset = cVals(fitStart:end-fitEnd, 2);
mask = isfinite(subset);
% 
% f = fit(cVals(rows(mask), 1), cVals(rows(mask), 2), 'power2');
% 
% % Calculate the true 3-sigma (99.73%) bounds of the fitted curve
% p_bounds = predint(f, cVals(:, 1), 0.9973, 'functional');
% 
% cValFit = f(cVals(:, 1));

ft = fittype('a*x^b + 343', 'independent', 'x', 'dependent', 'y');
opts = fitoptions('Method', 'NonlinearLeastSquares');

% Provide starting points based on the previous unconstrained fit
opts.StartPoint = [1224, -0.8247]; 

f = fit(cVals(rows(mask),1), cVals(rows(mask),2), ft, opts);
p_bounds = predint(f, cVals(:, 1), 0.9973, 'functional');
confIntVals = confint(f);
cValFit = f(cVals(:,1));

% Because c is fixed, confIntVals is only 2x2 (for parameters a and b)
cValFit1sigPos = confIntVals(2,1)*(cVals(:,1).^confIntVals(2,2)) + 343;
cValFit1sigNeg = confIntVals(1,1)*(cVals(:,1).^confIntVals(1,2)) + 343;


% predint outputs a matrix where col 1 is the lower bound, col 2 is the upper
cValFit3sigNeg = p_bounds(:, 1);
cValFit3sigPos = p_bounds(:, 2);

% Extract Data for Plotting
c_r = cVals(rows(mask), 1);
c_c = cVals(rows(mask), 2);
c_fit = cValFit(rows(mask));
c_3sigPos = cValFit3sigPos(rows(mask));
c_3sigNeg = cValFit3sigNeg(rows(mask));
c_fit_end_val = cValFit(end);

%% ================== 3. EXPORT WORKSPACE ==================
% Ensure figDir exists if saving anything to it directly
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
save(fullfile(figDir, 'plot_data.mat'), 't', 'p_cfd', 'modelP', 'optP', 'v_cfd', 'modelV', 'optV', ...
     'c_r', 'c_c', 'c_fit', 'c_3sigPos', 'c_3sigNeg', 'c_fit_end_val');
disp('Data successfully generated and saved to plot_data.mat!');