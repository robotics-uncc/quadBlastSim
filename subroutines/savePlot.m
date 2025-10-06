function savePlot(plotName, dirName)
% Function to save the plots as a pdf
% Input:
%    plotName = string for the name of the plot
%    dirName = name of target save directory

% Save the plot as a pdf with the appropriate fonts and size
set(gcf,'Color','w');
set(gcf,'Units','inches');
screenposition = get(gcf,'Position');
set(gcf,...
    'PaperPosition',[0 0 screenposition(3:4)],...
    'PaperSize',[screenposition(3:4)]);
saveas(gcf,append(dirName,'/',plotName,'.svg'))
% saveas(gcf,append(dirName,'/',plotName,'.pdf'))
% saveas(gcf,[dirName '/' plotName '.pdf'])

end