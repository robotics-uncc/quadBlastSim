% Clear everything
clear; clc; close all;
addpath('../')
figDir = 'figs';

% Formatting
set(groot, 'defaultAxesTitleFontWeight', 'normal');
set(groot, 'defaultAxesLabelFontSizeMultiplier', 1);
set(groot, 'defaultAxesTitleFontSizeMultiplier', 1);
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultColorbarFontName', 'Times New Roman');
set(groot, 'defaultTextInterpreter', 'none');
set(groot, 'defaultAxesTickLabelInterpreter', 'none');

% Load Data
if ~isfile('meshgridData.mat')
    error('Run generateMeshgridData.m first to create the data file.');
end
load('meshgridData.mat');

%% ========================= Setup Plot Limits =========================
xLimits = [x0 xf];
yLimits = [t00 tf] * 1000; % Convert to ms

% Shared color limits (Raw)
pMin_raw = -30;
pMax_raw = 120; % kPa 

vMin_raw = min([velocityNP_ms(:); velocityP_ms(:); velocityFit_ms(:); blastVelocity_ms(:)]);
vMax_raw = max([velocityNP_ms(:); velocityP_ms(:); velocityFit_ms(:); blastVelocity_ms(:)]);

% Calculate nice ticks and snap the absolute limits to them
pTicks = getNiceTicks(pMin_raw, pMax_raw);
pMin = pTicks(1); 
pMax = pTicks(end);

vTicks = getNiceTicks(vMin_raw, vMax_raw);
vMin = vTicks(1); 
vMax = vTicks(end);

% Calculate the 5 exact tick marks spanning the entire axes
xTickVals = linspace(xLimits(1), xLimits(2), 5);
yTickVals = linspace(yLimits(1), yLimits(2), 5);

%% ========================= Create Figure =========================
fig = figure('Name', 'Meshgrid Comparison');
t = tiledlayout(2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
colormap("turbo"); 

% --- ROW 1: PRESSURE ---
ax1 = nexttile;
plotMeshPanel(ax1, Xnp, 1000*Tnp, pressureNP_kPa, [pMin pMax], xLimits, yLimits, xTickVals, yTickVals);
title(ax1, 'Non-propagated');
ylabel(ax1, 'Time (ms)');
xticklabels(ax1, {}); % Remove x-ticks for top row

ax2 = nexttile;
plotMeshPanel(ax2, Xp, 1000*Tp, pressureP_kPa, [pMin pMax], xLimits, yLimits, xTickVals, yTickVals);
title(ax2, 'Propagated');
xticklabels(ax2, {}); yticklabels(ax2, {});

ax3 = nexttile;
plotMeshPanel(ax3, Xfit, 1000*Tfit, pressureFit_kPa, [pMin pMax], xLimits, yLimits, xTickVals, yTickVals);
title(ax3, 'Fitted');
xticklabels(ax3, {}); yticklabels(ax3, {});

ax4 = nexttile;
plotMeshPanel(ax4, Xbf, 1000*Tbf, blastPressure_kPa, [pMin pMax], xLimits, yLimits, xTickVals, yTickVals);
title(ax4, 'BlastFoam');
xticklabels(ax4, {}); yticklabels(ax4, {});

% Add and format pressure colorbar
cb1 = colorbar(ax4, 'eastoutside');
cb1.Label.String = 'Pressure (kPa)';
cb1.Ruler.Exponent = 0;
cb1.Ticks = pTicks;
cb1.TickLabels = arrayfun(@(x) sprintf('%g', x), pTicks, 'UniformOutput', false);

% --- ROW 2: VELOCITY ---
ax5 = nexttile;
plotMeshPanel(ax5, Xnp, 1000*Tnp, velocityNP_ms, [vMin vMax], xLimits, yLimits, xTickVals, yTickVals);
ylabel(ax5, 'Time (ms)');
xlabel(ax5, 'Distance (m)');

ax6 = nexttile;
plotMeshPanel(ax6, Xp, 1000*Tp, velocityP_ms, [vMin vMax], xLimits, yLimits, xTickVals, yTickVals);
xlabel(ax6, 'Distance (m)');
yticklabels(ax6, {});

ax7 = nexttile;
plotMeshPanel(ax7, Xfit, 1000*Tfit, velocityFit_ms, [vMin vMax], xLimits, yLimits, xTickVals, yTickVals);
xlabel(ax7, 'Distance (m)');
yticklabels(ax7, {});

ax8 = nexttile;
plotMeshPanel(ax8, Xbf, 1000*Tbf, blastVelocity_ms, [vMin vMax], xLimits, yLimits, xTickVals, yTickVals);
xlabel(ax8, 'Distance (m)');
yticklabels(ax8, {});

% Add and format velocity colorbar
cb2 = colorbar(ax8, 'eastoutside');
cb2.Label.String = 'Velocity (m/s)';
cb2.Ruler.Exponent = 0;
cb2.Ticks = vTicks;
cb2.TickLabels = arrayfun(@(x) sprintf('%g', x), vTicks, 'UniformOutput', false);

%% ========================= MDPI Formatting & Export =========================
formatMDPIFigure(fig, 'full');

% Export as a high-quality PDF
savePlot(fig, 'updatedModelMesh_2x4', figDir)


%% ========================= Local Functions =========================
function plotMeshPanel(ax, X, T, data, cLims, xLims, yLims, xTickVals, yTickVals)
    pcolor(ax, X, T, data);
    shading(ax, 'flat');
    
    if ~isempty(cLims)
        clim(ax, cLims);
    end
    
    % Enforce precise limits and exact 5-tick arrays
    xlim(ax, xLims);
    ylim(ax, yLims);
    xticks(ax, xTickVals);
    yticks(ax, yTickVals);
    
    % Force 1 decimal place format
    xtickformat(ax, '%.1f');
    ytickformat(ax, '%.1f');
end

function formatMDPIFigure(fig, sizeType)
    if nargin < 2; sizeType = 'full'; end
    
    fontName = 'Times New Roman'; 

    % Dynamically set layout and font size based on the figure size
    if strcmpi(sizeType, 'half')
        figWidth = 7.5;   
        figHeight = 5.0; 
        fontSize = 11; % Larger font for smaller physical figures
    else
        figWidth = 16; 
        figHeight = 8.5;  
        fontSize = 9;  % Standard 9pt font for full-page width figures
    end

    fig.Color = 'w'; 
    fig.Units = 'centimeters';
    fig.Position(3:4) = [figWidth, figHeight]; 

    % Apply strict formatting to all axes and their text children
    allAxes = findall(fig, 'type', 'axes');
    for i = 1:length(allAxes)
        ax = allAxes(i);
        ax.FontName = fontName;
        ax.FontSize = fontSize;
        ax.Box = 'on';           
        ax.LineWidth = 1.0;      
        ax.TickDir = 'in';       
        ax.XColor = 'k';         
        ax.YColor = 'k';
        
        % Force inner text properties explicitly
        ax.Title.FontWeight = 'normal';
        ax.Title.FontName = fontName;
        ax.Title.FontSize = fontSize;
        ax.Title.Interpreter = 'none';
        
        ax.XLabel.FontName = fontName;
        ax.XLabel.FontSize = fontSize;
        ax.XLabel.Interpreter = 'none';
        
        ax.YLabel.FontName = fontName;
        ax.YLabel.FontSize = fontSize;
        ax.YLabel.Interpreter = 'none';
    end

    % Apply strict formatting to all colorbars and their labels
    allCBs = findall(fig, 'type', 'colorbar');
    for i = 1:length(allCBs)
        cb = allCBs(i);
        cb.FontName = fontName;
        cb.FontSize = fontSize;
        cb.LineWidth = 1.0;
        cb.Color = 'k';
        
        % Target the colorbar label specifically
        cb.Label.FontWeight = 'normal';
        cb.Label.FontName = fontName;
        cb.Label.FontSize = fontSize;
        cb.Label.Interpreter = 'none';
    end
end