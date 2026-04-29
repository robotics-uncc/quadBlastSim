function savePlott(plotName, dirName)
% Function to save the plots as a pdf
% Input:
%    plotName = string for the name of the plot
%    dirName = name of target save directory

set(gcf,'Color','w');
set(gcf,'Units','inches');

% Make sure output folder exists
if ~exist(dirName,'dir')
    mkdir(dirName);
end

outFile = fullfile(dirName, plotName + ".pdf");

% exportgraphics is generally more reliable for tiledlayout/colorbars
exportgraphics(gcf, outFile, 'ContentType', 'vector', 'BackgroundColor', 'white');

outFile = fullfile(dirName, plotName + ".png");
exportgraphics(gcf, outFile, 'ContentType', 'vector', 'BackgroundColor', 'white');
end