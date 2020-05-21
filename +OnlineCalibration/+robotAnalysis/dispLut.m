function dispLut(mat,hvals,vvals)
    imagesc(abs(mat));
    colormap jet;
    textStrings = num2str(mat(:), '%0.3f');       % Create strings from the matrix values
    textStrings = strtrim(cellstr(textStrings));  % Remove any space padding
    [x, y] = meshgrid(1:size(mat,1),1:size(mat,2));  % Create x and y coordinates for the strings
    hStrings = text(x(:), y(:), textStrings(:), ...  % Plot the strings
        'HorizontalAlignment', 'center');
    [~,minInd] = min(abs(mat(:)));
    
    textColors = zeros(length(hStrings),3);
    textColors(minInd,:) = [1,0 ,0];% Choose white or black for the
    %   text color of the strings so
    %   they can be easily seen over
    %   the background color
    set(hStrings, {'Color'}, num2cell(textColors, 2));  % Change the text colors
    
    set(gca, 'XTick', 1:length(hvals), ...                             % Change the axes tick marks
        'XTickLabel', cellstr(num2str(hvals(:), '%0.3f'))', ...  %   and tick labels
        'YTick', 1:length(vvals), ...
        'YTickLabel', cellstr(num2str(vvals(:), '%0.3f'))', ...
        'TickLength', [0 0]);
    xlabel('H-factor');
    ylabel('V-factor');
    
end