% Clear the workspace
clear; clc; close all;
addpath('../')
addpath('../00_subroutines/')
figDir = 'figs';

% Load the generated data
if ~isfile('velocity_model_fig_data.mat')
    error('Run dataGen.m first to create the data file.');
end
load('velocity_model_fig_data.mat');

% Define MDPI Colors (Matches default MATLAB but explicitly defined for safety)
colors = ["#0072BD", "#A2142F", "#EDB120", "#77AC30"];

%% ================= Figure A: Parameter Plot ================= %%
figA = figure('Name', 'Parameters');
hold on; grid on;

% Plot curves
plot(S_vals, v_s, '-', 'Color', colors(1), 'DisplayName', '$V_s$ (Ma)');
plot(S_vals, alpha, '-', 'Color', colors(2), 'DisplayName', '$\alpha$');
plot(S_vals, beta, '-', 'Color', colors(3), 'DisplayName', '$\beta$');
plot(S_vals, a, '-', 'Color', colors(4), 'DisplayName', '$a$ (Ma)');

% Attempt to load and plot CSV scatter data if it exists
if isfile('deweyParams.csv')
    csvData = readmatrix('deweyParams.csv');
    % Columns based on your paramPlot.m indices
    scatter(csvData(:,2), csvData(:,3), 20, 'MarkerFaceColor', colors(1), 'MarkerEdgeColor', colors(1), 'HandleVisibility', 'off');
    scatter(csvData(:,2), csvData(:,4), 20, 'MarkerFaceColor', colors(2), 'MarkerEdgeColor', colors(2), 'HandleVisibility', 'off');
    scatter(csvData(:,2), csvData(:,5), 20, 'MarkerFaceColor', colors(3), 'MarkerEdgeColor', colors(3), 'HandleVisibility', 'off');
    scatter(csvData(:,2), csvData(:,6), 20, 'MarkerFaceColor', colors(4), 'MarkerEdgeColor', colors(4), 'HandleVisibility', 'off');
end

% Formatting
xlim([0 10]);
xticks(linspace(0,10,5))
ylim([0 2.5]);
xlabel('$S$ (m/kg$^{1/3}$)', 'Interpreter', 'latex');
ylabel('Parameter Values', 'Interpreter', 'latex');

% Shrink the legend line length so it doesn't overlap the data
lgd = legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');
lgd.ItemTokenSize = [12, 18]; % Default is [30, 18]. This cuts the line width by more than half.

% Apply MDPI Styles & Export
formatMDPIFigure(figA, 'half');
savePlot(figA, 'Params', figDir)

%% ================= Figure B: Velocity Plot ================= %%
figB = figure('Name', 'Velocity');
hold on; grid on;

% Plot data (Original Dewey as dashed, Modified as solid)
plot(t_ms, V_t_orig, 'k--', 'DisplayName', 'Original (Eq. 4)');
plot(t_ms, V_t, 'k-', 'DisplayName', 'Modified (Eq. 7)');

% Find peak for the arrow (using the modified model)
[peakV, peakIdx] = max(V_t);
peakT = t_ms(peakIdx);

% Formatting
xlim([0 30]);
xticks(0:5:30);
% ylim([0 2.5]);    
yMax = max(max(V_t_orig), max(V_t)) * 1.1;
ylim([0 yMax]);
xlabel('Time (ms)', 'Interpreter', 'latex');
ylabel('Wind Velocity (Mach)', 'Interpreter', 'latex');

% Add a legend to distinguish the two curves
legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');

% Apply MDPI Styles (MUST do this before the arrow so dimensions are locked)
formatMDPIFigure(figB, 'half');
drawnow;

% --- ADDING THE TEXT ARROW ---
% Define where the text should start (in Data coordinates)
textX_data = peakT + 5;  
textY_data = peakV - 0.2; 

% Convert Data coordinates to Normalized Figure coordinates
ax = gca;
axPos = ax.Position; 

xNorm = [axPos(1) + ((textX_data - ax.XLim(1)) / diff(ax.XLim)) * axPos(3), ...
         axPos(1) + ((peakT - ax.XLim(1)) / diff(ax.XLim)) * axPos(3)];
yNorm = [axPos(2) + ((textY_data - ax.YLim(1)) / diff(ax.YLim)) * axPos(4), ...
         axPos(2) + ((peakV - ax.YLim(1)) / diff(ax.YLim)) * axPos(4)];

% 3. Draw the arrow
ta = annotation('textarrow', xNorm, yNorm, 'String', ' Peak Induced Wind Velocity');
ta.FontName = 'Times New Roman';
ta.FontSize = 9;
ta.TextColor = 'k';
ta.Color = 'k';
ta.HeadStyle = 'vback2';
ta.HeadLength = 7;
ta.HeadWidth = 6;
ta.LineWidth = 1.2;

% Export
savePlot(figB, 'Velocity', figDir)