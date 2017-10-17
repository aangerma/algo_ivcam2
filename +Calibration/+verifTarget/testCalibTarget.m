clean

chosenSet = 5;





% % % if(chosenSet == 1)
% % %     dirp = 'C:\Users\ychechik\Desktop\calibImages';
% % %     isflipud = [1 1 1 1 1 1 1 1 1 1 1 1];
% % %     isfliplr = [1 0 0 0 0 1 1 1 1 1 1 1];
% % % elseif(chosenSet == 2)
% % %     dirp = 'C:\Users\ychechik\Desktop\calibImages\my';
% % % elseif(chosenSet == 3)
% % %     dirp = 'C:\Users\ychechik\Desktop\calibImages\new';
if(chosenSet == 4)
    dirp = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\verifTargetImages\new105';
elseif(chosenSet == 5)
    dirp = '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\verifTargetImages\new105POC';
        isflipud = [0 0];
    isfliplr = [1 1];
end


d = dir(dirp);
isdir = {d.isdir};
d = {d.name};
d(cell2mat(isdir)) = [];

f = figure('name','calibration target results');

for i = 1:length(d)
    
    p = fullfile(dirp,d{i});
    I = imread(p);
    if(exist('isflipud','var'))
        if(isflipud(i))
            I = flipud(I);
        end
        if(isfliplr(i))
            I = fliplr(I);
        end
    end
    
    if(length(size(I)) == 3)
        I = rgb2gray(I);
    end
    
    Calibration.verifTarget.irMetrics(I,[],f);
end