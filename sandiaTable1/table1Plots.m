clc; clf; clearvars; close all;

% Import the data
data         = readtable("dataExportTab1.csv");
testNum      = data{:,2};
charge_lb    = data{:,3};
distance_ft  = data{:,4};
pPeak_psi    = data{:,5};
Ipeak_psims  = data{:,6};
fnf          = data{:,7};
condition    = strcmp(fnf,"Fail");

% Make a figure directory (quietly)
figDir = "table1Visualization/";
if ~exist(figDir, "dir"), mkdir(figDir); end

% Conversions (exact/standard)
lb2kg  = 0.45359237;
ft2m   = 0.3048;
psi2kPa = 6.89476;
c42tnt = 1/1.34; % https://en.wikipedia.org/wiki/TNT_equivalent

% Imperial -> SI
charge       = charge_lb   * lb2kg * c42tnt;           % lb -> kg -> c4 eqivalent
distance     = distance_ft * ft2m;            % ft -> m
peakPressure = pPeak_psi   * psi2kPa;          % psi -> kPa
peakImpulse  = Ipeak_psims * psi2kPa * 1e-3;   % psi·ms -> kPa·s

% Functions for plotting
function plot3dScatter(x, y, z, tf, fn, labels)
    fig = figure();
    scatter3(x(tf),  y(tf),  z(tf),  "ro", "filled"); hold on
    scatter3(x(~tf), y(~tf), z(~tf), "bo", "filled");
    grid on
    xlabel(labels(1)); ylabel(labels(2)); zlabel(labels(3));
    exportgraphics(fig, fn);
end

function plotMeshgrid(x, y, z, tf, fn, labels)
    [Xq, Yq] = meshgrid(linspace(min(x), max(x), 100), ...
                        linspace(min(y), max(y), 100));
    Zq = griddata(x, y, z, Xq, Yq, "natural");

    fig = figure();
    pcolor(Xq, Yq, Zq);
    colormap("cool")
    shading interp
    hold on
    scatter(x(tf),  y(tf),  "ro", "filled");
    scatter(x(~tf), y(~tf), "bo", "filled");
    grid on

    cb = colorbar;
    xlabel(labels(1)); ylabel(labels(2));
    cb.Label.String = labels(3);
    exportgraphics(fig, fn);
end

% Plots (SI labels)
plot3dScatter(charge, peakPressure, peakImpulse, condition, ...
    figDir + "charge_vs_pPeak_vs_Ipeak_scatter3.png", ...
    ["Charge (kg c4)", "Peak Pressure (kPa)", "Peak Impulse (kPa·s)"]);

plot3dScatter(distance, peakPressure, peakImpulse, condition, ...
    figDir + "distance_vs_pPeak_vs_Ipeak_scatter3.png", ...
    ["Distance (m)", "Peak Pressure (kPa)", "Peak Impulse (kPa·s)"]);

plotMeshgrid(charge, distance, peakPressure, condition, ...
    figDir + "charge_vs_distance_vs_pPeak.png", ...
    ["Charge (kg c4)", "Distance (m)", "Peak Pressure (kPa)"]);

plotMeshgrid(charge, distance, peakImpulse, condition, ...
    figDir + "charge_vs_distance_vs_Ipeak.png", ...
    ["Charge (kg c4)", "Distance (m)", "Peak Impulse (kPa·s)"]);

plotMeshgrid(charge, peakPressure, peakImpulse, condition, ...
    figDir + "charge_vs_pPeak_vs_Ipeak.png", ...
    ["Charge (kg c4)", "Peak Pressure (kPa)", "Peak Impulse (kPa·s)"]);

plotMeshgrid(distance, peakPressure, peakImpulse, condition, ...
    figDir + "distance_vs_pPeak_vs_Ipeak.png", ...
    ["Distance (m)", "Peak Pressure (kPa)", "Peak Impulse (kPa·s)"]);