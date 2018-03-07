function cP = centerPoints(squares)
% returns the center location of each square (format of nSquaresx8)
cP = [mean(squares(:,1:2:end),2),mean(squares(:,2:2:end),2)];
end