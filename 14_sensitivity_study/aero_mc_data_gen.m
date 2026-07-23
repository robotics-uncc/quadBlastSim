% aero_grid_data_gen.m
% Generates Grid Sweep data for terminal states (t = 90 ms)
% Focuses on sweeping Aerodynamic Drag (C_D) and Air Density (rho)
% for a single fixed blast distance and angle.
clc; clear; close all; bdclose('all')

% Add subroutines to the client path
addpath('../');
addpath('../00_subroutines/');

if isempty(gcp('nocreate'))
    parpool('Processes');
end

disp('Initializing workspace and physical constants for Aero Grid Sweep...');

%% =======================================================
% 1. SWEEP CONFIGURATION
% =======================================================
addpath(fullfile(pwd, '../00_subroutines/'));
% mdl = '../00_subroutines/UAVSim.slx';
mdl = 'UAVSim';
load_system(mdl);

max_time_s = 0.090; % Terminal state extraction time (90 ms)
simTime = 0.09;
sampleTime = 0.0001;

% --- FIXED BLAST CONDITIONS ---
d0_val = 5.0;      % Fixed standoff distance (m)
alpha_case = 1;    % Fixed angle case
thetaB_deg = 90 - 30 * (alpha_case - 1);
phiB_deg = 150 - 30 * (alpha_case - 1);
thetaB_rad = deg2rad(thetaB_deg);
phiB_rad = deg2rad(phiB_deg);

IC_val = [d0_val*sin(phiB_rad)*cos(thetaB_rad), ...
          d0_val*sin(phiB_rad)*sin(thetaB_rad), ...
          d0_val*cos(phiB_rad)];

W = 10;          
c = 343;         
blastParams_val = [thetaB_rad, phiB_rad, c, W];

% --- GRID SWEEP PARAMETERS ---
n = 6;
centerCD = 0.47;
centerRho = 1.225;

% CD_vec  = linspace(centerCD - centerCD/2, centerCD + centerCD/2, n);
CD_vec = linspace(centerCD, centerCD + centerCD/2, n);
rho_vec = linspace(centerRho, centerRho + centerRho/2, n);

totalSims = n * n;

% Base Nominal Physical Parameters (LOCKED)
beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
g = 9.81;
rpm_nom = 5000; 
desRPM = rpm_nom*ones(4,1);
CM = 0.1; % Yaw coefficient

nom_rBody = 0.05;    nom_rMotors = 0.05;  nom_L = 0.15;        
nom_mBody = 1.0;     nom_mMotor = 0.2;    nom_mArm = 0.05;     

%% =======================================================
% 2. BUILD PARALLEL SIMULATION INPUTS
% =======================================================
in = repmat(Simulink.SimulationInput(mdl), 1, totalSims);
disp(['Configuring ', num2str(totalSims), ' simulation inputs (C_D vs \rho)...']);

idx = 1;
for rIdx = 1:n
    rho_val = rho_vec(rIdx);
    
    for cIdx = 1:n
        CD_val = CD_vec(cIdx);
        
        % --- Lock Physical Parameters ---
        rBody = nom_rBody;    rMotors = nom_rMotors;  L = nom_L;        
        mBody = nom_mBody;    mMotor = nom_mMotor;    mArm = nom_mArm;
        
        m_total = mBody + 4*mMotor + 4*mArm;
        CT_val = m_total * g / 4 / rpm_nom^2; 
        
        bodyA = pi*rBody^2; 
        motorA = pi*rMotors^2; 
        
        % INJECTING DENSITY AND CD UNCERTAINTY HERE
        dragConstsMotor_val = -1/2 * rho_val * motorA * CD_val;
        dragConstsBody_val  = -1/2 * rho_val * bodyA  * CD_val;
        
        RMOTOR_iG_val = zeros(4,3);
        for k = 1:4
            RMOTOR_iG_val(k,1) = (rMotors+L)*cos(beta(k));
            RMOTOR_iG_val(k,2) = (rMotors+L)*sin(beta(k));
        end
        
        Ibody = (2/5) * mBody * (rBody^2)*eye(3);
        alpha_inertia = 2*(L+rBody)^2;
        Imotors = mMotor*diag([alpha_inertia alpha_inertia 2*alpha_inertia]);
        gamma_inertia = ((L^2)/6) + 2*((L/2) + rMotors)^2;
        Iarms = mArm*diag([gamma_inertia gamma_inertia 2*gamma_inertia]);
        Iquad_val = Ibody + Iarms + Imotors;
        
        quadDims_val = [rBody, rMotors, L];
        rpm2bodyMomentRollPitch_val = [-L L L -L; L -L L -L]; 
        
        % --- Inject Variables ---
        in(idx) = in(idx).setVariable('IC', IC_val);
        in(idx) = in(idx).setVariable('blastParams', blastParams_val);
        in(idx) = in(idx).setVariable('CD', CD_val);
        in(idx) = in(idx).setVariable('rho', rho_val); % Just in case Simulink uses it raw
        in(idx) = in(idx).setVariable('dragConstsMotor', dragConstsMotor_val);
        in(idx) = in(idx).setVariable('dragConstsBody', dragConstsBody_val);
        in(idx) = in(idx).setVariable('m', m_total);
        in(idx) = in(idx).setVariable('mBody', mBody);
        in(idx) = in(idx).setVariable('mMotor', mMotor);
        in(idx) = in(idx).setVariable('mArm', mArm);
        in(idx) = in(idx).setVariable('CT', CT_val);
        in(idx) = in(idx).setVariable('RMOTOR_iG', RMOTOR_iG_val);
        in(idx) = in(idx).setVariable('Iquad', Iquad_val);
        in(idx) = in(idx).setVariable('quadDims', quadDims_val);
        in(idx) = in(idx).setVariable('desRPM', desRPM);
        in(idx) = in(idx).setVariable('CM', CM);
        in(idx) = in(idx).setVariable('rpm2bodyMomentRollPitch', rpm2bodyMomentRollPitch_val);
        
        idx = idx + 1;
    end
end

%% =======================================================
% 3. RUN PARALLEL SIMULATIONS
% =======================================================
disp('Starting Parallel Sweep...');
tic;
out = parsim(in, 'ShowProgress', 'on', ...
             'TransferBaseWorkspaceVariables', 'on', ...
             'SetupFcn', @() addpath('../00_subroutines/'));
toc;
disp('Simulations complete. Extracting 90ms terminal states...');

%% =======================================================
% 4. EXTRACT TERMINAL STATES (Matrix Format for Imagesc)
% =======================================================
% Preallocate matrix: (Density Rows) x (CD Columns) x (12 States)
terminal_states = zeros(n, n, 12);

idx = 1;
for rIdx = 1:n
    for cIdx = 1:n
        
        if ~isempty(out(idx).ErrorMessage)
            error('\n--- SIMULINK ERROR AT RUN %d ---\n%s\n--------------------------------\n', ...
                  idx, out(idx).ErrorMessage);
        end

        try
            names = out(idx).logsout.getElementNames;
            posIdx   = find(matches(names, 'quadPos'));
            velIdx   = find(matches(names, 'quadVel'));
            eulIdx   = find(matches(names, 'quadEul'));
            omegaIdx = find(matches(names, 'quadOmega'));
            
            t_sim = out(idx).logsout{posIdx}.Values.Time;
            [~, t_idx] = min(abs(t_sim - max_time_s));
            
            X_term = out(idx).logsout{posIdx}.Values.Data(t_idx,1) - out(idx).logsout{posIdx}.Values.Data(1,1);
            Y_term = out(idx).logsout{posIdx}.Values.Data(t_idx,2) - out(idx).logsout{posIdx}.Values.Data(1,2);
            Z_term = -(out(idx).logsout{posIdx}.Values.Data(t_idx,3) - out(idx).logsout{posIdx}.Values.Data(1,3));
            
            XDot_term = out(idx).logsout{velIdx}.Values.Data(t_idx,1);
            YDot_term = out(idx).logsout{velIdx}.Values.Data(t_idx,2);
            ZDot_term = -out(idx).logsout{velIdx}.Values.Data(t_idx,3);
            
            phi_term   = rad2deg(out(idx).logsout{eulIdx}.Values.Data(t_idx,1));
            theta_term = rad2deg(out(idx).logsout{eulIdx}.Values.Data(t_idx,2));
            psi_term   = rad2deg(out(idx).logsout{eulIdx}.Values.Data(t_idx,3));
            
            p_term = rad2deg(out(idx).logsout{omegaIdx}.Values.Data(t_idx,1));
            q_term = rad2deg(out(idx).logsout{omegaIdx}.Values.Data(t_idx,2));
            r_term = rad2deg(out(idx).logsout{omegaIdx}.Values.Data(t_idx,3));
            
        catch ME
            error('Data Extraction Failed at idx %d. Error: %s', idx, ME.message);
        end
        
        % Store all 12 states into the 3D matrix
        terminal_states(rIdx, cIdx, :) = [X_term, XDot_term, theta_term, q_term, ...
                                          Y_term, YDot_term, phi_term, p_term, ...
                                          Z_term, ZDot_term, psi_term, r_term];
        idx = idx + 1;
    end
end

% Save workspace variables needed for plotting
save('grid_aero_data.mat', 'terminal_states', 'CD_vec', 'rho_vec', 'd0_val', 'alpha_case');
disp('Grid data successfully extracted and saved to grid_aero_data.mat!');