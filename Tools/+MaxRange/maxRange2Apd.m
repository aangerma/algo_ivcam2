%% definitions and initializations

%other definitions
distances = 2300;% distances to go over in mm
manualTargeting = true; %automatically detects the target
storeResPath = '';%where to store results

plotsToShow = {'fill Rate With Std Below 30','fill Rate With Diff From Med Below 30',...
    'Ir Masked Mean','Max Peak Masked Mean','Conf Masked Mean','Duty Cycle Masked Mean'};

%register to sweep using the tool
regToSweep = 'EXTLvAPD';
sweepVals = [0 360:2:380];
%default valuye as a baseline
sweepDefaultVal = hex2dec('1400');
%this is how we update the value:
regUpdateFunction = @(x)(uint32(hex2dec([dec2hex(x) '1'])));

num_of_frames_per_dist = 100;
allRes = [];

%% init hw
if ~exist('hw','var')
    hw = HWinterface();
    hw.getFrame(10);%need to start streaming
    pause(5);
end

% configure hw
r=Calibration.RegState(hw);
r.add('JFILinvBypass',true);
r.set();
pause(0.1);

% metrics parameters
params = Validation.aux.defaultMetricsParams();
params.detectDarkRect = false;
params.stdTh = [30,70];
params.diffFromMeanTh = [30,70];
params.diffFromMedTh = [30,70];
params.camera.zMaxSubMM = 2^double(hw.read('GNRLzMaxSubMMExp'));


%% capture and label target
alignFrame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],sprintf('move camera to distance %d mm',distances(1)));
figure(1);
imagesc(alignFrame.i)
maximizeFig(1);
rect_coords = [];
if manualTargeting
    title('Mark Target');
    roi = ginput(4);
    msk = double(poly2mask(roi(:,1),roi(:,2),size(alignFrame.i,1),size(alignFrame.i,2)));
    %h = drawpolygon;
    %rect_coords = h.get.Position;
    %msk = double(poly2mask(h.Position(:,1), h.Position(:,2),size(alignFrame.i,1),size(alignFrame.i,2)));
else
    params.detectDarkRect = true;
    msk = Validation.aux.updateMaskWithRect(params, alignFrame.i, ones(size(alignFrame.i)));
    params.detectDarkRect = false;
end
imshowpair(alignFrame.i,msk)
sMsk = sum(msk(:));
roiSize = sqrt(sMsk);
avgOverMask = @(x)(nansum_(double(x(:)).*msk(:))./sMsk);
params.BWMask = msk;

%% main loop
for ridx=1:length(sweepVals)
    
    %set apd register
    curVal = sweepVals(ridx);
    fprintf_r(sprintf('Changing %s to %d',regToSweep,curVal),[]);
    
    if sweepVals(ridx) > 0
        regVal = regUpdateFunction(curVal);
    else
        regVal = sweepDefaultVal;
    end
    hw.setReg(regToSweep,regVal);
    pause(0.1);
    hw.getFrame(10); %clear buffer;
        
    % set capture mode to default confidence and IR
    hw.setReg('DESTaltIrEn',0);
    hw.setConfidenceAs();
    pause(0.1);
    frames = hw.getFrame(num_of_frames_per_dist,false);
    [~, results] = Validation.metrics.maxRange( frames, params );
        
    % set capture mode to duty cycle confidence and alternate IR (max peak)
    hw.setReg('DESTaltIrEn',1);
    hw.setConfidenceAs('dc');
    pause(0.1);
    frames = hw.getFrame(num_of_frames_per_dist,false);
    [~, resultsAltIrDc] = Validation.metrics.maxRange( frames, params ); 
    
    mergedRes = struct();
    mergedRes.(regToSweep) = regVal;
    fields = fieldnames(results);
    ifieldsToSplit = {'iMaskedMean','iMaskedStd'};
    dcfieldsToSplit = {'cMaskedMean','cMaskedStd'};
    for fid = 1:length(fields)
        if contains(fields{fid},ifieldsToSplit)
            newFieldPostfix = fields{fid}(2:end);
            mergedRes.(['Ir' newFieldPostfix]) = results.(fields{fid});
            mergedRes.(['MaxPeak' newFieldPostfix]) = resultsAltIrDc.(fields{fid});            
        elseif contains(fields{fid},dcfieldsToSplit)
            newFieldPostfix = fields{fid}(2:end);
            mergedRes.(['Conf' newFieldPostfix]) = results.(fields{fid});
            mergedRes.(['DutyCycle' newFieldPostfix]) = resultsAltIrDc.(fields{fid});
        else
            if isnumeric(results.(fields{fid}))
                mergedRes.(fields{fid}) = mean ([results.(fields{fid}) resultsAltIrDc.(fields{fid})]);
            end
        end
    end
    
    allRes = [allRes mergedRes];
end

defaultIdx = 1;
xAx = [allRes(defaultIdx+1:end).(regToSweep)];
for pid=1:length(plotsToShow)
    figure(pid);
    plt = plotsToShow{pid};
    fieldname = plt(~isspace(plt));
    yAx = [allRes(defaultIdx+1:end).(fieldname)];
    plot(xAx,yAx,'b',xAx,repmat(allRes(defaultIdx).(fieldname),size(xAx)),'r');
    title(sprintf('%s as a function of the Vapd',plt))
    xlabel('Vapd register value')
    ylabel(plt);
    legend({'Manual','Flyback'});
end

writetable(struct2table(allRes),fullfile(storeResPath,'results.csv'));

