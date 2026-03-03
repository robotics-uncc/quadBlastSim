clc;clf;clear all;close all;

% Import the data
data         = readtable("dataExportTab1.csv");
testNum      = data{:,2};
charge       = data{:,3};
distance     = data{:,4};
peakPressure = data{:,5};
peakImpulse  = data{:,6};
fnf          = data{:,7};
condition    = strcmp(fnf,"Fail");

% Make a figure directory
figDir = "table1Visualization/";
mkdir(figDir)

% Conversions
lb2kg = 0.453592;
ft2m = 0.3048;
psi2pa = 6894.76;

% Imperial to SI units
charge = charge * lb2kg;                   % lb → kg
distance = distance * ft2m;                % ft → m
peakPressure = peakPressure * psi2pa;      % psi → Pa
peakImpulse = peakImpulse * psi2pa * 1e-3; % psi·ms → Pa·s

% Functions for plotting
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

function plotMeshgrid(x, y, z, tf, fn, labels)
    [Xq, Yq] = meshgrid(linspace(min(x), max(x), 100), ...
                    linspace(min(y), max(y), 100));
    Zq = griddata(x, y, z, Xq, Yq, "natural");
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

% Make some plots
plot3dScatter(charge, peakPressure, peakImpulse, condition, ...
    append(figDir, "chargeVsPeakpressureVsPeakImpulse-scatter3.png"), ...
    ["Charge (kg c4)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
plot3dScatter(distance, peakPressure, peakImpulse, condition, ...
    append(figDir, "distanceVsPeakpressureVsPeakImpulse-scatter3.png"), ...
    ["Distance from UAV (m)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
plotMeshgrid(charge, distance, peakPressure, condition, ...
    append(figDir, "chargeVsDistanceVsPeakpressure.png"), ...
    ["Charge (kg c4)", "Distance from UAV (m)", "Peak Pressure (Pa)"])
plotMeshgrid(charge, distance, peakImpulse, condition, ...
    append(figDir, "chargeVsDistanceVsPeakimpulse.png"), ...
    ["Charge (kg c4)", "Distance from UAV (m)", "Peak Impulse (Pa-s)"])
plotMeshgrid(charge, peakPressure, peakImpulse, condition, ...
    append(figDir, "chargeVsPeakpressureVsPeakImpulse.png"), ...
    ["Charge (kg c4)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
plotMeshgrid(distance, peakPressure, peakImpulse, condition, ...
    append(figDir, "distanceVsPeakpressureVsPeakImpulse.png"), ...
    ["Distance (m)", "Peak Pressure (Pa)", "Peak Impulse (Pa-s)"])
