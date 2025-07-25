% Run this to get all the labels, ticks, and legend in latex formatting
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');

% Data indexes - https://www.mathworks.com/help/simulink/slref/simulink.simulationdata.dataset.html
posIdx = find(matches(out.logsout.getElementNames,'quadPos'));
velIdx = find(matches(out.logsout.getElementNames,'quadVel'));
bodyVelIdx = find(matches(out.logsout.getElementNames,'quadVelBody'));
eulIdx = find(matches(out.logsout.getElementNames,'quadEul'));
omegaIdx = find(matches(out.logsout.getElementNames,'quadOmega'));
omegaDotIdx = find(matches(out.logsout.getElementNames,'pqrDot'));
bodyForceIdx = find(matches(out.logsout.getElementNames,'bodyForces'));
bodyMomentIdx = find(matches(out.logsout.getElementNames,'bodyMoments'));
blastForceIdx = find(matches(out.logsout.getElementNames,'blastForces'));
blastMomentIdx = find(matches(out.logsout.getElementNames,'blastMoments'));
% bodyWindIdx = find(matches(out.logsout.getElementNames,'bodyWind'));
motorWindIdx = find(matches(out.logsout.getElementNames,'motorWind'));
allBlastFIdx = find(matches(out.logsout.getElementNames,'allBlastFInertial'));
weightIdx = find(matches(out.logsout.getElementNames,'weightInertial'));
% bodyDragBFIdx = find(matches(out.logsout.getElementNames,'bodyDragBodyFrame'));
bodyDragIFIdx = find(matches(out.logsout.getElementNames,'bodyDragInertialFrame'));
motorDragIdx = find(matches(out.logsout.getElementNames,'motorDragInertial'));
thrustIdx = find(matches(out.logsout.getElementNames,'thrustInertial'));
pressValsIdx = find(matches(out.logsout.getElementNames,'pressureValues'));
bodyWindIdx = find(matches(out.logsout.getElementNames,'bodyWindI'));
motorWindsIdx = find(matches(out.logsout.getElementNames,'motorWindsI'));

% Time
t = out.logsout{posIdx}.Values.Time;

% Quad position data
X = out.logsout{posIdx}.Values.Data(:,1);
Y = out.logsout{posIdx}.Values.Data(:,2);
Z = -out.logsout{posIdx}.Values.Data(:,3);

% Quad velocity data - inertial frame
XDot = out.logsout{velIdx}.Values.Data(:,1);
YDot = out.logsout{velIdx}.Values.Data(:,2);
ZDot = -out.logsout{velIdx}.Values.Data(:,3);

% Quad velocity data - body frame 
U = out.logsout{bodyVelIdx}.Values.Data(:,1);
V = out.logsout{bodyVelIdx}.Values.Data(:,2);
W = -out.logsout{bodyVelIdx}.Values.Data(:,3);

% Motor rpm data
% wt = out.logsout{rpmIdx}.Values.Time;
% w1 = out.logsout{rpmIdx}.Values.Data(:,1);
% w2 = out.logsout{rpmIdx}.Values.Data(:,2);
% w3 = out.logsout{rpmIdx}.Values.Data(:,3);
% w4 = out.logsout{rpmIdx}.Values.Data(:,4);

% Quad euler angles
phi = out.logsout{eulIdx}.Values.Data(:,1);
theta = out.logsout{eulIdx}.Values.Data(:,2);
psi = out.logsout{eulIdx}.Values.Data(:,3);

% Quad rotation rates
p = out.logsout{omegaIdx}.Values.Data(:,1);
q = out.logsout{omegaIdx}.Values.Data(:,2);
r = out.logsout{omegaIdx}.Values.Data(:,3);

% Euler rates calculation
tmpN = length(p);
phiDot = zeros(size(p)); thetaDot = zeros(size(q)); psiDot = zeros(size(r));
for i = 1:tmpN
    L = [1 sin(phi(i))*tan(theta(i)) cos(phi(i))*tan(theta(i)); 
         0 cos(phi(i)) -sin(phi(i));
         0 sin(phi(i))/cos(theta(i)) cos(phi(i))/cos(theta(i))];
    tmpRates = L*[p(i); q(i); r(i)];
    phiDot(i) = tmpRates(1); thetaDot(i) = tmpRates(2); psiDot(i) = tmpRates(3);
end

% Quad rotation accel
pDot = out.logsout{omegaDotIdx}.Values.Data(:,1);
qDot = out.logsout{omegaDotIdx}.Values.Data(:,2);
rDot = out.logsout{omegaDotIdx}.Values.Data(:,3);

% Control forces
bodyFx = squeeze(out.logsout{bodyForceIdx}.Values.Data(1,1,:));
bodyFy = squeeze(out.logsout{bodyForceIdx}.Values.Data(1,2,:));
bodyFz = -squeeze(out.logsout{bodyForceIdx}.Values.Data(1,3,:));

% Control moments
% bodyMx = squeeze(out.logsout{bodyMomentIdx}.Values.Data(:,1));
% bodyMy = squeeze(out.logsout{bodyMomentIdx}.Values.Data(:,2));
% bodyMz = squeeze(out.logsout{bodyMomentIdx}.Values.Data(:,3));
bodyMx = squeeze(out.logsout{bodyMomentIdx}.Values.Data(1,1,:));
bodyMy = squeeze(out.logsout{bodyMomentIdx}.Values.Data(1,2,:));
bodyMz = squeeze(out.logsout{bodyMomentIdx}.Values.Data(1,3,:));

% Summed blast forces
blastFx = squeeze(out.logsout{blastForceIdx}.Values.Data(1,1,:));
blastFy = squeeze(out.logsout{blastForceIdx}.Values.Data(1,2,:));
blastFz = -squeeze(out.logsout{blastForceIdx}.Values.Data(1,3,:));

% Summed blast moments
blastMx = squeeze(out.logsout{blastMomentIdx}.Values.Data(1,1,:));
blastMy = squeeze(out.logsout{blastMomentIdx}.Values.Data(1,2,:));
blastMz = squeeze(out.logsout{blastMomentIdx}.Values.Data(1,3,:));

% Individual blast forces
bodyBlastForces = squeeze(out.logsout{allBlastFIdx}.Values.Data(1,:,:))';
motor1BlastForces = squeeze(out.logsout{allBlastFIdx}.Values.Data(3,:,:))';
motor2BlastForces = squeeze(out.logsout{allBlastFIdx}.Values.Data(2,:,:))';
motor3BlastForces = squeeze(out.logsout{allBlastFIdx}.Values.Data(5,:,:))';
motor4BlastForces = squeeze(out.logsout{allBlastFIdx}.Values.Data(4,:,:))';

% Calculate azimuth and elevation over time for each individual blast force matrix
bodyBlastAngles =   [atan2(bodyBlastForces(2,:), bodyBlastForces(1,:)); acos(bodyBlastForces(3,:)./vecnorm(bodyBlastForces))];
motor1BlastAngles = [atan2(motor1BlastForces(2,:), motor1BlastForces(1,:)); acos(motor1BlastForces(3,:)./vecnorm(motor1BlastForces))];
motor2BlastAngles = [atan2(motor2BlastForces(2,:), motor2BlastForces(1,:)); acos(motor2BlastForces(3,:)./vecnorm(motor2BlastForces))];
motor3BlastAngles = [atan2(motor3BlastForces(2,:), motor3BlastForces(1,:)); acos(motor3BlastForces(3,:)./vecnorm(motor3BlastForces))];
motor4BlastAngles = [atan2(motor4BlastForces(2,:), motor4BlastForces(1,:)); acos(motor4BlastForces(3,:)./vecnorm(motor4BlastForces))];

% Get pressure values over time for each sphere
bodyPressures = squeeze(out.logsout{pressValsIdx}.Values.Data(1,:,:))/1000;
motor1Pressures = squeeze(out.logsout{pressValsIdx}.Values.Data(2,:,:))/1000;
motor2Pressures = squeeze(out.logsout{pressValsIdx}.Values.Data(3,:,:))/1000;
motor3Pressures = squeeze(out.logsout{pressValsIdx}.Values.Data(4,:,:))/1000;
motor4Pressures = squeeze(out.logsout{pressValsIdx}.Values.Data(5,:,:))/1000;

% % Calculate inertial angles over time for each individual blast force matrix
% bodyBlastAngles = [bodyBlastForces(1,:)./vecnorm(bodyBlastForces); bodyBlastForces(2,:)./vecnorm(bodyBlastForces); bodyBlastForces(3,:)./vecnorm(bodyBlastForces)];
% motor1BlastAngles = [motor1BlastForces(1,:)./vecnorm(motor1BlastForces); motor1BlastForces(2,:)./vecnorm(motor1BlastForces); motor1BlastForces(3,:)./vecnorm(motor1BlastForces)];
% motor2BlastAngles = [motor2BlastForces(1,:)./vecnorm(motor2BlastForces); motor2BlastForces(2,:)./vecnorm(motor2BlastForces); motor2BlastForces(3,:)./vecnorm(motor2BlastForces)];
% motor3BlastAngles = [motor3BlastForces(1,:)./vecnorm(motor3BlastForces); motor3BlastForces(2,:)./vecnorm(motor3BlastForces); motor3BlastForces(3,:)./vecnorm(motor3BlastForces)];
% motor4BlastAngles = [motor4BlastForces(1,:)./vecnorm(motor4BlastForces); motor4BlastForces(2,:)./vecnorm(motor4BlastForces); motor4BlastForces(3,:)./vecnorm(motor4BlastForces)];

% Body velocities
xBodyBlastWind = squeeze(out.logsout{bodyWindIdx}.Values.Data(1,1,:));
yBodyBlastWind = squeeze(out.logsout{bodyWindIdx}.Values.Data(1,2,:));
zBodyBlastWind = squeeze(out.logsout{bodyWindIdx}.Values.Data(1,3,:));

% Motor velocities
xMotorBlastWind = squeeze(out.logsout{motorWindIdx}.Values.Data(:,1,:));
yMotorBlastWind = squeeze(out.logsout{motorWindIdx}.Values.Data(:,2,:));
zMotorBlastWind = squeeze(out.logsout{motorWindIdx}.Values.Data(:,3,:));

% Forces at the body sphere
weight = squeeze(out.logsout{weightIdx}.Values.Data);
bodyDrag = squeeze(out.logsout{bodyDragIFIdx}.Values.Data)';
thrust = squeeze(out.logsout{thrustIdx}.Values.Data);

% Body and motor winds
bodyWind = squeeze(out.logsout{bodyWindIdx}.Values.Data)';
motor1Wind = squeeze(out.logsout{motorWindsIdx}.Values.Data(1,:,:))';
motor2Wind = squeeze(out.logsout{motorWindsIdx}.Values.Data(2,:,:))';
motor3Wind = squeeze(out.logsout{motorWindsIdx}.Values.Data(3,:,:))';
motor4Wind = squeeze(out.logsout{motorWindsIdx}.Values.Data(4,:,:))';

% Drag per motor
motor1Drag = squeeze(out.logsout{motorDragIdx}.Values.Data(1,:,:))';
motor2Drag = squeeze(out.logsout{motorDragIdx}.Values.Data(2,:,:))';
motor3Drag = squeeze(out.logsout{motorDragIdx}.Values.Data(3,:,:))';
motor4Drag = squeeze(out.logsout{motorDragIdx}.Values.Data(4,:,:))';

% Save the data with the plots
save(append(figDir,'Data.mat'),'t', 'X', 'Y', 'Z', 'XDot', 'YDot', 'ZDot', 'phiB', 'thetaB', 'psi', 'theta', 'phi', 'psiDot', 'thetaDot', 'phiDot', 'p', 'q', 'r', ...
    'pDot', 'qDot', 'rDot', 'bodyFx', 'bodyFy', 'bodyFz', 'bodyMx', 'bodyMy', 'bodyMz', ...
    'blastFx', 'blastFy', 'blastFz', 'blastMx', 'blastMy', 'blastMz', ...
    'xBodyBlastWind', 'yBodyBlastWind', 'zBodyBlastWind', 'xMotorBlastWind', 'yMotorBlastWind', 'zMotorBlastWind',...
    'motor1Drag','motor2Drag','motor3Drag','motor4Drag','weight','bodyDrag','thrust',...
    'bodyPressures','motor1Pressures','motor2Pressures','motor3Pressures','motor4Pressures',...
    'bodyBlastForces','motor1BlastForces','motor2BlastForces','motor3BlastForces','motor4BlastForces',...
    'bodyBlastAngles','motor1BlastAngles','motor2BlastAngles','motor3BlastAngles','motor4BlastAngles' )

% Plot options - xyz
plotOptsX.Color = [0 0.4470 0.7410];
plotOptsX.LineWidth = 2;
plotOptsX.DisplayName = '$x$';
plotOptsY.Color = [0.9290 0.6940 0.1250];
plotOptsY.LineWidth = 2;
plotOptsY.DisplayName = '$y$';
plotOptsZ.Color = [0.4660 0.6740 0.1880];
plotOptsZ.LineWidth = 2;
plotOptsZ.DisplayName = '$z$';

% Plot options - velocity
plotOptsU = plotOptsX;
plotOptsU.DisplayName = '$XDot$';
plotOptsV = plotOptsY;
plotOptsV.DisplayName = '$YDot$';
plotOptsW = plotOptsZ;
plotOptsW.DisplayName = '$ZDot$';

% Plot options - euler angles
plotOptsRoll = plotOptsX;
plotOptsRoll.DisplayName = '$\phi$';
plotOptsPitch = plotOptsY;
plotOptsPitch.DisplayName = '$\theta$';
plotOptsYaw = plotOptsZ;
plotOptsYaw.DisplayName = '$\psi$';

% Plot options - body rotation rates
plotOptsP = plotOptsX;
plotOptsP.DisplayName = '$p$';
plotOptsQ = plotOptsY;
plotOptsQ.DisplayName = '$q$';
plotOptsR = plotOptsZ;
plotOptsR.DisplayName = '$r$';

% Plot options - body rotation accel
plotOptsPDot = plotOptsX;
plotOptsPDot.DisplayName = '$\dot{p}$';
plotOptsQDot = plotOptsY;
plotOptsQDot.DisplayName = '$\dot{q}$';
plotOptsRDot = plotOptsZ;
plotOptsRDot.DisplayName = '$\dot{r}$';

% Plot options - motor rpms 
plotOptsW1 = plotOptsX;
plotOptsW1.DisplayName = 'Motor 1';
plotOptsW2 = plotOptsY;
plotOptsW2.DisplayName = 'Motor 2';
plotOptsW3 = plotOptsZ;
plotOptsW3.DisplayName = 'Motor 3';
plotOptsW4.Color = [0.4940 0.1840 0.5560];
plotOptsW4.LineWidth = 2;
plotOptsW4.DisplayName = 'Motor 4';

% Plot options - control forces/moments
plotOptsBodyFx = plotOptsX;
plotOptsBodyFx.DisplayName = '$F_{(body,x)}$';
plotOptsBodyFy = plotOptsY;
plotOptsBodyFy.DisplayName = '$F_{(body,y)}$';
plotOptsBodyFz = plotOptsZ;
plotOptsBodyFz.DisplayName = '$F_{(body,z)}$';
plotOptsBodyMx = plotOptsX;
plotOptsBodyMx.DisplayName = '$M_{(body,x)}$';
plotOptsBodyMy = plotOptsY;
plotOptsBodyMy.DisplayName = '$M_{(body,y)}$';
plotOptsBodyMz = plotOptsZ;
plotOptsBodyMz.DisplayName = '$M_{(body,z)}$';

% Plot options - blast forces/moments
plotOptsBlastFx = plotOptsX;
plotOptsBlastFx.DisplayName = '$F_{(blast,x)}$';
plotOptsBlastFy = plotOptsY;
plotOptsBlastFy.DisplayName = '$F_{(blast,y)}$';
plotOptsBlastFz = plotOptsZ;
plotOptsBlastFz.DisplayName = '$F_{(blast,z)}$';
plotOptsBlastMx = plotOptsX;
plotOptsBlastMx.DisplayName = '$M_{(blast,x)}$';
plotOptsBlastMy = plotOptsY;
plotOptsBlastMy.DisplayName = '$M_{(blast,y)}$';
plotOptsBlastMz = plotOptsZ;
plotOptsBlastMz.DisplayName = '$M_{(blast,z)}$';

% Plot options - blast wind
plotOptsBlastWindx = plotOptsX;
plotOptsBlastWindx.DisplayName = '$w_{x}$';
plotOptsBlastWindy = plotOptsY;
plotOptsBlastWindy.DisplayName = '$w_{y}$';
plotOptsBlastWindz = plotOptsZ;
plotOptsBlastWindz.DisplayName = '$w_{z}$';

% Figure options
figOpts.Position = [0, 0, 9, 10];
% figOpts.Position = [0, 0, 900, 1000];
% figOpts.Position = [100, 50, 900, 550];
figOpts.Color = 'w';
fntSize = 16;

% Plot options - calculated moments
plotOptsCalcMx = plotOptsX;
plotOptsCalcMx.DisplayName = '$M_{(\rm{calc body},x)}$';
plotOptsCalcMy = plotOptsY;
plotOptsCalcMy.DisplayName = '$M_{(\rm{calc body},y)}$';
plotOptsCalcMz = plotOptsZ;
plotOptsCalcMz.DisplayName = '$M_{(\rm{calc body},z)}$';