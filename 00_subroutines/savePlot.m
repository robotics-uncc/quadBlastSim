function savePlot(hdl, plotName, dirName, overwriteMeshCheck, overwritePDF)
% Function to save the plots as a pdf, or png if mesh elements exist
% Input:
%    hdl                = figure handle
%    plotName           = string for the name of the plot
%    dirName            = name of target save directory
%    overwriteMeshCheck = true/false to save mesh elements as pdfs
%    overwritePDF = true/false overwrite save as a png instead of a pdf

arguments
    hdl (1,1) handle {mustBeA(hdl, 'matlab.ui.Figure')}
    plotName (1,1) string % Updated to scalar string
    dirName (1,1) string  % Updated to scalar string
    overwriteMeshCheck (1,1) logical = false
    overwritePDF (1,1) logical = false
end

% Ensure the target directory exists, create it if it doesn't
if ~exist(dirName, 'dir')
    mkdir(dirName);
end

% Check the figure for mesh, surface, patch, or image elements
hasSurface = ~isempty(findall(hdl, 'Type', 'surface'));
hasPatch   = ~isempty(findall(hdl, 'Type', 'patch'));
hasImage   = ~isempty(findall(hdl, 'Type', 'image'));

% Route the export format based on the figure contents
% FIX: Use && so it only triggers PNG if complex elements exist AND we aren't overriding
if (hasSurface || hasPatch || hasImage) && ~overwriteMeshCheck || overwritePDF
    % Save as a high-resolution PNG for raster-heavy figures
    savePath = fullfile(dirName, plotName + ".png"); % FIX: String concatenation
    exportgraphics(hdl, savePath, 'Resolution', 600);
    fprintf('Saved as PNG (mesh elements detected): %s\n', savePath);
else
    % Save as a vector PDF for standard line/scatter plots
    savePath = fullfile(dirName, plotName + ".pdf"); % FIX: String concatenation
    exportgraphics(hdl, savePath, 'ContentType', 'vector');
    fprintf('Saved as PDF: %s\n', savePath);
end

end