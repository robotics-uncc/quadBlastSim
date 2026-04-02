clf;clc;clear all;close all;

% Testing parameters
dF = sqrt(10^2 + 10^2);
% dVals = linspace(1,dF,100);
% dVals = 14;
tf = 0.1;

% Flags
dataFit_Pressure = 1;
dataFit_velocity = 1;
dataFit_propagationSpeed = 1;

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

% Setup a sweep for the selected W's and d's
dN = length(dVals);
subplotN = linspace(1,dN,dN);
figw = 12;
figh = 4;
lw = 1.4;
if dataFit_Pressure == 1
for bbb = 1:dN
    %% Clear and close the plot
    % clf;close all;
    
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

    % Calcualte scaled distance
    crW = W^(1/3);
    scaledDist(bbb) = d/crW;

    % Get initial parameter values
    [Ps_i(bbb), tau_i(bbb)] = sadovskiy(W,scaledDist(bbb));

    % Pack the parameters into an IC input for the optimization
    modelPParams = [Ps_i(bbb), t0_i(bbb), tau_i(bbb)];
    PparamIC = [PsStd,t0_i(bbb),1/200];
    
    % Get t0 based on the approximate first near zero overpressure value
    % see this plot for what to use (figure();plot(blastData.times(1:maxPsIdx+10),pressureVals(1:maxPsIdx+10)))
    t0 = blastData.times(maxPsIdx);

    % Interpolate the parameters for the velocity equation
    [Vs_i(bbb), alpha_i(bbb), beta_i(bbb), a_i(bbb), ~] = deweyParams(scaledDist(bbb));
    DT = t-t0;

    % Scale times
    scaledTime = c*(DT)/W;

    % Calculate heaviside values
    sympref('HeavisideAtOrigin', 1);
    hval = ceil(heaviside(t-t0));

    % Pack the parameters into an IC input for the optimization
    VparamIC = [Vs_i(bbb), alpha_i(bbb), beta_i(bbb), a_i(bbb)];

    % Calculate pressure
    modelP(bbb,:) = Pmodel(modelPParams,t);

    % Calculate velocity
    modelV(bbb,:) = Vmodel(VparamIC,scaledTime,hval);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRESSURE MODEL OPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Pressure parameter Optimization    
    % Run fmincon
    % optParam = fmincon(@(x)deweyOpt(x,currParams), paramIC, [], [], [], [], lb, ub);

    % Run lsqcurvefit
    options = optimoptions('lsqcurvefit','Algorithm','interior-point');
    lb = [];
    ub = [];
    % optParam = lsqcurvefit(@(x,xdata)abs(Pmodel(x,xdata)), [5000, 0.05, 1/200], t', abs(blastData.overpressure(blastData.nearIdx,:)),lb,ub,options);
    optParamP = lsqcurvefit(@(x,xdata)(abs(Pmodel(x,xdata))), PparamIC, t', abs(blastData.overpressure(blastData.nearIdx,:)),lb,ub,options);

    % Unpack to store the params
    Ps_opt(bbb) = optParamP(1);
    t0_opt(bbb) = optParamP(2);
    tau_opt(bbb) = optParamP(3);

    %% Calculate the pressure model based on the optimized parameters
    optP(bbb,:) = Pmodel(optParamP,blastData.times);

    %% Plot the model, the data, and the optimized model ----- PRESSURE ONLY
    figP = figure(1);
    set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
    set(figP,'Color','w','Position',[0 3 figw figh],'Units','inches')
    subplot(1,3,subplotN(bbb))
    fntSize = 16;
    ax.FontSize = fntSize;
    plot(t*1000,0.001*blastData.overpressure(blastData.nearIdx,:),'DisplayName','CFD','LineWidth',lw,'LineStyle','-.','Color','k')
    hold on
    plot(t*1000,0.001*modelP(bbb,:), 'DisplayName','Model','LineWidth',lw,'LineStyle',':', 'Color','r')
    plot(t*1000,0.001*optP(bbb,:),'DisplayName','Fit','LineWidth',lw,'LineStyle','--', 'Color','b')
    grid on
    xlabel('$t$ (ms)')
    if bbb == 1
        ylabel('$P_{0}$ (kPa)')
    end
    title(sprintf('$r$ = %2.0f m',d),'Interpreter','latex')
    % legend('Location','best')
    xticks(linspace(0, tf*1000,5))
    xlim([0, tf*1000])
    % ylim([min(blastData.overpressure(blastData.nearIdx,:)),max(blastData.overpressure(blastData.nearIdx,:))])
    % savePlot(append('pCompAtd', strrep(string(d),'.',',')),optFitFigs)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VELOCITY MODEL OPT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Parameter Optimization - VELOCITY ONLY
    % Setup input - t0 might change throughout the data
    currParams.t0 = t0;
    currParams.dataV = blastData.Umag(blastData.nearIdx,:);
    
    % Run fmincon
    % optParam = fmincon(@(x)deweyOpt(x,currParams), paramIC, [], [], [], [], lb, ub);

    % Run lsqcurvefit
    lb = [0, 0, 0, 0];
    ub = [1, 1, 1, 1]*5;
    optParamV = lsqcurvefit(@(x,xdata)deweyOpt2(x,xdata,currParams), VparamIC, scaledTime, currParams.dataV, lb, ub, [], [], [], []);

    % Unpack to store the params
    Vs_opt(bbb) = optParamV(1);
    alpha_opt(bbb) = optParamV(2);
    beta_opt(bbb) = optParamV(3);
    a_opt(bbb) = optParamV(4);

    %% Calculate the velocity model based on the optimized parameters
    optV(bbb,:) = Vmodel(optParamV,scaledTime,hval);

    %% Plot the model, the data, and the optimized model
    figV = figure(2);
    set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
    set(figV,'Color','w','Position',[0 3 figw figh],'Units','inches')
    subplot(1,3,subplotN(bbb))
    ax.FontSize = fntSize;
    plot(t*1000,blastData.Umag(blastData.nearIdx,:),'DisplayName','CFD','LineWidth',lw,'LineStyle','-.','Color','k')
    hold on
    plot(t*1000,modelV(bbb,:)*mach2ms, 'DisplayName','Model','LineWidth',lw,'LineStyle',':', 'Color','r')
    plot(t*1000,optV(bbb,:)*mach2ms,'DisplayName','Fit','LineWidth',lw,'LineStyle','--', 'Color','b')
    grid on
    xlabel('$t$ (ms)')
    if bbb == 1
        ylabel('$V$ (m/s)')
    end
    title(sprintf('$r$ = %2.0f m',d),'Interpreter','latex')
    xticks(linspace(0, tf*1000,5))
    % if bbb == 1
    %     yticks(round(linspace(0,max(modelV(bbb,:)*mach2ms),5),-2))
    % else
    %     yticks(round(linspace(0,max(modelV(bbb,:)*mach2ms),5),-1))
    % end
    % yticks(linspace(0,round(max(modelV(bbb,:)*mach2ms),-2),5))
    % xlim([0, tf*1000])
    % savePlot(append('vCompAtd', strrep(string(d),'.',',')),optFitFigs)

    % Pause
    1;
end

% Finalize pressure plot
figP = figure(1);
fontsize(16,"points")
legend('Location','best')
savePlot(append('pComps'),optFitFigs)

% Finalize velcoity plot
figV = figure(2);
fontsize(16,"points")
legend('Location','best')
savePlot(append('vComps'),optFitFigs)
end

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
if dataFit_velocity == 1
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
    % t0_i(bbb) = blastData.times(maxPsIdx);
    t0_i(bbb) = 0.001;

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
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% C PLOT - blastFoam DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% dRange = 5:0.015:29.5;
% % dRange = 5:0.015:20;
diffX = diff(blastData.radii);
dRange = min(blastData.radii):mean(diffX(diffX~=0)):max(blastData.radii);
L = 0.5;
dValsList = [dRange' dRange'+L];
cFigsDir = append(optFitFigs,'cFigs/');
mkdir(cFigsDir)
cVals = zeros(length(dValsList),2);
makeCPlots = 0;

if dataFit_propagationSpeed == 1
% for ccc = 1:1
for ccc = 1:length(dValsList)
% dVals = [15 15.5];
dVals = dValsList(ccc,:);
dN = length(dVals);
t = blastData.times;
t0s = zeros(dN,1);
for bbb = 1:dN
    %% Clear and close the plot
    % clf;close all;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA GATHERING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Calculate model velocity    
    % Set values for this loop
    d = dVals(bbb);
    
    % Find the value nearest to d in the blast radii data - https://www.mathworks.com/matlabcentral/answers/194618-how-to-find-the-index-of-the-closest-value-to-some-number-in-1d-array
    [~, blastData.nearIdx] = min(abs(blastData.radii-d));
    blastR = blastData.radii(blastData.nearIdx);
    
    % Get peak overpressure based on nearest radii index
    [PsStd, maxPsIdx] = max(blastData.overpressure(blastData.nearIdx,:));

    % Get t0 for this loop
    t0 = blastData.times(maxPsIdx);

    % Get velocity data
    currParams.t0 = t0;
    currParams.dataV = blastData.Umag(blastData.nearIdx,:);
    
    % Gather t0's to calculate c
    t0s(bbb) = t0;

    % Calculate c
    if bbb == 2
        % [~, Pidx1] = max(modelP(1,:));
        % [~, Pidx2] = max(modelP(2,:));
        dT = t0s(2)-t0s(1);
        dX = dVals(2)-dVals(1);
        c = dX/dT;
    end

    %% Make the plots
    if makeCPlots == 1
        figV = figure(4);
        set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
        set(figV,'Color','w','Position',[0 3 figw figh],'Units','inches')
        
        subplot(1,3,1)
        fntSize = 16;
        ax.FontSize = fntSize;
        plot(t*1000,0.001*blastData.overpressure(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb))
        hold on
        grid on
        xlabel('$t$ (ms)')
        % title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
        % legend('Location','best')
        if bbb == 1
            ylabel('$P_{0}$ (kPa)')
            xticks(linspace(0, tf*1000,5))
            xlim([0, tf*1000])
        end
        
        subplot(1,3,2)
        ax.FontSize = fntSize;
        plot(t*1000,blastData.Umag(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb),'DisplayName',append('$r =$ ',string(dVals(bbb)), ' m'))
        hold on
        grid on
        xlabel('$t$ (ms)')
        % title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
        if bbb == 1
            ylabel('$V$ (m/s)')
            yticks(linspace(0,round(max(blastData.Umag(blastData.nearIdx,:)),-1),5))
            xticks(linspace(0, tf*1000,5))
            xlim([0, tf*1000])
            ylim([0,round(max(blastData.Umag(blastData.nearIdx,:)),-1)])
        end
    end
end

% Collect c's
cVals(ccc,:) = [dVals(1) c];

% Finalize pressure plot
if makeCPlots == 1
    figP = figure(4);
    fontsize(16,"points")
    legend('Location','best')
    text(60,max(blastData.Umag(blastData.nearIdx,:))*1/2,sprintf('$c$ = %2.2f m/s',c),'FontSize',14)
    savePlot(append('cCalc',string(dVals(1)),'m'),cFigsDir)
    clf(4)
end
end

% Calculate a best fit line for the c's
[~,fitStart] = max(round(cVals(:,1),1)==0.1);
[~,fitEnd] = max(round(cVals(:,1),1)==25);
fitEnd = size(cVals,1) - fitEnd;
rows = fitStart:size(cVals,1)-fitEnd;
subset = cVals(fitStart:end-fitEnd,2);
mask = isfinite(subset);
% fitType = 'fourier3';
% fitType = 'poly9';
% fitType = 'exp2';
% fitType = 'gauss2';
fitType = 'power2';
% fitType = 'weibull';
f = fit(cVals(rows(mask),1),cVals(rows(mask),2),fitType);
confIntVals = confint(f);
cValFit = f(cVals(:,1));
cValFit1sigPos = confIntVals(2,1)*(cVals(:,1).^confIntVals(2,2)) + confIntVals(2,3);
cValFit1sigNeg = confIntVals(1,1)*(cVals(:,1).^confIntVals(1,2)) + confIntVals(1,3);

% f = fit(cVals(:,1),cVals(:,2),'power2');
% confIntVals = confint(f);
% cValFit = f.a*(cVals(:,1).^f.b) + f.c;
% cValFit1sigPos = confIntVals(2,1)*(cVals(:,1).^confIntVals(2,2)) + confIntVals(2,3);
% cValFit1sigNeg = confIntVals(1,1)*(cVals(:,1).^confIntVals(1,2)) + confIntVals(1,3);


%% Calculate model velocity    
ccc = 801;
dVals = dValsList(ccc,:);
dN = length(dVals);
t = blastData.times;
t0s = zeros(dN,1);
for bbb = 1:dN

% Set values for this loop
d = dVals(bbb);

% Find the value nearest to d in the blast radii data - https://www.mathworks.com/matlabcentral/answers/194618-how-to-find-the-index-of-the-closest-value-to-some-number-in-1d-array
[~, blastData.nearIdx] = min(abs(blastData.radii-d));
blastR = blastData.radii(blastData.nearIdx);

% Get peak overpressure based on nearest radii index
[PsStd, maxPsIdx] = max(blastData.overpressure(blastData.nearIdx,:));

% Get t0 for this loop
t0 = blastData.times(maxPsIdx);

% Get velocity data
currParams.t0 = t0;
currParams.dataV = blastData.Umag(blastData.nearIdx,:);

% Gather t0's to calculate c
t0s(bbb) = t0;

% Calculate c
if bbb == 2
    % [~, Pidx1] = max(modelP(1,:));
    % [~, Pidx2] = max(modelP(2,:));
    dT = t0s(2)-t0s(1);
    dX = dVals(2)-dVals(1);
    c = dX/dT;
end

% Make a quick plot to show how c changes with distance
figC = figure(4);
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
set(figC,'Color','w','Position',[0 3 13.5 figh],'Units','inches')
% set(figV,'Color','w','Position',[0 3 14 4.5],'Units','inches')

subplot(1,3,1)
fntSize = 16;
ax.FontSize = fntSize;
plot(t*1000,0.001*blastData.overpressure(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb),'DisplayName',append('$r =$ ',string(dVals(bbb)), ' m'))
hold on
grid on
xlabel('$t$ (ms)')
% title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
% legend('Location','best')
if bbb == 1
    ylabel('$P_{0}$ (kPa)')
    xticks(linspace(0, tf*1000,5))
    xlim([0, tf*1000])
end
legend('Location','best')

subplot(1,3,2)
ax.FontSize = fntSize;
plot(t*1000,blastData.Umag(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb),'DisplayName',append('$r =$ ',string(dVals(bbb)), ' m'))
hold on
grid on
xlabel('$t$ (ms)')
% title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
if bbb == 1
    ylabel('$V$ (m/s)')
    yticks(linspace(0,round(max(blastData.Umag(blastData.nearIdx,:)),-1),5))
    xticks(linspace(0, tf*1000,5))
    xlim([0, tf*1000])
    ylim([0,max(blastData.Umag(blastData.nearIdx,:))])
end
fontsize(16,"points")
% legend('Location','best')
% title(sprintf('$c$ = %2.2f m/s',c))

% Update the plot
figC = figure(5);
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
set(figC,'Color','w','Position',[0 3 3.5 5],'Units','inches')
% set(figV,'Color','w','Position',[0 3 14 4.5],'Units','inches')

subplot(2,2,1)
fntSize = 10;
ax.FontSize = fntSize;
plot(t*1000,0.001*blastData.overpressure(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb),'DisplayName',append('$r =$ ',string(dVals(bbb)), ' m'))
hold on
grid on
xlabel('Time (ms)')
% title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
% legend('Location','best')
if bbb == 1
    ylabel('$P_{0}$ (kPa)')
    xticks(linspace(0, tf*1000,5))
    xlim([0, tf*1000])
end
leg = legend('Location','south');
leg.Position = [0.16 0.62 0.3427 0.0951];
% legend('Location','best')
fontsize(10,"points")

subplot(2,2,2)
ax.FontSize = fntSize;
plot(t*1000,blastData.Umag(blastData.nearIdx,:),'LineWidth',lw,'LineStyle',':', 'Color',colors(bbb),'DisplayName',append('$r =$ ',string(dVals(bbb)), ' m'))
hold on
grid on
xlabel('Time (ms)')
% title(sprintf('$c$ = %2.2f m/s',c),'Interpreter','latex')
if bbb == 1
    ylabel('$V$ (m/s)')
    yticks(linspace(0,round(max(blastData.Umag(blastData.nearIdx,:)),-1),5))
    xticks(linspace(0, tf*1000,5))
    xlim([0, tf*1000])
    ylim([0,max(blastData.Umag(blastData.nearIdx,:))])
end
fontsize(10,"points")
% legend('Location','best')
% title(sprintf('$c$ = %2.2f m/s',c))


end
figC = figure(4);
subplot(1,3,3)
% set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
% set(figC,'Color','w','Position',[0 3 figw/2 figh],'Units','inches')
plot(cVals(:,1),cVals(:,2),'k.','DisplayName','Calcualted c')
hold on
plot(cVals(:,1),cValFit,'r--','DisplayName',sprintf('Fit = %2.0f (m/s)', cValFit(end)),'LineWidth',lw)
plot(cVals(:,1),cValFit1sigPos,'b--','DisplayName','$1\sigma$','LineWidth',lw)
plot(cVals(:,1),cValFit1sigNeg,'b--','HandleVisibility','off','LineWidth',lw)
xlabel('$r$ (m)')
ylabel('$c$ (m/s)')
grid on
xticks(5:5:round(max(cVals(:,1)),-1))
xlim([5,30])
legend('Location','best')
fontsize(16,"points")
savePlot(append('combinedcVsDsFig'),cFigsDir)

figC = figure(5);
subplot(2,2,[3 4])
% set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');
% set(figC,'Color','w','Position',[0 3 figw/2 figh],'Units','inches')
plot(cVals(:,1),cVals(:,2),'k.','DisplayName','Calcualted c')
hold on
plot(cVals(:,1),cValFit,'r--','DisplayName',sprintf('Fit = %2.0f (m/s)', cValFit(end)),'LineWidth',lw)
plot(cVals(:,1),cValFit1sigPos,'b--','DisplayName','$1\sigma$','LineWidth',lw)
plot(cVals(:,1),cValFit1sigNeg,'b--','HandleVisibility','off','LineWidth',lw)
xlabel('$r$ (m)')
ylabel('$c$ (m/s)') 
grid on
xticks(5:5:round(max(cVals(:,1)),-1))
xlim([5,30])
legend('Location','best')
fontsize(10,"points")
savePlot(append('combinedcVsDsFig_updated'),cFigsDir)

end