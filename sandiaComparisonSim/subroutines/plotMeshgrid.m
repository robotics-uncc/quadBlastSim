function plotMeshgrid(Xq, Yq, Zq, fn, labels)
    fig = figure();
    pcolor(Xq,Yq,Zq)
    colormap("cool")
    hold on
    scatter(x(tf), y(tf), "ro", "filled")
    scatter(x(~tf), y(~tf), "bo", "filled")
    shading interp
    cb = colorbar;
    xlabel(labels(1))
    ylabel(labels(2))
    cb.Label.String = labels(3);
    exportgraphics(fig, fn)
end