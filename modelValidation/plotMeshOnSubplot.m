function cb = plotMeshOnSubplot(axH, X, Y, Z)
grid off
h = pcolor(axH, X, Y, Z);
set(h, 'EdgeColor', 'none');
shading interp; 
% xlabel('Distance (m)');
% ylabel('Time (s)');
cb = colorbar();
% cb.Label.String = 'Velocity (m/s)';
axis square
% set(gca,'ColorScale','log')
% savePlot('modelMeshgrid.pdf',figDir)
end