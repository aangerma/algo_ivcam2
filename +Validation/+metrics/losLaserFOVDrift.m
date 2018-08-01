function [score, results] = losGridDrift(frames, params)

% frames should be captured with spherical enable mode
% frames 1xN struct array with fields: z, i, c
%   - z, i, c images e.g. 480x640
% params : defined as in aux.defaultMetricsParams

zMaxSubMM = 8;

imgSize = size(frames(1).z);

if ~exist('params','var')
    params = Validation.aux.defaultMetricsParams();
end

ir = double(frames(1).i);



nestEstColumn = 2;

n = length(frames);

yRange = 240-40:240+40;
xRange = 320-40:320+40;


%% find grid points for all the images
for i = 1:n
    ir = frames(i).i;
    vSum = sum(ir, 1);
    if (vSum(1) ~= 0)
        warning('All the pixels of the first column of IR image should be 0');
        score = nan; results.error = true;
        return;
    end
    
    iColFirstNest = find(vSum ~= 0, 1);

    nestFirstCol = ir(:,iColFirstNest);
    nestFirstCol = nestFirstCol(nestFirstCol ~= 0);

    irFilled = ir;
    iColEmpty = find(vSum == 0);
    irFilled(:,iColEmpty) = nestFirstCol(1);
    iColNest = arrayfun(@(x) find(irFilled(:,x)~=0,1,'last'), 1:imgSize(2));
    colNest = irFilled(sub2ind(imgSize, iColNest, 1:imgSize(2)));
    nestImg = repmat(colNest, imgSize(1), 1);
    
    nestMin = nestImg - 4;
    nestMax = nestImg + 4;
    
    nestMask = and(ir >= nestMin, ir <= nestMax);

    dx = diff(double(nestMask),1,1);
    dy = diff(double(nestMask),1,2);
    
    if (params.verbose)
        fig = figure(17); imagesc(nestMask);
        title(sprintf('nest mask for frame %g', i));
    end
    
    FovL(i) = mean(arrayfun(@(y) find(dy(y,:)>0,1), yRange));
    FovR(i) = mean(arrayfun(@(y) find(dy(y,:)<0,1,'last'), yRange));

    LdOnL(i) = mean(arrayfun(@(y) find(dy(y,:)<0,1), yRange));
    LdOnR(i) = mean(arrayfun(@(y) find(dy(y,:)>0,1,'last'), yRange));
    
    FovT(i) = mean(arrayfun(@(x) find(dx(:,x)>0,1), xRange));
    FovB(i) = mean(arrayfun(@(x) find(dx(:,x)<0,1,'last'), xRange));

    LdOnT(i) = mean(arrayfun(@(x) find(dx(:,x)<0,1), xRange));
    LdOnB(i) = mean(arrayfun(@(x) find(dx(:,x)>0,1,'last'), xRange));
end

if (params.verbose)
    close(fig);
end

%% estimate results

results.meanFovL = mean(FovL);
results.meanFovR = mean(FovR);
results.meanFovT = mean(FovT);
results.meanFovB = mean(FovB);
results.meanLdOnL = mean(LdOnL);
results.meanLdOnR = mean(LdOnR);
results.meanLdOnT = mean(LdOnT);
results.meanLdOnB = mean(LdOnB);

results.stdFovL = std(FovL);
results.stdFovR = std(FovR);
results.stdFovT = std(FovT);
results.stdFovB = std(FovB);
results.stdLdOnL = std(LdOnL);
results.stdLdOnR = std(LdOnR);
results.stdLdOnT = std(LdOnT);
results.stdLdOnB = std(LdOnB);

p = polyfit(1:n, FovL, 1);
results.driftFovL = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, FovR, 1);
results.driftFovR = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, FovT, 1);
results.driftFovT = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, FovB, 1);
results.driftFovB = polyval(p, n) - polyval(p, 1);

p = polyfit(1:n, LdOnL, 1);
results.driftLdOnL = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, LdOnR, 1);
results.driftLdOnR = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, LdOnT, 1);
results.driftLdOnT = polyval(p, n) - polyval(p, 1);
p = polyfit(1:n, LdOnB, 1);
results.driftLdOnB = polyval(p, n) - polyval(p, 1);

if (params.verbose)
    figure; imagesc(frames(1).i); hold on;
    line([FovL(1) FovL(1)], [1 imgSize(1)], 'Color','white');
    line([FovR(1) FovR(1)], [1 imgSize(1)], 'Color','white');
    line([1 imgSize(2)], [FovT(1) FovT(1)], 'Color','white');
    line([1 imgSize(2)], [FovB(1) FovB(1)], 'Color','white');
    line([LdOnL(1) LdOnL(1)], [1 imgSize(1)], 'Color','red');
    line([LdOnR(1) LdOnR(1)], [1 imgSize(1)], 'Color','red');
    line([1 imgSize(2)], [LdOnT(1) LdOnT(1)], 'Color','red');
    line([1 imgSize(2)], [LdOnB(1) LdOnB(1)], 'Color','red');
end


results.maxDrift = max([abs(results.stdFovL), abs(results.stdFovR),abs(results.stdFovT),abs(results.stdFovB)]);
results.stability = min(1/max(eps, results.maxDrift),1000);

score = results.stability;
results.score = 'stability';
results.units = '1/pixels';
results.error = false;

end

