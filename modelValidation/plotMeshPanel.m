function plotMeshPanel(ax, X, T, Z, climVals, xLimits, yLimits, fontSizes)
    axes(ax);
    pcolor(X, T, Z)
    shading interp
    axis normal
    grid off
    box on

    tckSz = fontSizes.tckSz;

    xlim(xLimits)
    ylim(yLimits)

    xticks(linspace(xLimits(1), xLimits(2), 5))
    yticks(linspace(yLimits(1), yLimits(2), 5))

    xtickformat('%.2f')
    ytickformat('%.2f')

    ax.FontSize = tckSz;
    ax.XAxis.Exponent = 0;
    ax.YAxis.Exponent = 0;
    ax.TitleHorizontalAlignment = 'center';
    ax.XTickLabelRotation = 0;

    if ~isempty(climVals)
        clim(ax, climVals)
    end
end