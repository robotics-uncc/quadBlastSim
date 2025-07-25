%% Make a plot of all of the states over time for the simulation
thisFig = figure(5);
set(thisFig,'Color','w','Units','inches','Position',[0 3 16 7])
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');

% Make a matrix of all plotted variables
plotVars = [X-d0 XDot U rad2deg(phi) rad2deg(phiDot) rad2deg(p) Y YDot V rad2deg(theta) rad2deg(thetaDot) rad2deg(q) Z ZDot W rad2deg(psi) rad2deg(psiDot) rad2deg(r)];
plotLabs = ["$\Delta X$ (m)"; "$\dot{X}$ (m/s)"; "$u$ (m/s)"; "$\phi$ (deg)"; "$\dot{\phi}$ (deg/s)"; "$p$ (deg/s)";
            "$\Delta Y$ (m)"; "$\dot{Y}$ (m/s)"; "$v$ (m/s)"; "$\theta$ (deg)"; "$\dot{\theta}$ (deg/s)"; "$q$ (deg/s)";
            "$\Delta Z$ (m)"; "$\dot{Z}$ (m/s)"; "$w$ (m/s)"; "$\psi$ (deg)"; "$\dot{\psi}$ (deg/s)"; "$r$ (deg/s)"];
titleLabs = ["Positions", "Inertial Velocity", "Body Velocity", "Euler Angles", "Euler Rates", "Body Rotaton Rates"];
lw = 1.2;

for i = 1:length(plotLabs)
    subplot(3,6,i)
    plot(t*1000,plotVars(:,i),'LineWidth',lw)
    grid on
    ylabel(plotLabs(i))
    if i > 12
        xlabel("Time (ms)")
    end
    if i <=6
        title(titleLabs(i))
    end
end
savePlot('states', figDir)

%% Make a plot of all of the forces over time for the simulation
thisFig = figure(6);
set(thisFig,'Color','w','Units','inches','Position',[0 0 16 9.5])
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');

% Make a matrix of all plotted variables
plotVars = [];
for i = 1:3
    plotVars = [plotVars weight(:,i) thrust(:,i) bodyDrag(:,i) motor1Drag(:,i) motor2Drag(:,i) motor3Drag(:,i) motor4Drag(:,i)];
end
titleLabs = ["Weight", "Thrust", "Body Drag", "Motor 1 Drag", "Motor 2 Drag", "Motor 3 Drag", "Motor 4 Drag"];

for i = 1:width(plotVars)
    subplot(3,7,i)
    plot(t*1000,plotVars(:,i),'LineWidth',lw)
    grid on
    if i > 14
        xlabel("Time (ms)")
    end
    if i <= 7
        title(titleLabs(i))
    end
    if i == 1
        ylabel("$F_{i_{1}}$")
    elseif i == 8
        ylabel("$F_{i_{2}}$")
    elseif i == 15
        ylabel("$F_{i_{3}}$")
    end
end
savePlot('forces', figDir)