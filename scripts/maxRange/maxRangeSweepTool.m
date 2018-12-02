%% definitions

%register to sweep using the tool
regToSweep = 'EXTLvAPD';
sweepVals = [0 360:2:430];
%default valuye as a baseline
sweepDefaultVal = hex2dec('1400');
%this is how we update the value:
regUpdateFunction = @(x)(uint32(hex2dec([dec2hex(x) '1'])));

%other definitions
distances = 230;% distances to go over
errPct = 0.1; % if std is above this fraction of the distance it is consider invalid
postProc = 1; %0 - no jfil or rast bilateral, 1 - with rast and bilateral
manualTargeting = true; %automatically detects the target
reflectivity = 0.1;
unitXlsPath = '';%'Tsense_Vsense_luts_generator_ver11_F8200234.xlsx';
storeResPath = 'Test1';%where to store results
params = Validation.aux.defaultMetricsParams();
params.detectDarkRect = true;

%max range score calculations
wAvgZstd = [0 0.5 0.4];
wValidZstd = [1 0 0.4];
wAvgC = [15 0 0.2];


%% init hw
if ~exist('hw','var')
    hw = HWinterface();
    hw.cmd('dirtybitbypass');
    hw.getFrame(10);%need to start streaming
    pause(5);
end

% configure hw
r=Calibration.RegState(hw);
r.add('RASTbiltAdapt$',uint32(0));
r.add('RASTbiltSharpnessR',uint32(0));
r.add('RASTbiltSharpnessS',uint32(0));
r.add('JFILinvBypass',true);

if postProc
    confTh = hw.read('JFILinvConfThr');
    r.add('JFILbypass$'        ,true    );
    r.add('DIGGgammaScale', uint16([256,64]));
    r.add('RASTbiltBypass',true);
else
    confTh = -1;
    r.add('RASTbiltBypass',false);
    r.add('JFILbypass$',false);
    r.add('DIGGgammaScale', uint16([256,256]));
end
r.set();
pause(0.1);

% read unit data in case xml is provided
if ~isempty(unitXlsPath)
    [unitData,txt,raw] = xlsread(unitXlsPath,'HPK_Data','A1:F1026');
    temps = [raw{3:end,2}]';
    tsenses = hex2dec(raw(3:end,6));
    [usens, uind] = unique(tsenses);
    tsense2temp = [tsenses(uind) temps(uind)];
else
    tsense2temp = [0:1023; 0:1023]';
end


%% initializations
fprintf_r('reset');
regValues = [];
results = {'Distance','Reflectivity',regToSweep,'ROI size','Average Intensity',...
    'Average Z','Average Z Temp Noise','Fill Factor','Average IR STD',...
    'Average Conf','valid STD Pct','Max Range Score','Vsense','Tsense','APD temp'};
ridx = 2;
DB =struct('Distance',[],'VAPD',[],'Mask',[],'Frames',[]);

%% main loop
for d=1:length(distances)
    fprintf_r('Moving to distance %d\n',distances(d));
    fprintf('\n');
    hw.setReg(regToSweep,uint32(sweepDefaultVal)); %set thermal flyback
    pause(0.1);
    alignFrame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],sprintf('move camera to distance %d',distances(d)));
    
    figure(1);
    imagesc(alignFrame.i)
    maximizeFig(1);
    if manualTargeting
        title('Mark Target');
        roi = ginput(4);
        msk = double(poly2mask(roi(:,1),roi(:,2),size(alignFrame.i,1),size(alignFrame.i,2)));
    else
        msk = Validation.aux.updateMaskWithRect(params, alignFrame.i, ones(size(alignFrame.i)));
    end
    imshowpair(alignFrame.i,msk)
    sMsk = sum(msk(:));
    roiSize = sqrt(sMsk);
    avgOverMask = @(x)(nansum_(double(x(:)).*msk(:))./sMsk);
    for g=1:length(sweepVals)
        curVal = sweepVals(g);
        fprintf_r(sprintf('Changing %s to %d',regToSweep,curVal),[]);
        if sweepVals(g) > 0
            hw.setReg(regToSweep,regUpdateFunction(curVal));
            pause(0.1);
            hw.getFrame(10); %clear buffer;
        end
        vsense = hw.readAddr('a00401a0');
        tsense = hw.readAddr('a00401a4');
        apdTemp = tsense2temp(tsense);
        
        frames = hw.getFrame(25,false);
        zImages = double(cat(3,frames(:).z))./8;
        zImages(zImages==0) = NaN;
        avgZ = nanmean_(zImages,3);
        avgZ = avgOverMask(avgZ);
        stds = nanstd_(zImages,1,3);
        avgZStd = nanmean_(stds(msk>0));
        validZStd = avgOverMask(stds<errPct*distances(d)*10);
        
        iImages = double(cat(3,frames(:).i));
        iImages(iImages==0) = NaN;
        avgI = mean(iImages,3);
        avgInt = avgOverMask(avgI);
        stdsI = nanstd_(iImages,1,3);
        avgStdI = nanmean_(stdsI(msk>0));
        
        cImages = double(cat(3,frames(:).c));
        cImages(isnan(iImages)) = NaN;
        avgC = nanmean_(cImages,3);
        avgC = avgOverMask(avgC);
        
        fillfactors = cellfun(@(x,y)(avgOverMask(double(x > 0 & y > confTh))),{frames(:).z}, {frames(:).c});
        avgFF = mean(fillfactors);
        
        mxRangScore = zeros(1,3);
        avgZStdN = avgZStd/(distances(d)*10);
        if avgZStdN == 0
            mxRangScore(1) = wAvgZstd(3);
        elseif avgZStdN > 0.5
            mxRangScore(1) = 0;
        else
            mxRangScore(1) = (wAvgZstd(2) - (avgZStdN - wAvgZstd(1)) /(wAvgZstd(2)-wAvgZstd(1)))./wAvgZstd(2)*wAvgZstd(3);
        end
        mxRangScore(2) = max(0,min(1,(validZStd-wValidZstd(2))/(wValidZstd(1)-wValidZstd(2))))*wValidZstd(3);
        mxRangScore(3) =  max(0,min(1,(avgC-wAvgC(2))/(wAvgC(1)-wAvgC(2))))*wAvgC(3);
        mxRangScoreS = sum(mxRangScore);
        
        results(ridx,:) = {distances(d),reflectivity,curVal,roiSize,avgInt,...
            avgZ,avgZStd,avgFF,avgStdI,avgC,validZStd,mxRangScoreS,vsense,tsense,apdTemp};
        
        DB(ridx-1).Distance = distances(d);
        DB(ridx-1).Gain = curVal;
        DB(ridx-1).Mask = msk;
        DB(ridx-1).Frames = frames;
        ridx = ridx+1;
    end
end

plotRng = 5:12;
for i=plotRng
    figure(i);
    plot([results{3:end,3}],[results{3:end,i}],'b',...
        [results{3:end,3}],repmat(results{2,i},[size(results,1)-2,1]),'r');
    title(sprintf('%s as a function of the Vapd',results{1,i}))
    xlabel('Vapd register value')
    ylabel(results{1,i});
    legend({'Manual','Flyback'});
end
fprintf_r('reset');
if ~isempty(storeResPath)
    for i=[1 plotRng]
        saveas(i,fullfile(storeResPath,sprintf('Figure%d.png',i)));
    end
    mkdir(storeResPath);
    try
        xlswrite(fullfile(storeResPath,'Results.xls'),results);
    catch
    end
    save(fullfile(storeResPath,'results.mat'),'DB');
    save(fullfile(storeResPath,'env.mat'),'results','DB')

end


