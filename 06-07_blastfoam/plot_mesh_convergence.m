% =========================================================================
% Script: plot_mesh_convergence.m
% Description: Reads CFD mesh convergence data from CSV and outputs 
%              figures formatted and saved via external subroutines.
% =========================================================================

clear; clc; close all;

% 1. Add Subroutine Path
addpath('../00_subroutines/');

%% 2. Load Data
filename = 'mesh_convergence_data.csv';
if ~isfile(filename)
    error('CSV file not found. Please run the Python extraction script first.');
end

% Read CSV and handle the string columns
opts = detectImportOptions(filename);
opts = setvartype(opts, 'Level', 'string');
simData = readtable(filename, opts);

% REMOVE MISSING DATA: Prevents MATLAB from breaking the line
simData = rmmissing(simData, 'DataVariables', 'PeakPressure');

% Sort the data descending by cell size so the plot line connects cleanly
simData = sortrows(simData, 'h_actual', 'descend');

%% 3. Generate Plot
fig2 = figure('Name', 'Asymptotic Mesh Convergence');
hold on;

% Plot the connecting line FIRST (in background, hidden from legend)
plot(simData.h_actual, simData.PeakPressure, '-', ...
    'Color', '#999999', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Padding definitions for text offsets
x_pad = 0.02; % Offset in meters for the text

% Loop through each data point to plot its specific color and text alignment
for i = 1:height(simData)
    lvl = simData.Level(i);
    
    % Determine color and visual placement based on the level name
    switch lvl
        case 'Original'
            c = '#d62728'; % Red
            alignH = 'right'; % Visually to the left
            x_pos = simData.h_actual(i) + x_pad; % Math +X is Visual Left
        case 'Lvl 3'
            c = '#9467bd'; % Purple
            alignH = 'right'; % Visually to the left
            x_pos = simData.h_actual(i) + x_pad;
        case 'Lvl 2'
            c = '#2ca02c'; % Green
            alignH = 'right'; % Visually to the left
            x_pos = simData.h_actual(i) + x_pad;
        case 'Lvl 1'
            c = '#ff7f0e'; % Orange
            alignH = 'left';  % Visually to the right
            x_pos = simData.h_actual(i) - x_pad; % Math -X is Visual Right
        case 'Lvl 0'
            c = '#1f77b4'; % Blue
            alignH = 'left';  % Visually to the right
            x_pos = simData.h_actual(i) - x_pad;
        otherwise
            c = '#333333'; % Fallback color
            alignH = 'center';
            x_pos = simData.h_actual(i);
    end
    
    % Plot individual marker (half size: 4)
    plot(simData.h_actual(i), simData.PeakPressure(i), 'o', ...
        'MarkerFaceColor', c, 'Color', c, 'LineWidth', 1.2, ...
        'MarkerSize', 4, 'DisplayName', lvl);
        
    % Add text annotation next to the marker
    % text(x_pos, simData.PeakPressure(i), lvl, ...
    %     'VerticalAlignment', 'middle', 'HorizontalAlignment', alignH, ...
    %     'FontSize', 9);
end

ylabel('Peak Overpressure (Pa)');
xlabel('Minimum Cell Size (m)');
grid on;

% Add the legend for the markers
legend('Location', 'northwest', 'FontSize', 9);

% Set X-axis limits tightly around the data, flipped so coarsest is on left
xlim([-0.05, 0.60]);
set(gca, 'XDir', 'reverse'); 

% Calculate an offset and apply limits to prevent text/line clipping
y_min = min(simData.PeakPressure);
y_max = max(simData.PeakPressure);
y_pad = (y_max - y_min) * 0.15; 
ylim([y_min - y_pad, y_max + y_pad]);

% Apply external MDPI Formatting & Export via savePlot
formatMDPIFigure(fig2, 'half');
savePlot(fig2, 'mesh_convergence_asymptotic_MDPI', '.', false);
fprintf('Saved asymptotic mesh convergence plot.\n');