% plotPaperFigures.m
% Loads data, generates small square figures, applies annotations, and exports.
clear; clc; close all;
addpath('../')
addpath('../00_subroutines/')
figDir = 'figs';

% Load data
load('waveformData.mat');

% Convert t0 and tau to ms for plotting logic
t0_ms = t0 * 1000;
tau_ms = tau * 1000;

%% ================== FIGURE 1: OVERPRESSURE ==================
figA = figure('Name', 'Overpressure');
plot(t_ms, P_kPa, 'k-', 'LineWidth', 1.5);
hold on;
plot([t0_ms, t0_ms], [-150, 0], 'k--', 'LineWidth', 0.8); % t0 dashed line

% Formatting
formatSmallSquare(figA);
xlim([0 10.2]);
ylim([-1.5 10.5]);
yticks(0:2:10);

% Custom X-ticks replacing '1' with 't_0'
xticks([0, t0_ms, 2, 4, 6, 8, 10]);
xticklabels({'0', '$t_0$', '2', '4', '6', '8', '10'});

ylabel('Overpressure (kPa)');
xlabel('Time (ms)');

% Annotations for Pressure
ax = gca;

% Ps Text and Arrow
[xTail, yTail] = data2norm(ax, t0_ms + 1.5, 8.5);
[xHead, yHead] = data2norm(ax, t0_ms + 0.1, max(P_kPa) - 0.2);
annotation(figA, 'textarrow', [xTail xHead], [yTail yHead], ...
    'String', '$P_S$', 'Interpreter', 'latex', 'FontSize', 12, ...
    'HeadStyle', 'vback2', 'HeadLength', 6, 'HeadWidth', 6);

% tau red double arrow and text
[x1, y1] = data2norm(ax, t0_ms, 0);
[x2, y2] = data2norm(ax, t0_ms + tau_ms, 0);
annotation(figA, 'doublearrow', [x1 x2], [y1 y2], 'Color', 'r', ...
    'Head1Style', 'vback2', 'Head2Style', 'vback2', ...
    'Head1Length', 5, 'Head2Length', 5, 'Head1Width', 5, 'Head2Width', 5);
text(t0_ms + tau_ms/2, 1.0, '$\tau$', 'Color', 'r', 'Interpreter', 'latex', 'FontSize', 12, 'HorizontalAlignment', 'center');

% 8tau red double arrow and text
[x3, y3] = data2norm(ax, t0_ms + tau_ms, 0);
[x4, y4] = data2norm(ax, t0_ms + 9*tau_ms, 0); % 8*tau later
annotation(figA, 'doublearrow', [x3 x4], [y3 y4], 'Color', 'r', ...
    'Head1Style', 'vback2', 'Head2Style', 'vback2', ...
    'Head1Length', 5, 'Head2Length', 5, 'Head1Width', 5, 'Head2Width', 5);
text(t0_ms + 5*tau_ms, 1.0, '$8\tau$', 'Color', 'r', 'Interpreter', 'latex', 'FontSize', 12, 'HorizontalAlignment', 'center');

% Export
% exportgraphics(figA, 'Overpressure_Square.pdf', 'ContentType', 'vector');
savePlot(figA, 'Overpressure', figDir)

%% ================== FIGURE 2: NET FORCE ==================
figB = figure('Name', 'Net Force');
plot(t_ms, Fx, 'k-', 'LineWidth', 1.5);
hold on;
plot([t0_ms, t0_ms], [-150, 0], 'k--', 'LineWidth', 0.8); % t0 dashed line

% Formatting
formatSmallSquare(figB);
xlim([0 10.2]);
ylim([-500 750]);
yticks(-500:250:750);
% y_ticks = getNiceTicks(min(Fx), max(Fx));
% ylim([y_ticks(1) y_ticks(end)]);
% yticks(y_ticks);

% Custom X-ticks replacing '1' with 't_0'
xticks([0, t0_ms, 2, 4, 6, 8, 10]);
xticklabels({'0', '$t_0$', '2', '4', '6', '8', '10'});

ylabel('Net Force (N)');
xlabel('Time (ms)');

% Annotations for Force
ax2 = gca;
[xTail2, yTail2] = data2norm(ax2, 6.0, 140); 
[xHead2, yHead2] = data2norm(ax2, 5.0, 10); 
annotation(figB, 'textarrow', [xTail2 xHead2], [yTail2 yHead2], ...
    'String', sprintf('Rebound\nPositive\nForce'), ...
    'Interpreter', 'latex', 'FontSize', 11, ...
    'HeadStyle', 'vback2', 'HeadLength', 6, 'HeadWidth', 6, ...
    'HorizontalAlignment', 'center');

% Export
% exportgraphics(figB, 'NetForce_Square.pdf', 'ContentType', 'vector');
savePlot(figB, 'NetForce', figDir)

disp('Figures successfully generated and saved as PDFs.');

%% ================== LOCAL FUNCTIONS ==================
function formatSmallSquare(fig)
    % Forces the figure into a small square suitable for side-by-side LaTeX grids
    figWidth = 5.5; % cm
    figHeight = 5.5; % cm
    
    fig.Color = 'w';
    fig.Units = 'centimeters';
    fig.Position(3:4) = [figWidth, figHeight];
    
    ax = gca;
    ax.FontName = 'Times New Roman'; % Standard for math/physics journals
    ax.FontSize = 11;
    ax.TickLabelInterpreter = 'latex';
    ax.Box = 'on';
    ax.LineWidth = 1.0;
    ax.TickDir = 'in';
    ax.XColor = 'k';
    ax.YColor = 'k';
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    
    % Hardcode the axes position so normalized annotations (arrows) stay perfectly aligned
    ax.Units = 'normalized';
    ax.Position = [0.24, 0.22, 0.70, 0.72]; 
end

function [x_norm, y_norm] = data2norm(ax, x_data, y_data)
    % Converts exact data coordinates into MATLAB's normalized figure coordinates
    % so annotations lock perfectly onto the data curves.
    axPos = ax.Position; 
    xLim = ax.XLim;
    yLim = ax.YLim;
    
    x_norm = axPos(1) + axPos(3) * (x_data - xLim(1)) / diff(xLim);
    y_norm = axPos(2) + axPos(4) * (y_data - yLim(1)) / diff(yLim);
end

%% ================== FIGURE 3: 3D SPHERE PRESSURE EVOLUTION ==================
figC = figure('Name', 'Sphere Pressure Evolution', 'Color', 'w');

% Re-define blast parameters locally
Ps_local = 10000;      
c_local = 343;         
R_local = 0.15;        
d_local = 5;           
t0_local = 0.001;
tau_local = 0.001;

t_plot_ms = [0.000, 1.074, 1.194, 1.314, 1.794, 2.034, 2.154, 2.274, 5.994, 10.000];

% Generate a 3D sphere grid (35x35 matches the density of the original well)
[X, Y, Z] = sphere(35);
X_grid = (X .* R_local) + d_local; 
x0_local = d_local - R_local;

% --- Asymmetric Modified Turbo Colormap Construction ---
P_min = -Ps_local * exp(-2) / 1000; 
P_max = Ps_local / 1000;            

N = 256;
N_neg = max(1, round(N * abs(P_min) / (P_max - P_min)));
N_pos = N - N_neg;
t_map = jet(256);

neg_base = interp1(linspace(0, 1, 128), t_map(1:128, :), linspace(0, 1, N_neg));
blend_n = linspace(0, 1, N_neg)'.^1.5; 
neg_colors = neg_base .* (1 - blend_n) + [1 1 1] .* blend_n;

pos_base = interp1(linspace(0, 1, 128), t_map(129:256, :), linspace(0, 1, N_pos));
blend_p = linspace(1, 0, N_pos)'.^1.5;
pos_colors = pos_base .* (1 - blend_p) + [1 1 1] .* blend_p;

colormap(figC, [neg_colors; pos_colors]);

% --- TIGHT LAYOUT SETTINGS ---
t = tiledlayout(2, 5, 'TileSpacing', 'none', 'Padding', 'compact');

for i = 1:length(t_plot_ms)
    nexttile;
    
    t_curr = t_plot_ms(i) / 1000;
    
    val = t_curr - (X_grid - x0_local) / c_local;
    Dt = val - t0_local;
    expr = Dt ./ tau_local;
    hval = double(Dt >= 0); 
    
    P_grid_kPa = (Ps_local .* exp(-expr) .* (1 - expr) .* hval) / 1000;
    
    % Plot the sphere surface
    surf(X.*R_local, Y.*R_local, Z.*R_local, P_grid_kPa, ...
        'EdgeColor', 'k', 'EdgeAlpha', 0.8, 'FaceColor', 'interp', ...
        'LineWidth', 0.25);
    
    view(-45, 35); 
    axis equal off;
    
    % Crop the 3D bounding box
    xlim([-R_local, R_local]);
    ylim([-R_local, R_local]);
    zlim([-R_local, R_local]);
    
    clim([P_min, P_max]); 
    
    % CRITICAL FIX 1: Zoom the camera in to destroy the invisible 3D padding
    camzoom(1.5); 
    
    % CRITICAL FIX 2: Use 3D text placement instead of standard titles to avoid layout squishing
    % Places the text slightly above the north pole of the sphere (Z = R * 1.45)
    text(0, 0, R_local * 1.85, sprintf('%.2f ms', t_plot_ms(i)), ...
        'Interpreter', 'latex', 'FontSize', 7.5, 'HorizontalAlignment', 'center');
end

% --- CREATE COLORBAR ---
cb = colorbar;
cb.Label.String = 'Gauge Pressure (kPa)';
cb.Label.Interpreter = 'latex';
cb.TickLabelInterpreter = 'latex';
cb.Ticks = [0, 2, 4, 6, 8, 10]; 

% Format the figure first
formatMDPIFigure(figC, 'half');

% 1. Shorten the height of the figure itself
figC.Units = 'centimeters';
figC.Position(4) = figC.Position(4) * 0.85; % Shrink the figure height by 15%
drawnow; % Lock in the new figure size before moving the elements

% 2. Manually position the layout and colorbar 
% Constrain the layout to the left 80% of the figure (was 84%)
t.OuterPosition = [0, 0, 0.80, 1]; 

% cb.Position = [left, bottom, width, height]
% left 0.81: shifted left to give the label plenty of breathing room
% bottom 0.20: centers it vertically in the new shorter figure
% width 0.02: slightly thicker than 0.015, but skinnier than 0.04
% height 0.60: shortens the colorbar relative to the axes
cb.Position = [0.81, 0.20, 0.02, 0.60]; 

savePlot(figC, 'new_spheres', figDir);