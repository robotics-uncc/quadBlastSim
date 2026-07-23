% Clear stuff
clear; clc; close all;
addpath('../00_subroutines/')

%% 1. Load and Process Experimental Data
csvFile = '../ritzel_fig5.csv';
if ~isfile(csvFile)
    error('Could not find ritzel_fig5.csv. Check the file path.');
end

% Read the CSV, skipping the two header rows
rawData = readmatrix(csvFile, 'NumHeaderLines', 2);

% Define the masses of the 4 spheres (in kg) based on the CSV headers
masses = [0.192, 0.557, 1.138, 2.269];
sphereData = struct();

% Extract valid data for each sphere
for i = 1:length(masses)
    % Columns are paired: (1,2), (3,4), (5,6), (7,8)
    col_x = 2*i - 1;
    col_y = 2*i;
    
    t_raw = rawData(:, col_x);
    disp_raw = rawData(:, col_y);
    
    % 1. Clean NaNs
    valid_idx = ~isnan(t_raw) & ~isnan(disp_raw);
    t_clean = t_raw(valid_idx);
    disp_clean = disp_raw(valid_idx);
    
    % 2. FIX: Sort the data chronologically to prevent backward-drawing plot artifacts
    [t_sorted, sort_order] = sort(t_clean);
    disp_sorted = disp_clean(sort_order);
    
    % 3. Store sorted data
    sphereData(i).mass_kg = masses(i);
    sphereData(i).t_exp_ms = t_sorted;
    sphereData(i).disp_exp_cm = disp_sorted;
    
    % Convert to standard SI units (Seconds and Meters) for the optimizer
    sphereData(i).t_exp = sphereData(i).t_exp_ms / 1000;
    sphereData(i).disp_exp = sphereData(i).disp_exp_cm / 100;
end

%% 2. Setup Fixed Physical Parameters (Ritzel M-Series)
p.R = 0.0715;             % Radius of M-series sphere (14.3 cm diameter / 2)
p.rho = 1.225;            % Air density (kg/m^3)
p.A = pi * p.R^2;         % Frontal area (m^2)
p.Ps = 125000;            % Peak overpressure (Pa)
p.tau = 0.006;            % Positive phase duration (s)
p.c = 343;                % Locked wave speed (m/s)
p.t0 = 0.0;               % Time delay (s)

%% 3. Optimization Setup & Loop
% Bounds [W, d0, Cd]
lb = [1.0,  1.0,  0.2]; 
ub = [500,  100,  3.0];

options = optimoptions('fmincon', ...
    'Display', 'none', ... % Set to 'iter' if you want to watch the convergence
    'Algorithm', 'sqp', ...
    'StepTolerance', 1e-4, ...
    'OptimalityTolerance', 1e-4);

% Array to store results
results = struct();

fprintf('Starting optimization loop across %d spheres...\n', length(masses));

for i = 1:length(masses)
    fprintf('\n--- Optimizing for Sphere %d (%.3f kg) ---\n', i, masses(i));
    
    % Update the mass in the physics struct
    p.m = masses(i);
    
    % Get local experimental data
    t_exp = sphereData(i).t_exp;
    disp_exp = sphereData(i).disp_exp;
    
    % Adaptive Initial Guess (Heavier spheres move less, so drag effects might optimize differently)
    params0 = [15, 10, 1.0]; 

    % Run fmincon
    optParams = fmincon(@(params) costFunc(params, t_exp, disp_exp, p), ...
                        params0, [], [], [], [], lb, ub, [], options);

    % Save Optimal Parameters
    results(i).W = optParams(1);
    results(i).d0 = optParams(2);
    results(i).Cd = optParams(3);
    
    fprintf('  Optimized W:   %.2f kg\n', results(i).W);
    fprintf('  Optimized d0:  %.2f m\n', results(i).d0);
    fprintf('  Optimized Cd:  %.3f\n', results(i).Cd);
    
    % Run final ODE simulation with optimal parameters
    p_opt = p;
    p_opt.W = results(i).W;
    p_opt.d0 = results(i).d0;
    p_opt.Cd = results(i).Cd;
    p_opt.crW = p_opt.W^(1/3);

    IC = [p_opt.d0; 0];
    ode_options = odeset('MaxStep', 0.0005);
    [t_sim, xDot] = ode45(@(t, X) sphereDynamicsOpt(t, X, p_opt), [0 max(t_exp)], IC, ode_options);
    
    disp_sim = xDot(:,1) - p_opt.d0;
    
    % Store simulation data (converted to ms and cm)
    results(i).t_sim_ms = t_sim * 1000;
    results(i).disp_sim_cm = disp_sim * 100;
    
    % --- Error Calculation ---
    % Interpolate the ODE solution to exactly match experimental time stamps
    disp_sim_interp = interp1(t_sim, disp_sim, t_exp, 'linear', 'extrap');
    
    % Absolute Error in cm
    results(i).err_cm = abs(disp_sim_interp - disp_exp) * 100;
    
    % Percent Error (guarded against division by zero at t=0)
    safe_disp_exp = max(disp_exp, 1e-4); 
    results(i).pct_err = (abs(disp_sim_interp - disp_exp) ./ safe_disp_exp) * 100;
end

fprintf('\n=== ALL OPTIMIZATIONS COMPLETE ===\n');

%% 4. Reporting and Plotting Results
% Ensure figure directory exists
figDir = 'figs';
if ~exist(figDir, 'dir'), mkdir(figDir); end

% --- Save Parameter Report ---
fid = fopen('optimized_parameters_report.txt', 'w');
fprintf(fid, 'Ritzel Sphere Optimization Results\n');
fprintf(fid, '==================================\n\n');
for i = 1:length(masses)
    fprintf(fid, 'Sphere %d (%.0f g):\n', i, masses(i)*1000);
    fprintf(fid, '  W  (Equivalent Mass) = %.2f kg\n', results(i).W);
    fprintf(fid, '  d0 (Standoff Dist)   = %.2f m\n', results(i).d0);
    fprintf(fid, '  Cd (Drag Coeff)      = %.3f\n\n', results(i).Cd);
end
fclose(fid);
fprintf('\nSaved parameter report to optimized_parameters_report.txt\n');

% --- Save Parameter Report as MDPI LaTeX Table ---
texFile = 'optimized_parameters_table.txt';
fid = fopen(texFile, 'w');

% Write table header and MDPI formatting
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\caption{Optimized parameters for Ritzel M-Series spheres.}\\label{tab:optimization_results}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '%% \\tablesize{} %% Un-comment to change table size if needed (e.g., \\tablesize{\\footnotesize})\n');
fprintf(fid, '\\begin{tabular}{ccccc}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, '\\textbf{Sphere} & \\textbf{Mass (g)} & \\textbf{$W$ (kg)} & \\textbf{$d_0$ (m)} & \\textbf{$C_d$} \\\\\n');
fprintf(fid, '\\midrule\n');

% Write row data for each sphere
for i = 1:length(masses)
    fprintf(fid, '%d & %.0f & %.2f & %.2f & %.3f \\\\\n', ...
        i, masses(i)*1000, results(i).W, results(i).d0, results(i).Cd);
end

% Write table footer
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);

fprintf('\nSaved LaTeX parameter report to %s\n', texFile);

% --- Formatting Setup ---
% colors = lines(length(masses)); % Generate distinct colors
colors = [1, 1, 248;
          254, 3, 2;
          150, 205, 4;
          1, 45, 1]./255;
lw = 1.2;
ticks = linspace(0,round(max(t_exp)*1000),7);

% === FIGURE 1: Trajectory Comparison ===
fig1 = figure('Name', 'Multi-Sphere Trajectories', 'Color', 'w');
hold on; grid on;

for i = 1:length(masses)
    % Plot Experimental Data using SCATTER to properly handle alpha (transparency)
    scatter(sphereData(i).t_exp_ms, sphereData(i).disp_exp_cm, 6, colors(i,:), 'filled', ...
        'MarkerFaceAlpha', 0.3, 'MarkerEdgeAlpha', 0.3, 'HandleVisibility', 'off');
    % plot(sphereData(i).t_exp_ms, sphereData(i).disp_exp_cm, 12, colors(i,:), '--', ...
    %     'Color', [colors(i,:), 0.3], 'LineWidth', lw/2, ...
    %     'DisplayName', sprintf('%.0f g', masses(i)*1000), ...
    %     'LineStyle', '--');
    
    % Plot Simulated Fits (Dashed lines to contrast with dots)
    plot(results(i).t_sim_ms, results(i).disp_sim_cm, '-', ...
        'Color', colors(i,:), 'LineWidth', lw, ...
        'DisplayName', sprintf('%.0f g', masses(i)*1000));
end

xlabel('Time (ms)', 'Interpreter', 'latex');
ylabel('Displacement (cm)', 'Interpreter', 'latex');
xlim([0,round(max(t_exp)*1000)])
xticks(ticks)
legend('Location', 'northwest', 'Interpreter', 'latex', 'Box', 'off');

% Apply MDPI half-figure formatting
formatMDPIFigure(fig1, 'half');

% Export if savePlot is available in your subroutines
savePlot(fig1, 'Ritzel_Displacement_Fit', figDir);

% === FIGURE 2: Percent Difference ===
fig2 = figure('Name', 'Fit Percent Error', 'Color', 'w');
hold on; grid on;

for i = 1:length(masses)
    % Ignore early points where displacement is < 0.1 cm to avoid the divide-by-zero spike
    valid_idx = sphereData(i).disp_exp_cm > 0.1;
    t_plot = sphereData(i).t_exp_ms(valid_idx);
    err_plot = results(i).pct_err(valid_idx);
    
    plot(t_plot, err_plot, '-', 'Color', colors(i,:), 'LineWidth', lw, ...
         'DisplayName', sprintf('%.0f g', masses(i)*1000));
end
xlim([0,round(max(t_exp)*1000)])
xticks(ticks)
xlabel('Time (ms)', 'Interpreter', 'latex');
ylabel('Percent Difference (\%)', 'Interpreter', 'latex');

% Legend only appears here now
% legend('Location', 'northeast', 'Interpreter', 'latex', 'Box', 'off');
ylim([0 50]); % Cap Y-axis to prevent any remaining noise from blowing out the scale

% Apply MDPI half-figure formatting
formatMDPIFigure(fig2, 'half');

% Export if savePlot is available in your subroutines
savePlot(fig2, 'Ritzel_Percent_Error', figDir);

% === FIGURE 3: Absolute Error ===
fig3 = figure('Name', 'Fit Absolute Error', 'Color', 'w');
hold on; grid on;

for i = 1:length(masses)
    % Plot the absolute error directly (no filtering needed since it handles t=0 safely)
    plot(sphereData(i).t_exp_ms, results(i).err_cm, '-', 'Color', colors(i,:), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('%.0f g', masses(i)*1000));
end
xlim([0,round(max(t_exp)*1000)])
xticks(ticks)
xlabel('Time (ms)', 'Interpreter', 'latex');
ylabel('Absolute Error (cm)', 'Interpreter', 'latex');

% legend('Location', 'northwest', 'Interpreter', 'latex', 'Box', 'off');
ylim([0 inf]); % Lock bottom to 0, let MATLAB auto-scale the top

% Apply MDPI half-figure formatting
formatMDPIFigure(fig3, 'half');

% Export if savePlot is available in your subroutines
savePlot(fig3, 'Ritzel_Absolute_Error', figDir);

%% ================== LOCAL FUNCTIONS ==================

function sse = costFunc(params, t_exp, disp_exp, p)
    % Unpack optimizer parameters
    p.W = params(1);
    p.d0 = params(2);
    p.Cd = params(3);
    p.crW = p.W^(1/3);
    
    % Run Simulation
    IC = [p.d0; 0];
    options = odeset('MaxStep', 0.0005);
    [t_sim, xDot] = ode45(@(t, X) sphereDynamicsOpt(t, X, p), [0 max(t_exp)], IC, options);
    
    % Calculate simulated displacement
    disp_sim = xDot(:,1) - p.d0;
    
    % Interpolate ODE solution to match experimental time stamps exactly
    disp_sim_interp = interp1(t_sim, disp_sim, t_exp, 'linear', 'extrap');
    
    % Calculate Sum of Squared Errors (cost)
    sse = sum((disp_sim_interp - disp_exp).^2);
end

function dX = sphereDynamicsOpt(t, X, p)
    x1 = X(1); % Position
    x2 = X(2); % Velocity
    
    % Create spatial slice array over the sphere
    x_bar = linspace(-p.R, p.R, 50); 
    x_sphere = x1 + x_bar;    
    x0 = x1 - p.R;            % Front face of the sphere
    
    % Calculate pressure field over the sphere volume
    pp = zeros(size(x_sphere));
    for i = 1:length(x_sphere)
        val = t - (x_sphere(i) - x0) / p.c;
        Dt = val - p.t0;
        if Dt >= 0
            eps_val = Dt / p.tau;
            pp(i) = p.Ps * exp(-eps_val) * (1 - eps_val);
        end
    end
    
    % Calculate Force using corrected planar slice integration
    Fp = trapz(x_bar, pp .* x_bar) * -2 * pi;
    
    % Wind Velocity (Evaluated at sphere center)
    val_center = t - (x1 - x0) / p.c;
    Dt_wind = val_center - p.t0;
    
    if Dt_wind >= 0
        scaledDist = x1 / p.crW;
        scaledTime = p.c * Dt_wind / p.crW; 
        
        [Vs_i, alpha_i, beta_i, a_i, ~] = deweyParams(scaledDist);
        logArg = max(1e-10, 1 + beta_i * scaledTime);
        
        V = p.c * ((Vs_i*(1-beta_i*scaledTime) * exp(-alpha_i*scaledTime) + a_i*log(logArg)) * exp(-scaledTime));
    else
        V = 0;
    end
    
    % Aerodynamic Drag
    vr = x2 - V; % Relative velocity
    drag = -sign(vr) * 0.5 * p.rho * p.A * p.Cd * vr^2;
    
    % State derivatives
    x1Dot = x2;
    x2Dot = (Fp + drag) / p.m;
    dX = [x1Dot; x2Dot];
end