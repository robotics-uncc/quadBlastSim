clf;clc;clear all;close all;

% General parameters
W = 10;     % mass of explosive - kg
c = 343;    % speed of sound - m/s

% Set initial and final values
x0 = 0;
xf = 30;
t0 = 0;
tf = 0.1;

% Initialize ranges and make a mesh
N = 100;
x = linspace(x0,xf,N);
t = linspace(t0,tf,N);
[X, T] = meshgrid(x, t);

% Initialize matrices to hold the pressure and velocity values
pressure = zeros(N, N);
velocity = zeros(N, N);

% Calculate the pressure and time for all combinations
hbar = waitbar(0,'Calculating data...');
step = 0;
totalSteps = numel(X);
for i = 1:N
    for j = 1:N
        %%%%%%%%%%%%%%% General %%%%%%%%%%%%%%%
        % Unpack
        d = X(i,j);
        t = T(i,j);
        
        % Calculate scaled values
        cubeRootW = W^(-1/3);
        scaledDist = d*cubeRootW;
        scaledTime = c*t*cubeRootW;
        % scaledTime = d*cubeRootW;
        % scaledTime = d/W;

        %%%%%%%%%%%%%%% Pressure %%%%%%%%%%%%%%%
        [Ps, tau] = sadovskiy(W, scaledDist);
        params = [Ps, t0, tau];
        currP = Pmodel(params, t);

        %%%%%%%%%%%%%%% Velocity %%%%%%%%%%%%%%%
        [v, alpha, beta, a, ~] = deweyParams(scaledDist);
        params = [v, alpha, beta, a];
        hval = ceil(heaviside(t-t0));
        currV = Vmodel(params, scaledTime, hval);

        %%%%%%%%%%%%%%% Store data %%%%%%%%%%%%%%%
        pressure(i, j) = currP;
        velocity(i, j) = currV;

        %%%%%%%%%%%%%%% Update progress bar %%%%%%%%%%%%%%%
        step = step + 1;
        waitbar(step / totalSteps, hbar, sprintf('Calculating data... %d / %d', step, totalSteps));
    end
end

%% Setup plotting
figDir = 'noPropagationSpeedTesting';
mkdir(figDir)
lw = 1.2;
colormap("turbo")

%% Plot the data
surfMaker

% animationMaker;