clf; clc; clear all; close all;

%% ========================= User controls =========================
% General parameters
W = 10;              % mass of explosive [kg]
c = 343;             % speed of sound [m/s]
mach2ms = 343;       % mach to m/s

% Mesh/plot window controls
x0  = 0.1;           % minimum distance [m]
xf  = 2.5;           % maximum distance shown in blast plots [m]
t00 = 2e-04;         % initial time [s]
tf  = 0.01;          % maximum time shown in blast plots [s]
N   = 500;           % mesh resolution

set(groot, 'defaultAxesLabelFontSizeMultiplier', 1)
set(groot, 'defaultAxesTitleFontWeight', 'normal')

% Import the best fit propagation speed
propSpeedData = load("cBestFitVars.mat");
cF = propSpeedData.f;

% Slice plot control
xSlice = 15;         % desired distance for time-history slice [m]
lw = 1.2;            % line width for slice plots

% Font sizes
fntSz = 12;          % everything except tick labels
tckSz = 10;          % tick labels
fontSizes.fntSz = fntSz;
fontSizes.tckSz = tckSz;

% BlastFoam data directory
blastDataDir = 'blastFoamDataPlotting/processedData10kgFine';

% Save directory
figDir = 'meshgridPandV';
mkdir(figDir)

%% ========================= Load BlastFoam data =========================
dirInfo = dir(fullfile(blastDataDir, '*.csv'));
filenames = string({dirInfo.name});

blastData.Umag = table2array(readtable(fullfile(blastDataDir, filenames(1)), 'NumHeaderLines', 1));
blastData.overpressure = table2array(readtable(fullfile(blastDataDir, filenames(2)), 'NumHeaderLines', 1));
blastData.radii = table2array(readtable(fullfile(blastDataDir, filenames(3)), 'NumHeaderLines', 1));
blastData.radii = blastData.radii(:,1);
blastData.times = table2array(readtable(fullfile(blastDataDir, filenames(4)), 'NumHeaderLines', 1));

% Trim raw arrays to time vector length
blastData.Umag = blastData.Umag(:,1:length(blastData.times));
blastData.overpressure = blastData.overpressure(:,1:length(blastData.times));

% Crop BlastFoam data to requested plotting window
xMask = blastData.radii >= x0 & blastData.radii <= xf;
tMask = blastData.times >= t00 & blastData.times <= tf;

blastRadiiCrop = blastData.radii(xMask);
blastTimesCrop = blastData.times(tMask);

% Convert to time x distance so it matches meshgrid(X,T) style
blastPressure_kPa = 0.001 * blastData.overpressure(xMask, tMask)';   % [kPa]
blastVelocity_ms = blastData.Umag(xMask, tMask)';                    % [m/s]

[Xbf, Tbf] = meshgrid(blastRadiiCrop, blastTimesCrop);

%% ========================= Parallel model calculations =========================
% Start a parallel pool if needed
pool = gcp('nocreate');
if isempty(pool)
    parpool;
end

% Non-propagated model
[Xnp, Tnp, pressureNP, velocityNP, all_Ps_np, all_tau_np, all_V_np, all_alpha_np, all_beta_np, all_a_np] = ...
    calcModelGrid(W, cF, x0, xf, t00, tf, N, 0);

% Propagated model
[Xp, Tp, pressureP, velocityP, all_Ps_p, all_tau_p, all_V_p, all_alpha_p, all_beta_p, all_a_p] = ...
    calcModelGrid(W, cF, x0, xf, t00, tf, N, 1);

%% ========================= Figure 1: full-width MDPI-style layout =========================
% Rows = {Pressure, Velocity}
% Cols = {Non-propagated, Propagated, BlastFoam}

% Convert model outputs to plotting units
pressureNP_kPa = 0.001 * pressureNP;
pressureP_kPa  = 0.001 * pressureP;
velocityNP_ms  = mach2ms * velocityNP;
velocityP_ms   = mach2ms * velocityP;

xLimits = [x0 xf];
yLimits = [blastTimesCrop(1) tf] * 1000;

% Shared color limits across each row
pMin = 0;
pMax = 1e4;

vMin = min([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);
vMax = max([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);

%% ========================= Figure 1: cleaned final layout =========================
% Convert model outputs to plotting units
pressureNP_kPa = 0.001 * pressureNP;
pressureP_kPa  = 0.001 * pressureP;
velocityNP_ms  = mach2ms * velocityNP;
velocityP_ms   = mach2ms * velocityP;

xLimits = [x0 xf];
yLimits = [blastTimesCrop(1) tf] * 1000;

% Shared color limits across each row
pMin = 0;
pMax = 1e4;

vMin = min([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);
vMax = max([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);

figure(1);
set(gcf, 'Color', 'w', 'Units', 'inches', 'Position', [1, 1, 7.0, 4.8]);

t = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
colormap("turbo")

colTitleSz = 11;

% ---------------- Pressure row ----------------
ax1 = nexttile;
plotMeshPanel(ax1, Xnp, 1000*Tnp, pressureNP_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('Non-prop','FontSize',colTitleSz)
ylabel('Time (ms)','FontSize',fntSz)

ax2 = nexttile;
plotMeshPanel(ax2, Xp, 1000*Tp, pressureP_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('Prop','FontSize',colTitleSz)

ax3 = nexttile;
plotMeshPanel(ax3, Xbf, 1000*Tbf, blastPressure_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('BlastFoam','FontSize',colTitleSz)

% Shared pressure colorbar
cb1 = colorbar(ax3,'eastoutside');
cb1.Label.String = 'Pressure (kPa)';
cb1.FontSize = tckSz;
cb1.Label.FontSize = fntSz;
cb1.Ruler.Exponent = 0;
cb1.Ticks = linspace(pMin, pMax, 5);

% ---------------- Velocity row ----------------
ax4 = nexttile;
plotMeshPanel(ax4, Xnp, 1000*Tnp, velocityNP_ms, [vMin vMax], xLimits, yLimits, fontSizes);
ylabel('Time (ms)','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)

ax5 = nexttile;
plotMeshPanel(ax5, Xp, 1000*Tp, velocityP_ms, [vMin vMax], xLimits, yLimits, fontSizes);
xlabel('Distance (m)','FontSize',fntSz)

ax6 = nexttile;
plotMeshPanel(ax6, Xbf, 1000*Tbf, blastVelocity_ms, [vMin vMax], xLimits, yLimits, fontSizes);
xlabel('Distance (m)','FontSize',fntSz)

% Shared velocity colorbar
cb2 = colorbar(ax6,'eastoutside');
cb2.Label.String = 'Velocity (m/s)';
cb2.FontSize = tckSz;
cb2.Label.FontSize = fntSz;
cb2.Ruler.Exponent = 0;
cb2.Ticks = linspace(vMin, vMax, 5);

savePlott('updatedModelMesh_fullwidth', '.')

%% ========================= Optional time-history slice plot =========================
% Use the nearest available x location in the requested window
[~, idxSlice] = min(abs(Xp(1,:) - min(max(xSlice, x0), xf)));

figure(5);
set(gcf, 'Color', 'w', 'Units', 'inches', 'Position', [1, 1, 6.8, 2.8]);

t2 = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile
plot(Tp(:,idxSlice), 0.001*pressureP(:,idxSlice), 'LineWidth', lw)
grid on
xlabel('Time (s)','FontSize',fntSz)
ylabel('Pressure (kPa)','FontSize',fntSz)
title(sprintf('Propagated Model at x = %0.2f m', Xp(1,idxSlice)),'FontSize',fntSz)
ax = gca;
ax.FontSize = tckSz;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 0;
xticks(linspace(t00, tf, 5))

nexttile
plot(Tp(:,idxSlice), mach2ms*velocityP(:,idxSlice), 'LineWidth', lw)
grid on
xlabel('Time (s)','FontSize',fntSz)
ylabel('Velocity (m/s)','FontSize',fntSz)
title(sprintf('Propagated Model at x = %0.2f m', Xp(1,idxSlice)),'FontSize',fntSz)
ax = gca;
ax.FontSize = tckSz;
ax.XAxis.Exponent = 0;
ax.YAxis.Exponent = 0;
xticks(linspace(t00, tf, 5))

savePlott('propagated_slice_pandv_vs_t', figDir)

%% ========================= Model parameter meshgrid figure =========================
% Keep parameter plots for the propagated model
figure(10);
set(gcf,'Color','w', 'Units','inches', 'Position',[1, 1, 6.8, 5.0]);

t3 = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
colormap("turbo")

ax1 = nexttile;
plotMeshPanel(ax1, Xp, 1000*Tp, all_Ps_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax1, Xp, Tp, all_Ps_p, [], 'Ps (Pa)', xLimits, yLimits, fontSizes);
title('Sadovskiy P_s','FontSize',fntSz)
ylabel('Time (s)','FontSize',fntSz)

ax2 = nexttile;
plotMeshPanel(ax2, Xp, 1000*Tp, all_tau_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax2, Xp, Tp, all_tau_p, [], '\tau (s)', xLimits, yLimits, fontSizes);
title('Sadovskiy \tau','FontSize',fntSz)

ax3 = nexttile;
plotMeshPanel(ax3, Xp, 1000*Tp, all_V_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax3, Xp, Tp, all_V_p, [], 'V_s', xLimits, yLimits, fontSizes);
title('Dewey V_s','FontSize',fntSz)

ax4 = nexttile;
plotMeshPanel(ax4, Xp, 1000*Tp, all_alpha_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax4, Xp, Tp, all_alpha_p, [], '\alpha', xLimits, yLimits, fontSizes);
title('Dewey \alpha','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)
ylabel('Time (s)','FontSize',fntSz)

ax5 = nexttile;
plotMeshPanel(ax5, Xp, 1000*Tp, all_beta_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax5, Xp, Tp, all_beta_p, [], '\beta', xLimits, yLimits, fontSizes);
title('Dewey \beta','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)

ax6 = nexttile;
plotMeshPanel(ax6, Xp, 1000*Tp, all_a_p, [], xLimits, yLimits, fontSizes);
% plotMeshPanel(ax6, Xp, Tp, all_a_p, [], 'a', xLimits, yLimits, fontSizes);
title('Dewey a','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)

savePlott('propagated_modelParams', figDir)

%% ========================= Save processed data =========================
save(fullfile(figDir, 'modelMeshgrid_with_blastFoam_processedData.mat'), ...
    'Xnp', 'Tnp', 'pressureNP', 'velocityNP', ...
    'Xp', 'Tp', 'pressureP', 'velocityP', ...
    'Xbf', 'Tbf', 'blastPressure_kPa', 'blastVelocity_ms', ...
    'all_Ps_np', 'all_tau_np', 'all_V_np', 'all_alpha_np', 'all_beta_np', 'all_a_np', ...
    'all_Ps_p', 'all_tau_p', 'all_V_p', 'all_alpha_p', 'all_beta_p', 'all_a_p', ...
    'x0', 'xf', 't00', 'tf', 'N', 'xSlice');

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

function plotMeshPanel(ax, X, T, Z, climVals, xLimits, yLimits, fontSizes)
    axes(ax);
    pcolor(X, T, Z)
    shading interp
    axis normal
    grid off
    box on

    tckSz = fontSizes.tckSz;

    xlim(xLimits)
    ylim(yLimits)

    xticks(linspace(xLimits(1), xLimits(2), 5))
    yticks(linspace(yLimits(1), yLimits(2), 5))

    xtickformat('%.2f')
    ytickformat('%.2f')

    ax.FontSize = tckSz;
    ax.XAxis.Exponent = 0;
    ax.YAxis.Exponent = 0;
    ax.TitleHorizontalAlignment = 'center';
    ax.XTickLabelRotation = 0;

    if ~isempty(climVals)
        clim(ax, climVals)
    end
end

function savePlott(plotName, dirName)
% Function to save the plots as a pdf
% Input:
%    plotName = string for the name of the plot
%    dirName = name of target save directory

set(gcf,'Color','w');
set(gcf,'Units','inches');

% Make sure output folder exists
if ~exist(dirName,'dir')
    mkdir(dirName);
end

outFile = fullfile(dirName, plotName + ".pdf");

% exportgraphics is generally more reliable for tiledlayout/colorbars
exportgraphics(gcf, outFile, 'ContentType', 'vector', 'BackgroundColor', 'white');

outFile = fullfile(dirName, plotName + ".png");
exportgraphics(gcf, outFile, 'ContentType', 'vector', 'BackgroundColor', 'white');
end