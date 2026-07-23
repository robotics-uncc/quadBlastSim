% figGen_grid.m
% Generates highly formatted MDPI-compliant grids mapping C_D vs Rho
clear; clc; close all;

addpath('../');
addpath('../00_subroutines/');
figDir = 'figs';

% Force MATLAB to use LaTeX globally
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultTextInterpreter', 'latex');

% Load the contour grid data
if ~isfile('grid_aero_data.mat')
    error('grid_aero_data.mat not found. Run aero_grid_data_gen.m first.');
end
load('grid_aero_data.mat');

% Plot labels (with units) for the mesh titles
plotLabs = ["$\Delta X$ (m)", "$\dot{X}$ (m/s)", "$\theta$ (deg)", "$\dot{\theta}$ (deg/s)", ...
            "$\Delta Y$ (m)", "$\dot{Y}$ (m/s)", "$\phi$ (deg)", "$\dot{\phi}$ (deg/s)", ...
            "$\Delta Z$ (m)", "$\dot{Z}$ (m/s)", "$\psi$ (deg)", "$\dot{\psi}$ (deg/s)"];

%% ================== FIGURE 1: TERMINAL STATES GRID (C_D vs Rho) ==================
figName = sprintf('Terminal States Contour (d_0 = %gm, alpha = %d)', d0_val, alpha_case);
fig1 = figure('Name', figName);

% Switch to a 2x3 tiled layout (matching the 'compact' spacing style of Fig 1 in figGen.m)
t1 = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
colormap(fig1, 'turbo');

% Map the specific states for the new 2x3 layout (ignoring near-zero X states):
% Row 1: dY (5), dY_dt (6), phi (7)
% Row 2: dZ (9), dZ_dt (10), phi_dt (8)
statesToPlot = [5, 6, 7, 9, 10, 8];

for i = 1:length(statesToPlot)
    stateIdx = statesToPlot(i);
    ax = nexttile;
    
    % Extract the 2D grid for this specific state
    Z_data = terminal_states(:, :, stateIdx);
    
    % Plot the grid. X-axis is CD_vec (columns), Y-axis is rho_vec (rows)
    imagesc(CD_vec, rho_vec, Z_data);
    set(ax, 'YDir', 'normal'); 
    
    % 1) FORCE SQUARE PLOT
    axis(ax, 'square');
    
    % Title above the plot 
    title(plotLabs(stateIdx), 'Interpreter', 'latex');
    
    % 2) COLORBAR FORMATTING
    clim_vals = [min(Z_data(:)), max(Z_data(:))];
    
    % Handle edge case where state is completely zero
    if diff(clim_vals) == 0
        clim_vals = clim_vals(1) + [-0.001, 0.001];
    end
    
    c_ticks = getNiceTicks(clim_vals(1), clim_vals(2));
    clim(ax, [c_ticks(1), c_ticks(end)]);
    
    % Add individual colorbars
    cb = colorbar(ax);
    cb.Ticks = c_ticks;
    if i == 1 || i == 4
        cb.TickLabels = arrayfun(@(x) sprintf('%.2f', x), c_ticks, 'UniformOutput', false);
    elseif i == 2 || i == 5
        cb.TickLabels = arrayfun(@(x) sprintf('%.1f', x), c_ticks, 'UniformOutput', false);
    else
        cb.TickLabels = arrayfun(@(x) sprintf('%.0f', x), c_ticks, 'UniformOutput', false);
    end
    cb.TickLabelInterpreter = 'latex';
    
    % Define 4 evenly spaced ticks for the axes to avoid crowding
    x_tick_vals = linspace(CD_vec(1), CD_vec(end), 4);
    y_tick_vals = linspace(rho_vec(1), rho_vec(end), 4);
    xticks(x_tick_vals);
    yticks(y_tick_vals);
    
    % Only show X-labels on the bottom row (tiles 4, 5, 6)
    if i > 3
        xlabel('$C_D$', 'Interpreter', 'latex');
        % Force X-axis labels to 2 decimal places
        xticklabels(arrayfun(@(x) sprintf('%.2f', x), x_tick_vals, 'UniformOutput', false));
    else
        xticklabels({});
    end
    
    % Only show Y-labels on the left column (tiles 1 and 4)
    if ismember(i, [1, 4])
        ylabel('$\rho$ (kg/m$^3$)', 'Interpreter', 'latex');
        % Force Y-axis labels to 2 decimal places
        yticklabels(arrayfun(@(x) sprintf('%.2f', x), y_tick_vals, 'UniformOutput', false));
    else
        yticklabels({});
    end
end

% Use the 'full' formatting preset to exactly match Figure 1 in figGen.m
formatMDPIFigure(fig1, 'twothirds');
savePlot(fig1, 'TerminalStates_CD_Rho_Grid', figDir);
disp('Parameter sweep contour figure successfully generated and exported!');
