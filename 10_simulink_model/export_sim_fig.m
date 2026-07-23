% exportSimulinkModel.m
% Captures the active Simulink model and exports it as an EPS file 
% to guarantee a perfectly tight bounding box with zero white margins.
clear; clc;

% 1. Get the name of the currently active Simulink system
sys = gcs; 

if isempty(sys)
    error('No Simulink model is currently open or active.');
end


% Change extension to .eps
outputFilename = fullfile([sys, '_model.svg']);

% 2. Force Simulink to zoom tightly to the blocks
set_param(sys, 'ZoomFactor', 'FitSystem');

% Ensure the background is pure white
set_param(sys, 'ScreenColor', 'white');

% 3. Print directly to an SVG file (-dsvg)
print(['-s' sys], '-dsvg', outputFilename);

disp(['Successfully exported zero-margin Simulink model to: ', outputFilename]);