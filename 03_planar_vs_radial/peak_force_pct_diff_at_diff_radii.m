% plotMultiRadius_ForceError.m
% Standalone script to calculate and plot the percent difference in peak force 
% (Planar vs Radial assumption) across multiple sphere radii.
clear; clc; close all;

%% 1. Setup Parameters
outDir = 'Blast_Sweep_Results';
addpath('../00_subroutines/');
if ~exist(outDir, 'dir'), mkdir(outDir); end
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultTextInterpreter', 'latex');

% Blast parameters (matching your dataGen scripts)
p.W = 10;               % Explosive mass (kg)
p.c = 343;              % Wave speed (m/s)
p.crW = p.W^(1/3);
p.tau = 0.006;          % Positive phase duration (s)

standoffs = linspace(0.5,30,500);       % Standoff distances (m)
num_points = 500;        % Higher resolution for precise analytical integration

% Define the array of radii to test (meters)
% R_vec = [0.05, 0.10, 0.143, 0.20, 0.30];
% R_vec = linspace(0.01, 0.25, 20);
R_vec = 0.25;

% Setup colors for the plot lines
colors = turbo(length(R_vec) + 1); 

%% 2. Setup Figure
fig2d = figure('Name', 'Multi-Radius Peak Force Error', 'Position', [150, 150, 800, 550], 'Color', 'w');
hold on; grid on;

fprintf('Calculating analytical forces for %d radii...\n', length(R_vec));

%% 3. Main Loop: Calculate and Plot for each Radius
for r_idx = 1:length(R_vec)
    R = R_vec(r_idx);
    fprintf('  -> Processing R = %.3f m...\n', R);
    
    peak_force_diff = zeros(1, length(standoffs));
    ratio_R_d0 = R ./ standoffs;
    
    % --- Integration Geometry for this specific R ---
    theta_pts = linspace(0, pi, num_points)';
    
    % Planar (Cartesian) Multiplier
    x_bar = R .* cos(theta_pts);
    x_bar_ascend = flip(x_bar); 
    cartesian_multiplier = -2 * pi .* x_bar_ascend;
    
    % Radial (Polar) Multiplier
    radial_multiplier = cos(theta_pts) .* (2 * pi * R^2 .* sin(theta_pts));
    
    for sd_idx = 1:length(standoffs)
        d0 = standoffs(sd_idx);
        
        % Define a tight time vector spanning the wave's passage over the sphere
        t_start = max(0, (d0 - R) / p.c - 0.002);
        t_end = t_start + (p.tau * 6);
        t = linspace(t_start, t_end, 200); 
        
        % Calculate actual 3D coordinates of the points on the sphere
        pts_x = d0 - R .* cos(theta_pts);
        pts_y = R .* sin(theta_pts);
        
        % Distances from blast origin (0,0,0)
        dist_plan = pts_x; 
        dist_rad  = sqrt(pts_x.^2 + pts_y.^2);
        
        % Preallocate pressure arrays
        P_plan = zeros(num_points, length(t));
        P_rad  = zeros(num_points, length(t));
        
        % Calculate pressure over time for each point
        for pt = 1:num_points
            P_plan(pt, :) = calcFriedlander(dist_plan(pt), t, p);
            P_rad(pt, :)  = calcFriedlander(dist_rad(pt), t, p);
        end
        
        % --- Force Integration ---
        % Planar integration (Flip to match ascending x_bar)
        P_plan_flip = flip(P_plan, 1);
        integrand_plan = P_plan_flip .* cartesian_multiplier;
        F_plan = trapz(x_bar_ascend, integrand_plan, 1);
        
        % Radial integration
        integrand_rad = P_rad .* radial_multiplier;
        F_rad = trapz(theta_pts, integrand_rad, 1) * -1;
        
        % --- Peak Difference Calculation ---
        peak_F_plan = max(F_plan);
        peak_F_rad  = max(F_rad);
        
        if peak_F_rad > 0
            peak_force_diff(sd_idx) = (abs(peak_F_plan - peak_F_rad) / peak_F_rad) * 100;
        else
            peak_force_diff(sd_idx) = 0;
        end
    end
    
    % Add line to plot
    plot(ratio_R_d0, peak_force_diff, '-o', 'LineWidth', 2, 'MarkerSize', 1, ...
         'Color', colors(r_idx, :), 'MarkerFaceColor', colors(r_idx, :), ...
         'DisplayName', sprintf('$R = %.3f$ m', R));
end

%% 4. Finalize and Save Plot
% title('\textbf{Peak Force Percent Error for Varying Radii}');
xlabel('$R/d_0$');
xscale('log')
xticks(logspace(-2, 0, 3))
ylabel('Max Percent Difference (\%)');

% legend('Location', 'best', 'Box', 'off');

% Apply MDPI half-figure formatting
formatMDPIFigure(fig2d, 'third');

% Ensure the directory exists and save using savePlot (auto-selects .pdf since it's a line plot)
savePlot(fig2d, 'MultiRadius_Force_PercentError_2D', outDir);

fprintf('\nPlot generation complete. Saved MDPI formatted figure to %s\n', outDir);


%% HELPER FUNCTION: Friedlander Pressure Calculation
function P = calcFriedlander(d, t, p)
    % Calculates the Friedlander overpressure for an array of distances or times
    Ps = (0.95 * p.crW ./ d + 3.9 * (p.crW^2) ./ (d.^2) + 13 * p.W ./ (d.^3)) * 1000;
    Dt = t - (d ./ p.c);
    eps_val = Dt ./ p.tau;
    
    P = Ps .* exp(-eps_val) .* (1 - eps_val);
    P(Dt < 0) = 0; % Zero out pressure before wave arrives
end