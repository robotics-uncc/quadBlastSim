function formatMDPIFigure(fig, sizeType)
% formatMDPIFigure Formats a MATLAB figure to meet MDPI journal standards.
%
% This function standardizes the dimensions, fonts, line widths, and general 
% aesthetics of a specified figure to comply with typical MDPI publication 
% requirements. It applies a 9pt Times New Roman font, 1.4pt data lines, 
% and 1.0pt axes boxes across all subplots and colorbars in the figure.
%
% Syntax:
%   formatMDPIFigure(fig)
%   formatMDPIFigure(fig, sizeType)
%
% Inputs:
%   fig      - Handle to the figure to be formatted (e.g., gcf or fig1).
%   sizeType - (Optional) String specifying the target figure width/height 
%              preset. All sizes use a 9pt font. Options include:
%                * 'full'   : (Default) 16.0 cm x 9.5 cm (Spans full page width)
%                * 'shorter': 16.0 cm x 7.0 cm (Full width, shorter height)
%                * 'half'   : 7.5 cm x 5.0 cm (For side-by-side sub-figures)
%                * 'third'  : 5.2 cm x 4.5 cm (For three-across sub-figures)
%                * 'twothirds'  : 10.5 cm x 6.3 cm (For three-across sub-figures)
%
% Example:
%   fig = figure;
%   plot(x, y);
%   formatMDPIFigure(fig, 'half');
%
% Notes:
%   - To ensure text like titles and legends render with matching LaTeX 
%     fonts, it is recommended to also set global LaTeX interpreters in 
%     your main script before calling this function.
    if nargin < 2; sizeType = 'full'; end
    fontName = 'Times New Roman'; 
    
    if strcmpi(sizeType, 'half')
        figWidth = 7.5;   
        figHeight = 5.0; 
        fontSize = 9; 
    elseif strcmpi(sizeType, 'third')
        figWidth = 5.2;   
        figHeight = 4.5; 
        fontSize = 9;
    elseif strcmpi(sizeType, 'shorter')
        figWidth = 16.0; 
        figHeight = 7.0;
        fontSize = 9; 
    elseif strcmpi(sizeType, 'twothirds')
        figWidth = 10.5; 
        figHeight = 6.3;
        fontSize = 9; 
    else
        figWidth = 16.0; 
        figHeight = 9.5;
        fontSize = 9;  
    end

    fig.Color = 'w'; 
    fig.Units = 'centimeters';
    fig.Position(3:4) = [figWidth, figHeight]; 

    allAxes = findall(fig, 'type', 'axes');
    for i = 1:length(allAxes)
        ax = allAxes(i);
        ax.FontName = fontName;
        ax.FontSize = fontSize;
        ax.Box = 'on';           
        ax.LineWidth = 1.0;      
        ax.TickDir = 'in';       
        ax.XColor = 'k';         
        ax.YColor = 'k';
        
        if ~isempty(ax.Title.String)
            ax.Title.FontWeight = 'normal';
            ax.Title.FontName = fontName;
            ax.Title.FontSize = fontSize;
        end
    end

    allLines = findall(fig, 'type', 'line');
    for i = 1:length(allLines)
        allLines(i).LineWidth = 1.4; % <--- ONLY thickens the data lines inside the plot
    end

    allCBs = findall(fig, 'type', 'colorbar');
    for i = 1:length(allCBs)
        cb = allCBs(i);
        cb.FontName = fontName;
        cb.FontSize = fontSize;
        cb.LineWidth = 1.0;
        cb.Color = 'k';
    end
end