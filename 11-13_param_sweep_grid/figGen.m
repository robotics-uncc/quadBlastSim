% Generates highly formatted MDPI-compliant grids matching the reference images
clear; clc; close all;
addpath('../');
addpath('../00_subroutines/');
figDir = 'figs';

% Force MATLAB to use LaTeX globally
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultTextInterpreter', 'latex');

% Load the data directly from the current folder
% if ~isfile('sweepDataWorkspace.mat')
%     error('sweepDataWorkspace.mat not found. Run mainSweep.m first.');
% end
load('sweepResults/sweepDataWorkspace.mat');

% --- LABELS ---
% Plot labels (with units) for the mesh titles and time-series Y-axes
plotLabs = ["$\Delta X$ (m)", "$\dot{X}$ (m/s)", "$\theta$ (deg)", "$\dot{\theta}$ (deg/s)", ...
            "$\Delta Y$ (m)", "$\dot{Y}$ (m/s)", "$\phi$ (deg)", "$\dot{\phi}$ (deg/s)", ...
            "$\Delta Z$ (m)", "$\dot{Z}$ (m/s)", "$\psi$ (deg)", "$\dot{\psi}$ (deg/s)"];

% Title labels (without units) for the time-series titles
titleLabs = ["$\Delta X$", "$\dot{X}$", "$\theta$", "$\dot{\theta}$", ...
             "$\Delta Y$", "$\dot{Y}$", "$\phi$", "$\dot{\phi}$", ...
             "$\Delta Z$", "$\dot{Z}$", "$\psi$", "$\dot{\psi}$"];

% --- CROP DATA (d0 <= 15m, alpha <= 6) ---
d0_max_idx = find(d0_vec == 15);
alpha_max_idx = find(alpha_i_vec == 6);

d0_sub = d0_vec(1:d0_max_idx);
alpha_sub = alpha_i_vec(1:alpha_max_idx);

alphaLabels = arrayfun(@(x) sprintf('$\\alpha_%d$', x), alpha_sub, 'UniformOutput', false);

%% ================== FIGURE 1: TERMINAL STATES GRID ==================
fig1 = figure('Name', 'Terminal States Contour');
t1 = tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
colormap(fig1, 'turbo');

max_time_ms = 90;

for stateIdx = 1:12
    ax = nexttile;
    
    % Extract terminal states at max_time_ms
    Z_data = zeros(length(d0_sub), length(alpha_sub));
    for r = 1:length(d0_sub)
        for c = 1:length(alpha_sub)
            % Convert time array to ms
            t_ms = timeSeriesData{r,c}.t * 1000; 
            
            % Find the index where time is closest to (but not exceeding) max_time_ms
            target_idx = find(t_ms <= max_time_ms, 1, 'last');
            
            % Use that index instead of 'end'
            Z_data(r, c) = timeSeriesData{r,c}.vars(target_idx, stateIdx);
        end
    end
    
    % Plot the grid
    imagesc(alpha_sub, d0_sub, Z_data);
    set(ax, 'YDir', 'normal'); 
    
    % 1) FORCE SQUARE PLOT
    axis(ax, 'square');
    
    % Title above the plot 
    title(plotLabs(stateIdx), 'Interpreter', 'latex');
    
    % 2) 4 EVENLY SPACED COLORBAR TICKS
    clim_vals = [min(Z_data(:)), max(Z_data(:))];
    c_ticks = getNiceTicks(clim_vals(1), clim_vals(2));
    
    % Snap the color limit strictly to the calculated nice boundaries
    clim(ax, [c_ticks(1), c_ticks(end)]);
    
    % Add individual colorbars to every plot
    cb = colorbar(ax);
    cb.Ticks = c_ticks;
    cb.TickLabels = arrayfun(@(x) sprintf('%5.1f', x), c_ticks, 'UniformOutput', false);
    cb.TickLabelInterpreter = 'latex';
    
    % Axis limits and ticks
    xticks(alpha_sub);
    yticks(d0_sub);
    
    % Only show X-labels on the bottom row
    if stateIdx > 8
        xticklabels(alphaLabels);
        xlabel('Blast Angles');
    else
        xticklabels({});
    end
    
    % Only show Y-labels on the left column
    if ismember(stateIdx, [1, 5, 9])
        ylabel('Distances (m)');
    else
        yticklabels({});
    end
end

formatMDPIFigure(fig1, 'full');
savePlot(fig1, 'TerminalStates', figDir);

%% ================== FIGURE 2: TIME SERIES GRID ==================
% Setup configuration for the time series
target_alpha = 1; % Plotted for single angle across all distances
alpha_idx = find(alpha_i_vec == target_alpha);
% max_time_ms = timeSeriesData{1,1}.t(end)*1000;
% max_time_ms = 500;
max_time_ms = 90;

fig2 = figure('Name', 'Time Series for Single Angle');
% Switch to a 2x3 layout
t2 = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% Use a colormap to distinguish the distances
lineColors = turbo(length(d0_sub));

% Map the specific states for the new 2x3 layout:
% Row 1: dY (5), dY_dt (6), phi (7)
% Row 2: dZ (9), dZ_dt (10), phi_dt (8)
statesToPlot = [5, 6, 7, 9, 10, 8];

for i = 1:length(statesToPlot)
    stateIdx = statesToPlot(i); 

    ax = nexttile;
    hold on; grid on;

    % 1) CALCULATE X-AXIS TICKS FIRST
    x_ticks = getNiceTicks(0, max_time_ms);
    visible_time_max = x_ticks(end);

    y_min = inf;
    y_max = -inf;

    for r = 1:length(d0_sub)
        t_ms = timeSeriesData{r, alpha_idx}.t * 1000; % Convert to ms
        y_data = timeSeriesData{r, alpha_idx}.vars(:, stateIdx);

        % Track min/max ONLY within the visible X window 
        valid_idx = t_ms <= visible_time_max;
        if any(valid_idx)
            y_min = min(y_min, min(y_data(valid_idx)));
            y_max = max(y_max, max(y_data(valid_idx)));
        end

        plotName = sprintf('$d_0 = %g$ m', d0_sub(r));
        plot(t_ms, y_data, 'LineWidth', 1.2, 'Color', lineColors(r,:), 'DisplayName', plotName);
    end

    % FORCE SQUARE PLOT
    axis(ax, 'square');

    % Titles and Labels
    title(titleLabs(stateIdx), 'Interpreter', 'latex');
    ylabel(plotLabs(stateIdx), 'Interpreter', 'latex');

    % 2) APPLY X-AXIS TICKS AND LIMITS
    ax.XLim = [x_ticks(1), x_ticks(end)];
    ax.XTick = x_ticks;
    ax.XTickLabel = arrayfun(@(x) sprintf('%g', x), x_ticks, 'UniformOutput', false);

    % 3) ENFORCE MINIMUM Y-RANGE & CALCULATE Y-TICKS
    if max(abs([y_min, y_max])) < 0.001
        y_min = -0.001;
        y_max = 0.001;
    end

    y_ticks = getNiceTicks(y_min, y_max);
    ax.YLim = [y_ticks(1), y_ticks(end)];
    ax.YTick = y_ticks;
    ax.YTickLabel = arrayfun(@(x) sprintf('%g', x), y_ticks, 'UniformOutput', false);

    % Only show X-labels on the bottom row (tiles 4, 5, 6)
    if i > 3
        xlabel('Time (ms)');
    else
        xticklabels({});
    end

    % Add Legend to the final plot (tile 6)
    if i == 6
        lgd = legend('Location', 'eastoutside', 'Box', 'off');
        lgd.Layout.Tile = 'east';
        lgd.ItemTokenSize = [15, 18]; 
    end
end

formatMDPIFigure(fig2, 'shorter');
savePlot(fig2, sprintf('TimeSeries_alpha_%d', target_alpha), figDir);

disp('All sweep figures successfully generated and exported!');

function savePlot(hdl, plotName, dirName)
    if ~exist(dirName, 'dir')
        mkdir(dirName);
    end
    hasSurface = ~isempty(findall(hdl, 'Type', 'surface')) || ~isempty(findall(hdl, 'Type', 'image'));
    if hasSurface 
        savePath = fullfile(dirName, [plotName, '.png']);
        exportgraphics(hdl, savePath, 'Resolution', 300);
    else
        savePath = fullfile(dirName, [plotName, '.pdf']);
        exportgraphics(hdl, savePath, 'ContentType', 'vector');
    end
end

% %% ================== FIGURE 3: ALL STATES TIME SERIES GRID ==================
% fig3 = figure('Name', 'All States Time Series');
% t3 = tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
% max_time_ms = timeSeriesData{1,1}.t(end)*1000;
% 
% for stateIdx = 1:12
%     ax = nexttile;
%     hold on; grid on;
% 
%     % 1) CALCULATE X-AXIS TICKS FIRST
%     x_ticks = getNiceTicks(0, max_time_ms);
%     visible_time_max = x_ticks(end);
% 
%     y_min = inf;
%     y_max = -inf;
% 
%     for r = 1:length(d0_sub)
%         t_ms = timeSeriesData{r, alpha_idx}.t * 1000; % Convert to ms
%         y_data = timeSeriesData{r, alpha_idx}.vars(:, stateIdx);
% 
%         % Track min/max ONLY within the visible X window 
%         valid_idx = t_ms <= visible_time_max;
%         if any(valid_idx)
%             y_min = min(y_min, min(y_data(valid_idx)));
%             y_max = max(y_max, max(y_data(valid_idx)));
%         end
% 
%         plotName = sprintf('$d_0 = %g$ m', d0_sub(r));
%         plot(t_ms, y_data, 'LineWidth', 1.2, 'Color', lineColors(r,:), 'DisplayName', plotName);
%     end
% 
%     % FORCE SQUARE PLOT
%     axis(ax, 'square');
% 
%     % Titles and Labels
%     title(titleLabs(stateIdx), 'Interpreter', 'latex');
%     ylabel(plotLabs(stateIdx), 'Interpreter', 'latex');
% 
%     % 2) APPLY X-AXIS TICKS AND LIMITS
%     ax.XLim = [x_ticks(1), x_ticks(end)];
%     ax.XTick = x_ticks;
%     ax.XTickLabel = arrayfun(@(x) sprintf('%g', x), x_ticks, 'UniformOutput', false);
% 
%     % 3) ENFORCE MINIMUM Y-RANGE & CALCULATE Y-TICKS
%     if max(abs([y_min, y_max])) < 0.001
%         y_min = -0.001;
%         y_max = 0.001;
%     end
% 
%     y_ticks = getNiceTicks(y_min, y_max);
%     ax.YLim = [y_ticks(1), y_ticks(end)];
%     ax.YTick = y_ticks;
%     ax.YTickLabel = arrayfun(@(x) sprintf('%g', x), y_ticks, 'UniformOutput', false);
% 
%     % Only show X-labels on the bottom row (tiles 9 through 12)
%     if stateIdx > 8
%         xlabel('Time (ms)');
%     else
%         xticklabels({});
%     end
% 
%     % Add Legend to the layout
%     if stateIdx == 12
%         lgd = legend('Location', 'eastoutside', 'Box', 'off');
%         lgd.Layout.Tile = 'east';
%         lgd.ItemTokenSize = [15, 18]; 
%     end
% end
% 
% formatMDPIFigure(fig3, 'full');
% savePlot(fig3, sprintf('AllStates_TimeSeries_alpha_%d', target_alpha), figDir);

%% ================== FIGURE 4: PEAK METRICS ==================
fig4 = figure('Name', 'Peak Metrics');
% Configured for a 2x2 tiled layout
t4 = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
colormap(fig4, 'turbo');

% Sub-select the data to match your cropped axes (d0 <= 15m, alpha <= 6)
% Divide Force and Moment by 1000 to convert to kN and kN*m
peakDataSub.force      = peakMetrics.force(1:d0_max_idx, 1:alpha_max_idx) / 1000;
peakDataSub.moment     = peakMetrics.moment(1:d0_max_idx, 1:alpha_max_idx) / 1000;
peakDataSub.impulse    = peakMetrics.impulse(1:d0_max_idx, 1:alpha_max_idx);
peakDataSub.angImpulse = peakMetrics.angImpulse(1:d0_max_idx, 1:alpha_max_idx);

% Updated Fields and Visual Labels (Units moved to colorbar and updated to kN)
metricFields = {'force', 'moment', 'impulse', 'angImpulse'};
metricTitles = ["Peak Blast Force", "Peak Blast Moment", "Peak Blast Impulse", "Peak Angular Impulse"];
metricUnits  = ["(kN)", "(kN$\cdot$m)", "(N$\cdot$s)", "(N$\cdot$m$\cdot$s)"];

for mIdx = 1:4
    ax = nexttile;
    
    % Extract the specific grid
    currentField = metricFields{mIdx};
    Z_data = peakDataSub.(currentField);
    
    imagesc(alpha_sub, d0_sub, Z_data);
    set(ax, 'YDir', 'normal'); 
    axis(ax, 'square');
    
    % Title (without units, since they are moving to the colorbar)
    title(metricTitles(mIdx), 'Interpreter', 'latex');
    
    clim_vals = [min(Z_data(:)), max(Z_data(:))];
    % Fallback guard if max == min
    if clim_vals(1) == clim_vals(2)
       clim_vals(2) = clim_vals(1) + 1; 
    end
    c_ticks = getNiceTicks(clim_vals(1), clim_vals(2));
    clim(ax, [c_ticks(1), c_ticks(end)]);
    
    cb = colorbar(ax);
    cb.Ticks = c_ticks;
    cb.TickLabels = arrayfun(@(x) sprintf('%5.1f', x), c_ticks, 'UniformOutput', false);
    cb.TickLabelInterpreter = 'latex';
    
    % Add the unit label to the colorbar
    cb.Label.String = metricUnits(mIdx);
    cb.Label.Interpreter = 'latex';
    
    xticks(alpha_sub);
    yticks(d0_sub);
    
    % 2x2 Layout axis formatting
    % Bottom row (mIdx 3 and 4) gets X-labels
    if mIdx == 3 || mIdx == 4
        xticklabels(alphaLabels);
        xlabel('Blast Angles');
    else
        xticklabels({});
    end
    
    % Left column (mIdx 1 and 3) gets Y-labels
    if mIdx == 1 || mIdx == 3
        ylabel('Distances (m)');
    else
        yticklabels({});
    end
end
formatMDPIFigure(fig4, 'twothirds');
savePlot(fig4, 'peak_blast_params', figDir);

%% ================== FIGURE 5: BLAST PARAMETERS TIME SERIES ==================
% Isolate a representative run (e.g., shortest distance d0 = 2.5m at target_alpha)
rep_r = 1; 
rep_c = alpha_idx; 

% Verify that the updated dataGen.m data exists before plotting
if isfield(timeSeriesData{rep_r, rep_c}, 'blastForces')
    fig5 = figure('Name', 'Blast Parameters Over Time');
    t5 = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Use same time bounds as Figure 2
    t_ms = timeSeriesData{rep_r, rep_c}.t * 1000;
    valid_idx = t_ms <= max_time_ms;
    t_plot = t_ms(valid_idx);
    
    % --- 1. Blast Forces ---
    ax1 = nexttile; hold on; grid on;
    forces = timeSeriesData{rep_r, rep_c}.blastForces(valid_idx, :);
    plot(t_plot, forces(:,1), 'Color', [0 0.4470 0.7410], 'LineWidth', 2, 'DisplayName', '$F_{(blast,x)}$');
    plot(t_plot, forces(:,2), 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 2, 'DisplayName', '$F_{(blast,y)}$');
    plot(t_plot, forces(:,3), 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2, 'DisplayName', '$F_{(blast,z)}$');
    title('Blast Forces', 'Interpreter', 'latex');
    ylabel('Force (N)', 'Interpreter', 'latex');
    axis(ax1, 'normal');
    
    % --- 2. Wind Velocity ---
    ax2 = nexttile; hold on; grid on;
    winds = timeSeriesData{rep_r, rep_c}.blastWind(valid_idx, :);
    plot(t_plot, winds(:,1), 'Color', [0 0.4470 0.7410], 'LineWidth', 2, 'DisplayName', '$w_x$');
    plot(t_plot, winds(:,2), 'Color', [0.9290 0.6940 0.1250], 'LineWidth', 2, 'DisplayName', '$w_y$');
    plot(t_plot, winds(:,3), 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 2, 'DisplayName', '$w_z$');
    title('Blast Wind Velocity', 'Interpreter', 'latex');
    ylabel('Velocity (m/s)', 'Interpreter', 'latex');
    axis(ax2, 'normal');
    
    % --- 3. Blast Pressure ---
    ax3 = nexttile; hold on; grid on;
    press = timeSeriesData{rep_r, rep_c}.pressures(valid_idx, :);
    plot(t_plot, press(:,1), 'LineWidth', 1.5, 'DisplayName', 'Body');
    plot(t_plot, press(:,2), 'LineWidth', 1.5, 'DisplayName', 'Motor 1');
    plot(t_plot, press(:,3), 'LineWidth', 1.5, 'DisplayName', 'Motor 2');
    plot(t_plot, press(:,4), 'LineWidth', 1.5, 'DisplayName', 'Motor 3');
    plot(t_plot, press(:,5), 'Color', [0.4940 0.1840 0.5560], 'LineWidth', 1.5, 'DisplayName', 'Motor 4');
    title('Blast Overpressure', 'Interpreter', 'latex');
    ylabel('Pressure (kPa)', 'Interpreter', 'latex');
    xlabel('Time (ms)', 'Interpreter', 'latex');
    axis(ax3, 'normal');
    
    % --- Formatting & Legends ---
    legend(ax1, 'Location', 'eastoutside', 'Box', 'off', 'Interpreter', 'latex');
    legend(ax2, 'Location', 'eastoutside', 'Box', 'off', 'Interpreter', 'latex');
    legend(ax3, 'Location', 'eastoutside', 'Box', 'off', 'Interpreter', 'latex');
    
    linkaxes([ax1, ax2, ax3], 'x');
    x_ticks = getNiceTicks(0, max_time_ms);
    for ax = [ax1, ax2, ax3]
        ax.XLim = [x_ticks(1), x_ticks(end)];
        ax.XTick = x_ticks;
        ax.XTickLabel = arrayfun(@(x) sprintf('%g', x), x_ticks, 'UniformOutput', false);
    end
    
    formatMDPIFigure(fig5, 'full');
    saveName = sprintf('Blast_Parameters_d0_%g_alpha_%d', d0_sub(rep_r), target_alpha);
    saveName = strrep(saveName, '.', 'p'); % Safe filename
    savePlot(fig5, saveName, figDir);
else
    disp('Skipped Figure 5: Please update dataGen.m and re-run to extract blast parameters.');
end

%% ================== FIGURE 6: INERTIAL FORCES GRID ==================
% Use the same representative run isolated in Figure 5
if isfield(timeSeriesData{rep_r, rep_c}, 'thrust')
    fig6 = figure('Name', 'Inertial Forces', 'Units', 'inches', 'Position', [0 0 16 9.5]);
    t6 = tiledlayout(3, 7, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Extract data for this run
    data = timeSeriesData{rep_r, rep_c};
    t_ms = data.t * 1000;
    valid_idx = t_ms <= max_time_ms;
    t_plot = t_ms(valid_idx);
    
    % Crop all forces to the valid time window
    w  = data.weight(valid_idx, :);
    t  = data.thrust(valid_idx, :);
    bd = data.bodyDrag(valid_idx, :);
    m1 = data.motor1Drag(valid_idx, :);
    m2 = data.motor2Drag(valid_idx, :);
    m3 = data.motor3Drag(valid_idx, :);
    m4 = data.motor4Drag(valid_idx, :);
    
    % Make a matrix of all plotted variables (Loop logic exactly from your script)
    plotVars = [];
    for i = 1:3
        plotVars = [plotVars, w(:,i), t(:,i), bd(:,i), m1(:,i), m2(:,i), m3(:,i), m4(:,i)];
    end
    
    titleLabs = ["Weight", "Thrust", "Body Drag", "Motor 1 Drag", "Motor 2 Drag", "Motor 3 Drag", "Motor 4 Drag"];
    lw = 1.2;
    
    for i = 1:width(plotVars)
        ax = nexttile;
        plot(t_plot, plotVars(:,i), 'LineWidth', lw, 'Color', [0 0.4470 0.7410]);
        grid on;
        
        if i > 14
            xlabel("Time (ms)", 'Interpreter', 'latex');
        else
            xticklabels({});
        end
        
        if i <= 7
            title(titleLabs(i), 'Interpreter', 'latex');
        end
        
        % Y-axis labels for the first column of each row
        if i == 1
            ylabel("$F_{i_{1}}$", 'Interpreter', 'latex');
        elseif i == 8
            ylabel("$F_{i_{2}}$", 'Interpreter', 'latex');
        elseif i == 15
            ylabel("$F_{i_{3}}$", 'Interpreter', 'latex');
        else
            yticklabels({});
        end
    end
    
    formatMDPIFigure(fig6, 'full');
    saveName = sprintf('Inertial_Forces_d0_%g_alpha_%d', d0_sub(rep_r), target_alpha);
    saveName = strrep(saveName, '.', 'p');
    savePlot(fig6, saveName, figDir);
else
    disp('Skipped Figure 6: Please update dataGen.m to include the inertial forces.');
end