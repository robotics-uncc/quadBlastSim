% Convert blast orientation to radians
phiB = deg2rad(phiB);
thetaB = deg2rad(thetaB);

% Calculate initial condition
IC = [d0*sin(phiB)*cos(thetaB) d0*sin(phiB)*sin(thetaB) d0*cos(phiB)];

% Set name for figure folder
figDir = append(mainFigDirName,'/d',string(d0),'m/');
mkdir(figDir)

% Set simulink model name
mdl = 'UAVSim.slx';

% Set blast constants
c = 360; % Value from blastfoam data fit
blastParams = [thetaB, phiB, c, W];

% Set general vehicle constants
beta = [pi/4, 5*pi/4, 3*pi/4, 7*pi/4]; 
dQuad = (rBody*2)+(rMotors*2)+(L*2);
RMOTOR_iG = zeros(4,3);
for k = 1:height(RMOTOR_iG)
    RMOTOR_iG(k,1) = (rMotors+L)*cos(beta(k));
    RMOTOR_iG(k,2) = (rMotors+L)*sin(beta(k));
end
quadDims = [rBody, rMotors, L];
desRPM = motorRPM*ones(4,1);

% Set constants
g = 9.81;
m = mBody + 4*mMotor + 4*mArm;
rpm_max  = 10000;
rpm_nom = rpm_max/2; % feedforward term
CT = m*g/4/rpm_nom^2; % thrust coefficient 
rho = 1.225; % air density kg/m^3
bodyA = pi*rBody^2; % surface area m^2
motorA = pi*rMotors^2; % surface area m^2
CD = 1.17;
dragConstsMotor = -1/2*rho*motorA*CD;
dragConstsBody = -1/2*rho*bodyA*CD;

% Calculate inertia
Ibody = (2/5) * mBody * (rBody^2)*eye(3);
alpha = 2*(L+rBody)^2;
Imotors = mMotor*diag([alpha alpha 2*alpha]);
gamma = ((L^2)/6) + 2*((L/2) + rMotors)^2;
Iarms = mArm*diag([gamma gamma 2*gamma]);
Iquad = Ibody + Iarms + Imotors;


% Motor mixer 
rpm2bodyMomentRollPitch = [-L L L -L; % roll moment
                           L -L L -L]; % pitch moment
CM = 0.1; % yaw coefficient