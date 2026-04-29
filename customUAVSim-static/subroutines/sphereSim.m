% Clear workspace
clc; clf; clear all; close all;

%% Setup
wave.c = 360; % speed of wave, m/s
wave.t0 = 0; % time delay, seconds
wave.W = 10; % kg of explosive
d0 = 10; % m

% Setup sphere constants
sphere.R = 0.143; % radius of sphere, meters
sphere.Cd = 1.2; % coefficient of drag https://www.engineeringtoolbox.com/drag-coefficient-d_627.html
sphere.m = 1.25; % drone weight (kg) https://www.ed.ac.uk/airborne/airborne-research-and-innovation/unmanned-aircraft-systems-uas/unmanned-aircraft-systems-fleet/3dr-iris
sphere.rho = 1.225; % air density (kg/m^3) https://macinstruments.com/blog/what-is-the-density-of-air-at-stp/#:~:text=According%20to%20the%20International%20Standard,%3A%200.0765%20lb%2Fft%5E3

% Setup sim time
dt = 0.0001;
tf = 30;
tspan = 0:dt:tf;

% Setup initial conditions for dynamics, modeling the center of the sphere
x0 = d0;
xDot0 = 0;
IC = [x0; xDot0];

%% Simulation 
% Run through the sphereDynamics function again to get the pressure and velocity over time
t = tspan;
n = length(t);
xDot = IC';
for i = 2:length(tspan)
    % Get current time
    tCurr = t(i);

    % Unpack structure
    m = sphere.m;
    R = sphere.R;
    Cd = sphere.Cd;
    rho = sphere.rho;
    
    % Set blast angles
    phiB = 90;
    thetaB = 0;
    
    % Unpack wave structure
    c = wave.c;
    t0 = wave.t0;
    W = wave.W;
    
    % Unpack states
    x1 = xDot(i-1,1);
    x2 = xDot(i-1,2);
    
    % Get blast parameters based on sadovskiy models
    % [Ps, tau] = sadovskiy(W,scaledDist);
    % Ps = 0;
    Ps = 125000;
    tau = 0.006;
    
    % Calculate area for drag
    A = pi*R^2;
    
    % Calculate common values
    Dt = tCurr-t0;
    eps = Dt/tau;
    sympref('HeavisideAtOrigin', 1);
    hval = heaviside(Dt);
    
    % Calculate the velocity from the model, based on the parameters, and the current times
    pp = (Ps*exp(-eps).*(1-eps).*hval);
    
    % Get current force due to pressure based on x1
    eps = 0.0000001;
    x = linspace(-R,R);
    Fp = trapz(x,pp.*x.*sqrt((R+eps)^2+(x.^2)))*-pi/R;
    
    % Calculate the scaled distance
    mach2ms = 343;
    crW = (W)^(1/3);
    DT = tCurr-t0;
    dd = x1;
    scaledDist = dd/crW;
    scaledTime = c*DT/crW;
    
    % Interpolate the parameters for the velocity equation
    [Vs_i, alpha_i, beta_i, a_i, ~] = deweyParams(scaledDist);
    logVal = 1 + beta_i*scaledTime;
    if logVal < 0
        1;
    end
    V = mach2ms * ((Vs_i*(1-beta_i*scaledTime) * exp(-alpha_i*scaledTime) + a_i*log(1 + beta_i*scaledTime)) * exp(-scaledTime)*hval(1));
    
    % Calculate dynamcis
    vr = x2 - V;
    drag = -sign(vr)*(1/2)*rho*A*Cd*vr^2;
    x1Dot = x2;
    x2Dot = (Fp/m) + (drag/m);
    
    % Pack up and output
    xDot(i,:) = xDot(i-1,:) + dt*[x1Dot x2Dot];
end

%% Plots
lw = 1.2;

figh = figure();
set(groot, 'defaultAxesTickLabelInterpreter','latex'); 
set(groot, 'defaultLegendInterpreter','latex'); 
set(groot, 'defaultTextInterpreter','latex');
% set(gcf,'Color','white','Position',[0 0 500 400])
set(gcf,'Units','inches','Color','w','Position',[0 0 3.25 2.25])
subplot(2,1,1)
yyaxis left
plot(t(1:121)*1000,(xDot(1:121,1)-d0)*100,'k','LineWidth',1.2)
ylabel('$x_{1}$ (m)','Color','k')
set(gca,'YColor','k')
hold on
yyaxis right
plot(t(1:121)*1000,xDot(1:121,2),'LineWidth',1.2,'LineStyle','--')
% xlabel('Time (ms)')
ylabel('$x_{2}$ (m/s)')
xlim([0,12])
grid on

subplot(2,1,2)
plot(t,(xDot(:,1)-d0),'k','LineWidth',1.2)
yyaxis left
ylabel('$x_{1}$ (m)')
hold on
yyaxis right
plot(t,xDot(:,2),'LineWidth',1.2,'LineStyle','--')
xlabel('Time (sec)')
ylabel('$x_{2}$ (m/s)')
grid on

fontsize(figh, 10, "points")
set(gcf,'Color','w');
set(gcf,'Units','inches');
screenposition = get(gcf,'Position');
set(gcf,...
    'PaperPosition',[0 0 screenposition(3:4)],...
    'PaperSize',[screenposition(3:4)]);
saveas(gcf,'sphereStates.pdf')

