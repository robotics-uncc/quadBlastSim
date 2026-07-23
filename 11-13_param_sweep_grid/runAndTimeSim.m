% serialSweepTiming.m
% Runs N simulation cases in serial and calculates execution time statistics.
clc; clear; close all;bdclose('all')

disp('Initializing workspace and physical constants...');

%% =======================================================
% 1. STATIC SIMULATION & VEHICLE PARAMETERS (Calculated Once)
% =======================================================
mdl = '../00_subroutines/UAVSim.slx';
simTime = 90/1000;
sampleTime = 0.0001;

% Fixed Vehicle & Blast properties
rBody = 0.05;    
rMotors = 0.05;  
L = 0.15;        
mBody = 1;       
mMotor = 0.2;    
mArm = 0.05;     
motorRPM = 5000; 
W = 10;          % Explosive mass (kg)
c = 343;         % Value from blastfoam data fit

% General vehicle constants 
beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
dQuad = (rBody*2)+(rMotors*2)+(L*2);
RMOTOR_iG = zeros(4,3);
for k = 1:height(RMOTOR_iG)
    RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
    RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
end
quadDims = [rBody, rMotors, L];
desRPM = motorRPM*ones(4,1);

% Physics Constants
g = 9.81;
m = mBody + 4*mMotor + 4*mArm;
rpm_max  = 10000;
rpm_nom = rpm_max/2; 
CT = m*g/4/rpm_nom^2; 
rho = 1.225; 
bodyA = pi*rBody^2; 
motorA = pi*rMotors^2; 
CD = 1.17;
dragConstsMotor = -1/2*rho*motorA*CD;
dragConstsBody = -1/2*rho*bodyA*CD;

% Inertia Calculations
Ibody = (2/5) * mBody * (rBody^2)*eye(3);
alpha_inertia = 2*(L+rBody)^2;
Imotors = mMotor*diag([alpha_inertia alpha_inertia 2*alpha_inertia]);
gamma = ((L^2)/6) + 2*((L/2) + rMotors)^2;
Iarms = mArm*diag([gamma gamma 2*gamma]);
Iquad = Ibody + Iarms + Imotors;

% Motor mixer 
rpm2bodyMomentRollPitch = [-L L L -L; L -L L -L]; 
CM = 0.1; 

%% =======================================================
% 2. SERIAL SWEEP SETUP & TIMING
% =======================================================
% Define number of runs (N)
N = 200; % Adjust this number to run more or fewer cases

% Preallocate array to store execution times
runTimes = zeros(N, 1);

% Create some dummy variation for the sweep (e.g., varying distance)
d0_vec = linspace(2.5, 20, N); 
i_val = 1; % Keeping angle static for this timing test

% Ensure the model is loaded into memory to avoid first-run overhead bias
load_system(mdl);

disp(['Starting Serial Execution of ', num2str(N), ' cases...']);

for idx = 1:N
    % Define variables for this specific run
    d0_val = d0_vec(idx);
    
    thetaB_deg = 90 - 30 * (i_val - 1);
    phiB_deg = 150 - 30 * (i_val - 1);
    thetaB_rad = deg2rad(thetaB_deg);
    phiB_rad = deg2rad(phiB_deg);
    
    IC_val = [d0_val*sin(phiB_rad)*cos(thetaB_rad), ...
              d0_val*sin(phiB_rad)*sin(thetaB_rad), ...
              d0_val*cos(phiB_rad)];
              
    blastParams_val = [thetaB_rad, phiB_rad, c, W];
    
    % Configure simulation input object
    simIn = Simulink.SimulationInput(mdl);
    simIn = simIn.setVariable('IC', IC_val);
    simIn = simIn.setVariable('blastParams', blastParams_val);
    
    % --- TIMING BLOCK ---
    t_start = tic;           % Start timer
    out = sim(simIn);        % Execute simulation in serial
    runTimes(idx) = toc(t_start); % Stop timer and record
    % --------------------
    
    fprintf('Run %d/%d completed in %.4f seconds.\n', idx, N, runTimes(idx));
end

disp('All simulations complete.');

%% =======================================================
% 3. CALCULATE AND DISPLAY STATISTICS
% =======================================================
meanTime = mean(runTimes);
medianTime = median(runTimes);
stdTime = std(runTimes);
minTime = min(runTimes);
maxTime = max(runTimes);
totalTime = sum(runTimes);

fprintf('\n========================================\n');
fprintf('       SERIAL EXECUTION STATISTICS      \n');
fprintf('========================================\n');
fprintf('Total Runs (N)  : %d\n', N);
fprintf('Total Wall Time : %.4f sec\n', totalTime);
fprintf('Mean Time       : %.4f sec\n', meanTime);
fprintf('Median Time     : %.4f sec\n', medianTime);
fprintf('Std Deviation   : %.4f sec\n', stdTime);
fprintf('Min Time        : %.4f sec\n', minTime);
fprintf('Max Time        : %.4f sec\n', maxTime);
fprintf('========================================\n');


%% =======================================================
% 4. GENERATE MDPI LATEX TABLES AND SAVE TO TXT
% =======================================================
disp('Generating MDPI LaTeX tables...');

fileName = 'mdpi_serial_tables.txt';
fid = fopen(fileName, 'w');

if fid == -1
    error('Cannot open file for writing.');
end

% --- Write Table 1: Summary Statistics ---
fprintf(fid, '%% Please ensure you have \\usepackage{booktabs} in your preamble\n\n');
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\caption{Summary of serial execution runtime statistics.\\label{tab:serial_stats}}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\begin{tabular}{lc}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, '\\textbf{Statistic} & \\textbf{Value} \\\\\n');
fprintf(fid, '\\midrule\n');
fprintf(fid, 'Total Runs (N)     & %d \\\\\n', N);
fprintf(fid, 'Total Wall Time    & %.4f s \\\\\n', totalTime);
fprintf(fid, 'Mean Time          & %.4f s \\\\\n', meanTime);
fprintf(fid, 'Median Time        & %.4f s \\\\\n', medianTime);
fprintf(fid, 'Standard Deviation & %.4f s \\\\\n', stdTime);
fprintf(fid, 'Minimum Time       & %.4f s \\\\\n', minTime);
fprintf(fid, 'Maximum Time       & %.4f s \\\\\n', maxTime);
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n\n');

fprintf(fid, '\\vspace{12pt}\n\n');

% --- Write Table 2: Individual Run Times ---
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\caption{Execution times for individual serial runs.\\label{tab:individual_runs}}\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\begin{tabular}{cc}\n');
fprintf(fid, '\\toprule\n');
fprintf(fid, '\\textbf{Run Number} & \\textbf{Execution Time (s)} \\\\\n');
fprintf(fid, '\\midrule\n');

% Loop through all runs and print them to the table
for idx = 1:N
    fprintf(fid, '%d & %.4f \\\\\n', idx, runTimes(idx));
end

fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');

fclose(fid);
disp(['MDPI LaTeX tables successfully saved to ', fileName]);