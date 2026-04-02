clc;clf;clear all;close all;

% Get the names of the cleaned txt files
files = dir('*.txt');
fileNames = {files.name};

% Iterate through the txt files
for i = 1:length(fileNames)
    % Get the data from the files
    T = readtable(fileNames{i});

    % Make a directory to hold the plots for this file
    figDir = fileNames{i}(1:end-4);
    mkdir(figDir);

    % Separate the headers and time variable
    headers = T.Properties.VariableNames;
    time = T.Time;
    for j = 1:length(headers)
        % Plot the data and save it in the directory
        plot(time, T{:, j}); % Plot the current variable against time
        xlabel('Time');
        ylabel(headers{j});
        title(['Plot of ', headers{j}, ' from ', fileNames{i}]);
        saveas(gcf, fullfile(figDir, [headers{j}, '.png'])); % Save the plot
    end
    clf
end