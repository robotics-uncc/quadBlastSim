%% ========================= Figure 1: MDPI single-column layout =========================
% Rows = {Pressure, Velocity}
% Cols = {Non-propagated, Propagated, BlastFoam}

% Convert model outputs to plotting units
pressureNP_kPa = 0.001 * pressureNP;
pressureP_kPa  = 0.001 * pressureP;
velocityNP_ms  = mach2ms * velocityNP;
velocityP_ms   = mach2ms * velocityP;

xLimits = [x0 xf];
yLimits = [blastTimesCrop(1) tf];

% Shared color limits across each row
pMin = 0;
pMax = 1e4;

vMin = min([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);
vMax = max([velocityNP_ms(:); velocityP_ms(:); blastVelocity_ms(:)]);

% MDPI-like single-column figure size
fig1 = figure(1);
set(fig1, 'Color', 'w', 'Units', 'inches', 'Position', [1, 1, 3.35, 4.6]);

t = tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
colormap(fig1, "turbo")

fntSz = 8;   % labels/titles/colorbar labels
tckSz = 7;   % tick labels
fontSizes.fntSz = fntSz;
fontSizes.tckSz = tckSz;

% ---------------- Pressure row ----------------
ax1 = nexttile(1);
plotMeshPanelNoCB(ax1, Xnp, Tnp, pressureNP_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('Non-propagated Pressure','FontSize',fntSz)
ylabel('Time (s)','FontSize',fntSz)

ax2 = nexttile(2);
plotMeshPanelNoCB(ax2, Xp, Tp, pressureP_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('Propagated Pressure','FontSize',fntSz)

ax3 = nexttile(3);
plotMeshPanelNoCB(ax3, Xbf, Tbf, blastPressure_kPa, [pMin pMax], xLimits, yLimits, fontSizes);
title('BlastFoam Pressure','FontSize',fntSz)

% Shared pressure colorbar
cb1 = colorbar(ax3, 'eastoutside');
cb1.Layout.Tile = 'east';
cb1.Label.String = 'Pressure (kPa)';
cb1.Label.FontSize = fntSz;
cb1.FontSize = tckSz;
cb1.Ruler.Exponent = 0;

% ---------------- Velocity row ----------------
ax4 = nexttile(4);
plotMeshPanelNoCB(ax4, Xnp, Tnp, velocityNP_ms, [vMin vMax], xLimits, yLimits, fontSizes);
title('Non-propagated Velocity','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)
ylabel('Time (s)','FontSize',fntSz)

ax5 = nexttile(5);
plotMeshPanelNoCB(ax5, Xp, Tp, velocityP_ms, [vMin vMax], xLimits, yLimits, fontSizes);
title('Propagated Velocity','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)

ax6 = nexttile(6);
plotMeshPanelNoCB(ax6, Xbf, Tbf, blastVelocity_ms, [vMin vMax], xLimits, yLimits, fontSizes);
title('BlastFoam Velocity','FontSize',fntSz)
xlabel('Distance (m)','FontSize',fntSz)

% Shared velocity colorbar
cb2 = colorbar(ax6, 'eastoutside');
cb2.Layout.Tile = 'east';
cb2.Label.String = 'Velocity (m/s)';
cb2.Label.FontSize = fntSz;
cb2.FontSize = tckSz;
cb2.Ruler.Exponent = 0;

savePlot('updatedModelMesh_mdpi_singlecol', '.')

function plotMeshPanelNoCB(ax, X, T, Z, climVals, xLimits, yLimits, fontSizes)
    axes(ax);
    pcolor(X, T, Z)
    shading interp
    axis square
    grid off

    fntSz = fontSizes.fntSz;
    tckSz = fontSizes.tckSz;

    xlim(xLimits)
    ylim(yLimits)

    xticks(linspace(xLimits(1), xLimits(2), 5))
    yticks(linspace(yLimits(1), yLimits(2), 5))

    xtickformat('%.2f')
    ytickformat('%.3f')

    ax.FontSize = tckSz;
    ax.XAxis.Exponent = 0;
    ax.YAxis.Exponent = 0;

    if ~isempty(climVals)
        clim(ax, climVals)
    end
end