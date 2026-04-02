clf;clc;clear all;close all;

% Turn propagation on/off
propFlag = 1;

% General parameters
W = 10;     % mass of explosive - kg
c = 343;    % speed of sound - m/s
mach2ms = 343; % mach to m/s

% Set initial and final values
x0 = 0.1;
xf = 10;
t00 = 0;
% maxTau = 0.008+t0;
% tf = max(maxTau*10,0.1);
tf = 0.05;

% Initialize ranges and make a mesh
N = 500;
x = linspace(x0,xf,N);
tspan = linspace(t00,tf,N);
[X, T] = meshgrid(x, tspan);

% Initialize matrices to hold the pressure and velocity values
pressure  = zeros(N, N);
velocity  = zeros(N, N);
all_Ps    = zeros(N, N);
all_tau   = zeros(N, N);
all_V     = zeros(N, N);
all_alpha = zeros(N, N);
all_beta  = zeros(N, N);
all_a     = zeros(N, N);

% Make filename prefix
if propFlag == 1
    prefixStr = 'propagated-';
else
    prefixStr = 'noProp-';
end

% Start a parallel pool
nPts = numel(X);
pool = gcp('nocreate');
if isempty(pool)
    parpool;
end

% Calculate the pressure and time for all combinations
% hbar = waitbar(0,'Calculating data...');
step = 0;
% totalSteps = numel(X);
t0 = t00;
parfor idx = 1:nPts
    % for j = 1:N
        %%%%%%%%%%%%%%% General %%%%%%%%%%%%%%%
        % Unpack
        d = X(idx);
        t = T(idx);
        
        % If propagation is on, propagate the waves by shifting t0 based on c
        if propFlag == 1
            t0 = t00 + (d - x0) / c;
        else
            t0 = t00;
        end
        Dt = t-t0;
        
        % Calculate scaled values
        cubeRootW = W^(-1/3);
        scaledDist = d*cubeRootW;
        scaledTime = c*max(Dt,0)*cubeRootW;
        % scaledTime = d*cubeRootW;
        % scaledTime = d/W;

        %%%%%%%%%%%%%%% Pressure %%%%%%%%%%%%%%%
        [Ps, tau] = sadovskiy(W, scaledDist);
        params = [Ps, t0, tau];
        currP = Pmodel(params, t);
        if isnan(currP)
            1;
        end

        %%%%%%%%%%%%%%% Velocity %%%%%%%%%%%%%%%
        [v, alpha, beta, a, ~] = deweyParams(scaledDist);
        params = [v, alpha, beta, a];
        % hval = ceil(heaviside(t-t0));
        hval = custHeaviside(Dt);
        currV = Vmodel(params, scaledTime, hval);

        %%%%%%%%%%%%%%% Store data %%%%%%%%%%%%%%%
        pressure(idx)   = currP;
        velocity(idx)   = currV;
        all_Ps(idx)     = Ps;
        all_tau(idx)    = tau;
        all_V(idx)      = v;
        all_alpha(idx)  = alpha;
        all_beta(idx)   = beta;
        all_a(idx)      = a;

        %%%%%%%%%%%%%%% Update progress bar %%%%%%%%%%%%%%%
        % step = step + 1;
        % waitbar(step / totalSteps, hbar, sprintf('Calculating data... %d / %d', step, totalSteps));
    % end
end

%% Setup plotting
figDir = 'meshgridPandV';
mkdir(figDir)
lw = 1.2;
colormap("turbo")

%% Plot the data
% Create surface plots for pressure and velocity
figure(1);
set(gcf,'color','w', 'Units','inches', 'Position',[1, 1, 6.5, 2])
ax1 = subplot(1, 2, 1);
cb = plotMeshOnSubplot(ax1,X,T,0.001*pressure);
clim([-10000, 100000])
% clim([0, 100000])
% cb.Ruler.Scale = 'log';
ylabel('Time (s)');
xlabel('Distance (m)');
grid off
cb.Label.String = 'Pressure (kPa)';
axis square

ax2 = subplot(1, 2, 2);
cb = plotMeshOnSubplot(ax2,X,T,mach2ms*velocity);
xlabel('Distance (m)');
% ylabel('Time (s)');
cb.Label.String = 'Velocity (m/s)';
axis square
% fontsize(12,'points')
savePlot(append(prefixStr,'modelMeshgrid'),figDir)

% % Make animations
% anim1 = 1;
% anim2 = 0;
% animationMaker;
% anim1 = 0;
% anim2 = 1;
% animationMaker;

% Plot the "first" blast time step
% [~, blastStartTidx] = min(abs(tspan-t00));
% idx = 1;
% [~, idx] = min(abs(x-15));
plotSpecificDist;
% figure(5);
% set(gcf,'color','w')
% subplot(1,2,1)
% % h3 = plot(X(:,idx), 0.001*pressure(:,idx), 'LineWidth', lw);
% % h3 = plot(X(idx,:), 0.001*pressure(idx,:), 'LineWidth', lw);
% % h3 = plot(X(idx,:), 0.001*pressure(:,idx), 'LineWidth', lw);
% h3 = plot(1000*T(:,idx), 0.001*pressure(:,idx), 'LineWidth', lw);
% grid on
% xlabel('Time (ms)')
% ylabel('Pressure (kPa)');
% 
% subplot(1,2,2)
% % h4 = plot(X(:,idx), mach2ms*velocity(:,idx), 'LineWidth', lw);
% h4 = plot(T(:,idx), mach2ms*velocity(:,idx), 'LineWidth', lw);
% % h4 = plot(X(idx,:), mach2ms*velocity(idx,:), 'LineWidth', lw);
% % h4 = plot(X(idx,:), mach2ms*velocity(:,idx), 'LineWidth', lw);
% grid on
% xlabel('Time (ms)')
% ylabel('Velocity (m/s)');
% savePlot('firstTimeStep_pandv_vs_t',figDir)

%% Make surface plots for all other variables
% Sadovskiy pressures
figure(10);
set(gcf,'color','w')
ax1 = subplot(2, 3, 1);
cb = plotMeshOnSubplot(ax1,X,T,all_Ps);
grid off
% xlabel('Distance (m)');
ylabel('Time (s)');
cb.Label.String = 'Ps (kPa) (sadovskiy)';
axis square

% Sadovskiy time constants
ax2 = subplot(2, 3, 2);
cb = plotMeshOnSubplot(ax2,X,T,all_tau);
% xlabel('Distance (m)');
% ylabel('Time (s)');
cb.Label.String = 'tau (sec) (sadovskiy)';
axis square

% Dewey Vs
ax3 = subplot(2, 3, 3);
cb = plotMeshOnSubplot(ax3,X,T,all_V);
% xlabel('Distance (m)');
% ylabel('Time (s)');
cb.Label.String = 'V (dewey)';
axis square

% Dewey alpha
ax4 = subplot(2, 3, 4);
cb = plotMeshOnSubplot(ax4,X,T,all_alpha);
xlabel('Distance (m)');
ylabel('Time (s)');
cb.Label.String = 'alpha (dewey)';
axis square

% Dewey beta
ax5 = subplot(2, 3, 5);
cb = plotMeshOnSubplot(ax5,X,T,all_beta);
xlabel('Distance (m)');
% ylabel('Time (s)');
cb.Label.String = 'beta (dewey)';
axis square

% Dewey a
ax6 = subplot(2, 3, 6);
cb = plotMeshOnSubplot(ax6,X,T,all_a);
xlabel('Distance (m)');
% ylabel('Time (s)');
cb.Label.String = 'a (dewey)';
axis square
savePlot(append(prefixStr,'modelParams'),figDir)

% Save the data so you don't have to re-process it later
save(append(prefixStr, 'processedData.mat'), 'pressure', 'velocity', 'all_Ps', 'all_tau', 'all_V', 'all_alpha', 'all_beta', 'all_a');
% close(hbar);