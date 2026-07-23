% generateFigureData.m
% Cleans and calculates data for the parameter and velocity plots
clear; clc; close all;
addpath('../')
addpath('../00_subroutines/')

%% 1. Generate Data for Left Plot (Parameter Curves)
S_vals = linspace(0.01, 10, 500); % Scaled distance S (m/kg^(1/3))

% Initialize arrays
v_s = zeros(size(S_vals));
alpha = zeros(size(S_vals));
beta = zeros(size(S_vals));
a = zeros(size(S_vals));

% Calculate parameters using the deweyParams function
for i = 1:length(S_vals)
    [v_s(i), alpha(i), beta(i), a(i), ~] = deweyParams(S_vals(i));
end

%% 2. Generate Data for Right Plot (Velocity Waveform)
% Parameters from friedlanderAndVelocity.m
W = 10;            % Explosive weight (kg)
d = 7.5;             % Distance (m)
% t0 = 1/1000;       % Time delay (1 ms)
t0 = 0;
c = 343;           % Wave speed (m/s)
t = linspace(0, 0.03, 2000); % Time from 0 to 10 ms

% Calculate scaled parameters for this specific blast
S_blast = W^(1/3);
scaledDist = d / S_blast;
disp(['Setup Scaled Distance (S): ', num2str(scaledDist), ' m/kg^(1/3)']);
[Vs_b, alpha_b, beta_b, a_b, ~] = deweyParams(scaledDist);

% Load the best fit for propagation speed
cFit = load('cBestFitVars.mat');
% cf = cFit.f;

% Calculate Velocity over time
V_t = zeros(size(t));
V_t_orig = zeros(size(t)); % Array for the model without exponential decay

for i = 1:length(t)
    ti = t(i);
    DT = ti - t0;
    
    if ti >= t0
        scaledTime = c * DT / S_blast;
        % Original Dewey model (without exponential decay, Eq. 4)
        V_t_orig(i) = Vs_b * (1 - beta_b * scaledTime) * exp(-alpha_b * scaledTime) + ...
                      a_b * log(1 + beta_b * scaledTime);
                  
        % Modified model (with exponential decay, Eq. 7)
        V_t(i) = V_t_orig(i) * exp(-scaledTime);
    else
        V_t(i) = 0; % Heaviside logic
        V_t_orig(i) = 0;
    end
end

% Convert time to ms for plotting
t_ms = t * 1000;

%% 3. Save Data
% Added V_t_orig to the save list
save('velocity_model_fig_data.mat', 'S_vals', 'v_s', 'alpha', 'beta', 'a', 't_ms', 'V_t', 'V_t_orig', 't0');
disp('Data successfully generated and saved to figureData.mat');