function [rtdFromWhite,ptsFromWhite1,ptsFromWhite2] = valuesFromWhites(rtd,pts,colorMap,r)
%VALUESFROMWHITES Summary of this function goes here
%   Detailed explanation goes here

slimPts = Calibration.aux.CBTools.slimNans(pts);
slimColors = Calibration.aux.CBTools.slimNans(colorMap);

ptsFromWhite1 = nan([size(slimColors),2]);
ptsFromWhite2 = nan([size(slimColors),2]);

nrows = size(slimColors,1);
ncols = size(slimColors,2);
for i = 1:nrows
    for j = 1:ncols
        if slimColors(i,j) % Top left and botom right 
            
            if i == 1 && j == 1% Top Left
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j+1,:);
            elseif i == nrows && j == 1% Bottom Left
                v = slimPts(i-1,j,:) - slimPts(i,j+1,:);
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + v;
                ptsFromWhite2(i,j,:) = slimPts(i,j,:) - v;
            elseif i == 1 && j == ncols% Top Right
                v = slimPts(i,j-1,:) - slimPts(i+1,j,:);
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + v;
                ptsFromWhite2(i,j,:) = slimPts(i,j,:) - v;
            elseif i == nrows && j == ncols% Bottom Right
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j-1,:);
            elseif i == 1 % First Row
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j+1,:);
            elseif i == nrows % Last Row
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j-1,:);
            elseif j == 1 % First Col
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j+1,:);
            elseif j == ncols % Last Col    
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j-1,:);
            else
                ptsFromWhite1(i,j,:) = slimPts(i-1,j-1,:);
                ptsFromWhite2(i,j,:) = slimPts(i+1,j+1,:);
            end
      
        else
            
            if i == 1 && j == 1% Top Left
                v = slimPts(i+1,j,:) - slimPts(i,j+1,:);
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + v;
                ptsFromWhite2(i,j,:) = slimPts(i,j,:) - v;
            elseif i == nrows && j == 1% Bottom Left
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j+1,:);
            elseif i == 1 && j == ncols% Top Right
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j-1,:);
            elseif i == nrows && j == ncols% Bottom Right
                v = slimPts(i,j-1,:) - slimPts(i-1,j,:);
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + v;
                ptsFromWhite2(i,j,:) = slimPts(i,j,:) - v;
            elseif i == 1 % First Row
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j-1,:);
            elseif i == nrows % Last Row
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j+1,:);
            elseif j == 1 % First Col
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i-1,j+1,:));
                ptsFromWhite2(i,j,:) = slimPts(i-1,j+1,:);
            elseif j == ncols % Last Col    
                ptsFromWhite1(i,j,:) = slimPts(i,j,:) + (slimPts(i,j,:) - slimPts(i+1,j-1,:));
                ptsFromWhite2(i,j,:) = slimPts(i+1,j-1,:);
            else
                ptsFromWhite1(i,j,:) = slimPts(i-1,j+1,:);
                ptsFromWhite2(i,j,:) = slimPts(i+1,j-1,:);
            end
            
        end
    end
end
ptsFromWhite1 = r*(ptsFromWhite1-slimPts) + slimPts;
ptsFromWhite2 = r*(ptsFromWhite2-slimPts) + slimPts;
ptsFromWhite1 = reshape(ptsFromWhite1,[],2);
ptsFromWhite2 = reshape(ptsFromWhite2,[],2);

rtdFromWhite = interp2(rtd,ptsFromWhite1(:,1),ptsFromWhite1(:,2))*0.5 + interp2(rtd,ptsFromWhite2(:,1),ptsFromWhite2(:,2))*0.5;
% plot(pts(:,:,1),pts(:,:,2),'r*')
% hold on 
% plot(ptsFromWhite1(:,:,1),ptsFromWhite1(:,:,2),'g*')
% plot(ptsFromWhite2(:,:,1),ptsFromWhite2(:,:,2),'b*')
end
