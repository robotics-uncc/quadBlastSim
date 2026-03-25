clf;clc;clear all;close all;

% Testing parameters
dF = sqrt(10^2 + 10^2);
% dVals = linspace(1,dF,100);
% dVals = 14;
tf = 0.1;

% Setup directory for figures
optFitFigs = 'optFitFigs/';
mkdir(optFitFigs)

% Get blast data filenames - https://www.mathworks.com/matlabcentral/answers/852330-converting-struct-field-to-array
% blastDataDir = 'blastFoamDataPlotting/processedData';
blastDataDir = 'blastFoamDataPlotting/processedData10kgFine';
dirInfo = dir(append(blastDataDir,'/*.csv'));
filenames = string({dirInfo.name});

% % Pull the data - blastFoamDataPlotting/processedData
% blastData.TOA = table2array(readtable(append(blastDataDir, '/', filenames(1)),'NumHeaderLines',1));
% blastData.Umag = table2array(readtable(append(blastDataDir, '/', filenames(5)),'NumHeaderLines',1));
% blastData.overpressure = table2array(readtable(append(blastDataDir, '/', filenames(6)),'NumHeaderLines',1));
% blastData.radii = table2array(readtable(append(blastDataDir, '/', filenames(7)),'NumHeaderLines',1));
% blastData.times = table2array(readtable(append(blastDataDir, '/', filenames(8)),'NumHeaderLines',1));

% Pull the data - blastFoamDataPlotting/processedData10kgFine
blastData.Umag = table2array(readtable(append(blastDataDir, '/', filenames(1)),'NumHeaderLines',1));
blastData.overpressure = table2array(readtable(append(blastDataDir, '/', filenames(2)),'NumHeaderLines',1));
blastData.radii = table2array(readtable(append(blastDataDir, '/', filenames(3)),'NumHeaderLines',1));
blastData.radii = blastData.radii(:,1);
blastData.times = table2array(readtable(append(blastDataDir, '/', filenames(4)),'NumHeaderLines',1));
blastData.Umag = blastData.Umag(:,1:length(blastData.times));
blastData.overpressure = blastData.overpressure(:,1:length(blastData.times));

% Set the radii to calculate at
dVals = [5 10 15];
% dVals = [3 6 9];
% dVals = blastData.radii([200 300]);
% dVals = blastData.radii(1:5:end);

% General params
% Ps = 10 * 1000; % peak overpressure, Pa
% tau = 1/200; % time constant in pressure wave, seconds
c = 360;% speed of wave, m/s
R = 0.15; % radius of sphere, meters
% t = linspace(0,tf,tf*2000); %times
t = blastData.times;
mach2ms = 343;
W = 10; % kg - weight of explosives

% Setup matrix to hold pressure models
modelP = zeros(length(dVals), length(t));
optP = zeros(length(dVals), length(t));

% Setup matrix to hold peak V values
modelV = zeros(length(dVals), length(t));
optV = zeros(length(dVals), length(t));

% initialize variables for pressure params
Ps_i = zeros(length(dVals),1);
t0_i = zeros(length(dVals),1);
tau_i = zeros(length(dVals),1);

% initialize variables to hold optimized pressure model params
Ps_opt = zeros(length(dVals),1);
t0_opt = zeros(length(dVals),1);
tau_opt = zeros(length(dVals),1);

% initialize variables for dewey params
Vs_i = zeros(length(dVals),1);
alpha_i = zeros(length(dVals),1);
beta_i = zeros(length(dVals),1);
a_i = zeros(length(dVals),1);
scaledDist = zeros(length(dVals));

% initialize variables to hold optimized model params
Vs_opt = zeros(length(dVals),1);
alpha_opt = zeros(length(dVals),1);
beta_opt = zeros(length(dVals),1);
a_opt = zeros(length(dVals),1);

% Setup opt input constants
currParams.times = blastData.times;
currParams.W = W;

% Setup bounds for params, based on x above and below the min/max dewey params respectively (see param fit sheet in drive)
% https://docs.google.com/spreadsheets/d/1_NkZsHRrwV47A8QFWSHvGOPzTEP2hYKrE6ib_uX87hw/edit?usp=sharing
% 50x
% lb = [-11.76, -10.094, -47.775, -10.29];
% ub = [52.02, 26.52, 63.342, 27.795];
% 5x
% lb = [-0.96, -0.824, -3.9, -0.84];
% ub = [6.12, 3.12, 7.452, 3.27];
% arbitrary
lb = [0, 0, 0];
ub = [100000000, 10, 1];

% General setup
dN = length(dVals);
subplotN = linspace(1,dN,dN);
figw = 12;
figh = 4;
lw = 1.4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% C PLOT - MODEL DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Make a plot that compares peak values from the model 0.5m away
dVals = [6 6.5];
dN = length(dVals);
colors = ['r', 'b'];
t = linspace(0,0.1,10000);

modelP = zeros(dN, length(t));
modelV = zeros(dN, length(t));
clear modelP modelV
for bbb = 1:dN
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Calculate model velocity    
    % Set values for this loop
    d = dVals(bbb);
    
    % Find the value nearest to d in the blast radii data - https://www.mathworks.com/matlabcentral/answers/194618-how-to-find-the-index-of-the-closest-value-to-some-number-in-1d-array
    [~, blastData.nearIdx] = min(abs(blastData.radii-d));
    blastR = blastData.radii(blastData.nearIdx);
    
    % Get peak overpressure based on nearest radii index
    [PsStd, maxPsIdx] = max(blastData.overpressure(blastData.nearIdx,:));
    
    % Get t0 based on the approximate first near zero overpressure value
    % see this plot for what to use (figure();plot(blastData.times(1:maxPsIdx+10),pressureVals(1:maxPsIdx+10)))
    t0_i(bbb) = blastData.times(maxPsIdx);
    % t0_i(bbb) = 0.001;

    % Calcualte scaled distance
    crW = W^(1/3);
    scaledDist(bbb) = d/crW;

    % Get initial parameter values
    [Ps_i(bbb), tau_i(bbb)] = sadovskiy(W,scaledDist(bbb));

    % Pack the parameters into an IC input for the optimization
    modelPParams = [Ps_i(bbb), t0_i(bbb), tau_i(bbb)];
    
    % Get t0 based on the approximate first near zero overpressure value
    % see this plot for what to use (figure();plot(blastData.times(1:maxPsIdx+10),pressureVals(1:maxPsIdx+10)))
    % t0 = blastData.times(maxPsIdx);
    t0 = 0.001;

    % Interpolate the parameters for the velocity equation
    [Vs_i(bbb), alpha_i(bbb), beta_i(bbb), a_i(bbb), ~] = deweyParams(scaledDist(bbb));
    DT = t-t0;

    % Scale times
    scaledTime = c*(t-t0)/crW;

    % Calculate heaviside values
    sympref('HeavisideAtOrigin', 1);
    hval = ceil(heaviside(t-t0));

    % Pack the parameters into an IC input for the optimization
    VparamIC = [Vs_i(bbb), alpha_i(bbb), beta_i(bbb), a_i(bbb)];

    % Calculate pressure
    modelP(bbb,:) = Pmodel(modelPParams,t);

    % Calculate velocity
    modelV(bbb,:) = Vmodel(VparamIC,scaledTime,hval);

    % Calculate c
    if bbb == 2
        [~, Pidx1] = max(modelP(1,:));
        [~, Pidx2] = max(modelP(2,:));
        dT = t(Pidx2)-t(Pidx1);
        dX = dVals(2)-dVals(1);
        c = dX/dT;
    end

    %% Make the plots
    figV = figure(3);
    set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
    set(figV,'Color','w','Position',[0 3 figw figh],'Units','inches')
    
    subplot(1,2,1)
    fntSize = 16;
    ax.FontSize = fntSize;
    plot(t*1000,0.001*modelP(bbb,:), 'DisplayName','Model Input','LineWidth',lw,'LineStyle',':', 'Color',colors(bbb))
    hold on
    grid on
    xlabel('$t$ (ms)')
    title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
    % legend('Location','best')
    if bbb == 1
        ylabel('$P_{0}$ (kPa)')
        xticks(linspace(0, tf*1000,5))
        xlim([0, tf*1000])
    end
    
    subplot(1,2,2)
    ax.FontSize = fntSize;
    plot(t*1000,modelV(bbb,:)*mach2ms, 'DisplayName','Model Input','LineWidth',lw,'LineStyle',':', 'Color',colors(bbb))
    hold on
    grid on
    xlabel('$t$ (ms)')
    title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
    if bbb == 1
        ylabel('$V$ (m/s)')
        yticks(linspace(0,max(modelV(bbb,:)*mach2ms),5))
        xticks(linspace(0, tf*1000,5))
        xlim([0, tf*1000])
    end
    % if bbb == 1
    %     yticks(round(linspace(0,max(modelV(bbb,:)*mach2ms),5),-2))
    % else
    %     yticks(round(linspace(0,max(modelV(bbb,:)*mach2ms),5),-1))
    % end
    
end
