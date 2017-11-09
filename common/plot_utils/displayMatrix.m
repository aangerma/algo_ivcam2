function h = displayMatrix(mat,minc,maxc)
    
    if exist('maxc','var')
        imagescNAN(mat,'nancolor',[0.3 0 0],[minc maxc]);
    else
        imagescNAN(mat,'nancolor',[0.3 0 0]);
    end
    colormap(flipud(gray));  %# Change the colormap to gray (so higher values are
    [w,h] = size(mat);
    textStrings = num2str(mat(:),'%0.2f');  %# Create strings from the matrix values
    textStrings = strtrim(cellstr(textStrings));  %# Remove any space padding
    [x,y] = meshgrid(1:w,1:h);   %# Create x and y coordinates for the strings
    hStrings = text(x(:),y(:),textStrings(:),...      %# Plot the strings
        'HorizontalAlignment','center');
    midValue = mean(get(gca,'CLim'));  %# Get the middle value of the color range
    textColors = repmat(mat(:) > midValue,1,3);  %# Choose white or black for the
    %#   text color of the strings so
    %#   they can be easily seen over
    %#   the background color
    textColors = double(textColors);
    textColors(isnan(mat(:)),:) =  bsxfun(@plus,textColors(isnan(mat(:)),:),[1 0.3 0.3]);
    set(hStrings,{'Color'},num2cell(textColors,2));  %# Change the text colors
    
    
    set(gca,'XTick',1:w,...                         %# Change the axes tick marks
        'YTick',1:h,...
        'TickLength',[0 0]);
    
    % set(gca,'XTick',1:w,...                         %# Change the axes tick marks
    %         'XTickLabel',{'A','B','C','D','E'},...  %#   and tick labels
    %         'YTick',1:h,...
    %         'YTickLabel',{'A','B','C','D','E'},...
    %         'TickLength',[0 0]);
    
end