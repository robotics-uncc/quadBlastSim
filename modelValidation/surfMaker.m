clf

% Create surface plots for pressure and velocity
figure(1);
set(gcf,'color','w')
subplot(1, 2, 1);
grid off
h = pcolor(X, T, pressure);
set(h, 'EdgeColor', 'none');
shading interp; 
xlabel('Distance (m)');
ylabel('Time (s)');
cb = colorbar();
cb.Label.String = 'Pressure (Pa)';
axis square
set(gca,'ColorScale','log')

subplot(1, 2, 2);
grid off
h = pcolor(X, T, velocity);
set(h, 'EdgeColor', 'none');
shading interp; 
xlabel('Distance (m)');
ylabel('Time (s)');
cb = colorbar();
cb.Label.String = 'Velocity (m/s)';
axis square
set(gca,'ColorScale','log')
savePlot('modelMeshgrid.pdf',figDir)