% % Quad position plot
% xyzFig = figure();
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,X,plotOptsX)
% hold on
% plot(t,Y,plotOptsY)
% plot(t,Z,plotOptsZ)
% grid on
% xlabel('Time (s)')
% ylabel('Position (m)')
% legend('Location','best')
% savePlot('xyzFig', figDir)
%
% % Quad velocity plot
% uvwFig = figure();
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,U,plotOptsU)
% hold on
% plot(t,V,plotOptsV)
% plot(t,W,plotOptsW)
% grid on
% xlabel('Time (s)')
% ylabel('Velocity (m/s)')
% legend('Location','best')
% savePlot('uvwFig', figDir)
% Quad position plot
% xyzFig = figure();
comboFig = figure(1);
set(comboFig,'Color','w','Units','inches','Position',[0 3 9 4.5])
set(groot, 'defaultAxesTickLabelInterpreter','latex'); set(groot, 'defaultLegendInterpreter','latex'); set(groot, 'defaultTextInterpreter','latex');

subplot(4,2,1)
ax = gca;
% ax.FontSize = fntSize;
set(gcf,figOpts)
plot(t,X-d0,plotOptsX)
hold on
plot(t,Y,plotOptsY)
plot(t,Z,plotOptsZ)
grid on
xlabel('Time (s)')
ylabel('Position Deviation (m)')
legend('Location','best')
% savePlot('xyzFig', figDir)
% Quad velocity plot
% uvwFig = figure();
subplot(4,2,2)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
plot(t,U,plotOptsU)
hold on
plot(t,V,plotOptsV)
plot(t,W,plotOptsW)
grid on
xlabel('Time (s)')
ylabel('Velocity (m/s)')
legend('Location','best')
% savePlot('uvwFig', figDir)
% Quad euler angles
subplot(4,2,3)
ax = gca;
ax.FontSize = fntSize;
set(gcf,figOpts)
plot(t,rad2deg(phi),plotOptsRoll)
hold on
plot(t,rad2deg(theta),plotOptsPitch)
plot(t,rad2deg(psi),plotOptsYaw)
grid on
xlabel('Time (s)')
ylabel('Angles (deg)')
legend('Location','best')

% Quad rotation rates
subplot(4,2,4)
ax = gca;
ax.FontSize = fntSize;
set(gcf,figOpts)
plot(t,p,plotOptsP)
hold on
plot(t,q,plotOptsQ)
plot(t,r,plotOptsR)
grid on
xlabel('Time (s)')
ylabel('Angular Velocity (rad/s)')
legend('Location','best')

% Body frame forces
subplot(4,2,5)
% subplot(2,1,1)
plot(t,bodyFx,plotOptsBodyFx)
hold on
plot(t,bodyFy,plotOptsBodyFy)
plot(t,bodyFz,plotOptsBodyFz)
grid on
xlabel('Time (s)')
ylabel('Body Forces (N)')
legend('Location','best')

% subplot(2,1,2)
subplot(4,2,6)
plot(t,bodyMx,plotOptsBodyMx)
hold on
plot(t,bodyMy,plotOptsBodyMy)
plot(t,bodyMz,plotOptsBodyMz)
grid on
xlabel('Time (s)')
ylabel('Body Moments (Nm)')
legend('Location','best')
savePlot('bodyForceMomentsFig', figDir)

% Blast forces and moments
% blastForceMomentsFig = figure();
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% subplot(2,1,1)
subplot(4,2,7)
plot(t,blastFx,plotOptsBlastFx)
hold on
plot(t,blastFy,plotOptsBlastFy)
plot(t,blastFz,plotOptsBlastFz)
grid on
xlabel('Time (s)')
ylabel('Blast Forces (N)')
legend('Location','best')

% subplot(2,1,2)
subplot(4,2,8)
plot(t,blastMx,plotOptsBlastMx)
hold on
plot(t,blastMy,plotOptsBlastMy)
plot(t,blastMz,plotOptsBlastMz)
grid on
xlabel('Time (s)')
ylabel('Blast Moments (Nm)')
legend('Location','best')
savePlot('comboFig', figDir)
% 
% % % Quad euler angles
% % rpyFig = figure();
% % ax = gca;
% % ax.FontSize = fntSize;
% % set(gcf,figOpts)
% % plot(t,phi,plotOptsRoll)
% % hold on
% % plot(t,theta,plotOptsPitch)
% % plot(t,psi,plotOptsYaw)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Angles (rad)')
% % legend('Location','best')
% % savePlot('rpyFig', figDir)
% 
% % % Quad rotation rates
% % pqrFig = figure();
% % ax = gca;
% % ax.FontSize = fntSize;
% % set(gcf,figOpts)
% % plot(t,p,plotOptsP)
% % hold on
% % plot(t,q,plotOptsQ)
% % plot(t,r,plotOptsR)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Angular Velocity (rad/s)')
% % legend('Location','best')
% % savePlot('pqrFig', figDir)
% 
% % Quad rotation accel
% figOpts.Position = [100, 50, 900, 550];
% pqrDotFig = figure();
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,pDot,plotOptsPDot)
% hold on
% plot(t,qDot,plotOptsQDot)
% plot(t,rDot,plotOptsRDot)
% grid on
% xlabel('$Time (s)$')
% ylabel('$Angular Accel (rad/s^2)$')
% legend('Location','best')
% savePlot('pqrDotFig', figDir)
% 
% % Expected moments
% expMoment = figure();
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,pDot*Iquad(1,1),plotOptsCalcMx)
% hold on
% plot(t,qDot*Iquad(2,2),plotOptsCalcMy)
% plot(t,rDot*Iquad(3,3),plotOptsCalcMz)
% grid on
% xlabel('Time (s)')
% ylabel('Moment (Nm)')
% % legend('Location','best')
% savePlot('expMoment', figDir)
% 
% % % Motor rpms
% % motorSpeedFig = figure();
% % ax = gca;
% % ax.FontSize = fntSize;
% % set(gcf,figOpts)
% % plot(wt,w1,plotOptsW1)
% % hold on
% % plot(wt,w2,plotOptsW2)
% % plot(wt,w3,plotOptsW3)
% % plot(wt,w4,plotOptsW4)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Motor Speed (rpm)')
% % legend('Location','best')
% % savePlot('motorSpeedFig', figDir)
% % Control forces and moments
% % bodyForceMomentsFig = figure();
% % figure(1);
% % ax = gca;
% % ax.FontSize = fntSize;
% % set(gcf,figOpts)
% % subplot(3,2,3)
% % % subplot(2,1,1)
% % plot(t,bodyFx,plotOptsBodyFx)
% % hold on
% % plot(t,bodyFy,plotOptsBodyFy)
% % plot(t,bodyFz,plotOptsBodyFz)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Body Forces (N)')
% % legend('Location','best')
% 
% % % subplot(2,1,2)
% % subplot(3,2,4)
% % plot(t,bodyMx,plotOptsBodyMx)
% % hold on
% % plot(t,bodyMy,plotOptsBodyMy)
% % plot(t,bodyMz,plotOptsBodyMz)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Body Moments (Nm)')
% % legend('Location','best')
% % savePlot('bodyForceMomentsFig', figDir)
% 
% % % Blast forces and moments
% % % blastForceMomentsFig = figure();
% % % ax = gca;
% % % ax.FontSize = fntSize;
% % % set(gcf,figOpts)
% % % subplot(2,1,1)
% % subplot(3,2,5)
% % plot(t,blastFx,plotOptsBlastFx)
% % hold on
% % plot(t,blastFy,plotOptsBlastFy)
% % plot(t,blastFz,plotOptsBlastFz)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Blast Forces (N)')
% % legend('Location','best')
% 
% % % subplot(2,1,2)
% % subplot(3,2,6)
% % plot(t,blastMx,plotOptsBlastMx)
% % hold on
% % plot(t,blastMy,plotOptsBlastMy)
% % plot(t,blastMz,plotOptsBlastMz)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Blast Moments (Nm)')
% % legend('Location','best')
% % savePlot('comboFig', figDir)
% % savePlot('blastForceMomentsFig', figDir)
% % % Body blast wind velocities
% % bodyWind = figure();
% % ax = gca;
% % ax.FontSize = fntSize;
% % set(gcf,figOpts)
% % plot(t,xBodyBlastWind,plotOptsBlastWindx)
% % hold on
% % plot(t,yBodyBlastWind,plotOptsBlastWindy)
% % plot(t,zBodyBlastWind,plotOptsBlastWindz)
% % grid on
% % xlabel('Time (s)')
% % ylabel('Wind Velocity (m/s)')
% % legend('Location','best')
% % savePlot('bodyBlastWind', figDir)
% %
% % % Motor blast wind velocities
% % figOpts.Position = [100, 50, 900, 1100];
% % bodyWinds = figure();
% % for ii = 1:4
% %     subplot(4,1,ii)
% %     ax = gca;
% %     ax.FontSize = fntSize;
% %     set(gcf,figOpts)
% %     plot(t,xMotorBlastWind(ii,:),plotOptsBlastWindx)
% %     hold on
% %     plot(t,yMotorBlastWind(ii,:),plotOptsBlastWindy)
% %     plot(t,zMotorBlastWind(ii,:),plotOptsBlastWindz)
% %     grid on
% %     ylabel('Wind Velocity (m/s)')
% % end
% % xlabel('Time (s)')
% % legend('Location','best')
% % savePlot('motorBlastWind', figDir)
% % if any([any(xMotorBlastWind>=0.01); any(yMotorBlastWind>=0.01); any(zMotorBlastWind>=0.01)],'all')
% %     error("The motor wind is nonzero")
% % end
% % if any([any(xBodyBlastWind>=0.01); any(yBodyBlastWind>=0.01); any(zBodyBlastWind>=0.01)])
% %     error("The body wind is nonzero")
% % end
% % Blast forces and moments
% % figOpts.Position = [100, 50, 1000, 900];
% blastForceMomentsFig = figure();
% subplot(3,2,1)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastFx,plotOptsBlastFx)
% grid on
% xlabel('Time (s)')
% ylabel('Forces (N)')
% % legend('Location','best')
% axis tight
% subplot(3,2,3)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastFy,plotOptsBlastFy)
% grid on
% xlabel('Time (s)')
% ylabel('Forces (N)')
% % legend('Location','best')
% axis tight
% subplot(3,2,5)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastFz,plotOptsBlastFz)
% grid on
% xlabel('Time (s)')
% ylabel('Forces (N)')
% % legend('Location','best')
% axis tight
% subplot(3,2,2)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastMx,plotOptsBlastMx)
% grid on
% xlabel('Time (s)')
% ylabel('Blast Moments (Nm)')
% % legend('Location','best')
% axis tight
% subplot(3,2,4)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastMy,plotOptsBlastMy)
% grid on
% xlabel('Time (s)')
% ylabel('Blast Moments (Nm)')
% % legend('Location','best')
% axis tight
% subplot(3,2,6)
% ax = gca;
% ax.FontSize = fntSize;
% set(gcf,figOpts)
% plot(t,blastMz,plotOptsBlastMz)
% grid on
% xlabel('Time (s)')
% ylabel('Blast Moments (Nm)')
% % legend('Location','best')
% axis tight
% 
% 
