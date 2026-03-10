function plot3dScatter(x, y, z, tf, fn, labels)
    fig = figure();
    scatter3(x(tf), y(tf), z(tf), "ro", "filled")
    hold on
    scatter3(x(~tf), y(~tf), z(~tf), "bo", "filled")
    grid on
    xlabel(labels(1))
    ylabel(labels(2))
    zlabel(labels(3))
    exportgraphics(fig, fn)
end