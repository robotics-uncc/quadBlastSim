% Clear everything
clear; clc; close all;

%% Parameters
Ps = 10000;      % Peak overpressure [Pa]
t0 = 0.001;      % Time delay [s]
tau = 0.001;     % Time constant [s]
c = 343;         % Speed of wave [m/s]
R = 0.15;        % Radius of sphere [m]
d = 5;           % Distance [m]
tf = 0.0104;     % Final time [s] (slightly past 10ms for plotting margins)

% Time array
t = linspace(0, tf, 2000); 

%% 1. Calculate Ideal Overpressure Waveform
% Using the modified Friedlander equation at the front face
idealPressure = heaviside(t-t0) .* Ps .* exp(-(t-t0)/tau) .* (1 - ((t-t0)/tau));

%% 2. Calculate Net Force on Sphere
% Define spatial slice over the sphere
x = linspace(-R, R) + d;
x0 = d - R;

% Precompute pressure field across the sphere volume over time
pp = zeros(length(x), length(t));
for j = 1:length(t)
    val = t(j) - (x - x0)/c;
    Dt = val - t0;
    expr = Dt ./ tau;
    hval = heaviside(Dt);
    pp(:,j) = Ps .* exp(-expr) .* (1 - expr) .* hval;
end

% Integrate pressure over the sphere surface to find Net Force
Fx = zeros(1, length(t));
eps = 0.0000001;
for k = 1:length(t)
    % Integrate using trapezoidal rule
    % Fval = trapz(x-d, pp(:,k)' .* (x-d) .* sqrt((R+eps)^2 - (x-d).^2)) * -pi/R;
    Fval = trapz(x-d, pp(:,k)' .* (x-d)) * -2 * pi;
    Fx(k) = real(Fval); % Ensure no residual imaginary parts
end

%% Save Data
% Convert standard SI to plotting units
t_ms = t * 1000;
P_kPa = idealPressure / 1000;

save('waveformData.mat', 't_ms', 'P_kPa', 'Fx', 't0', 'tau');
disp('Data generation complete. Saved to waveformData.mat');