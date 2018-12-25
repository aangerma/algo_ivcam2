function [allDistancesRes] = maxRange2Apd(hw,configFile)
    
    if ~exist('configFile','var')
        if isdeployed
            thisPath = pwd;
        else
            thisPath = fileparts(mfilename('fullpath'));
        end
        configFile = fullfile(thisPath,'maxRangeToVapdConfig.xml');
    end
    % configuration and initializations
    fprintf('Reading configuration xml ...');
    config = xml2structWrapper(configFile);
    fprintf('Done!\n');
    
    fprintf('Applying configuration...');
    distances = config.distances;
    manualTargeting = config.manualTargeting;
    storeResPath = config.storeResPath;
    plts = extractBetween(config.plotsToShow,'{','}');
    plotsToShow =  strtrim(strtok(splitlines(plts),','));
    framesPerValue = config.framesPerValue;
    
    
    %register to sweep parameters
    regToSweep = config.regToSweep;
    sweepVals = [config.sweepDefaultVal config.sweepVals];
    fw = Firmware;
    metaD = fw.getMeta(regToSweep);
    sweepVals = cast(sweepVals,metaD.type);
    fprintf('Done!\n');
    
    %initializations
    allDistancesRes = [];
    
    fprintf('Initializing and configuring HW...');
    % init hw
    if ~exist('hw','var')
        hw = HWinterface();
        hw.getFrame(10);%need to start streaming
        pause(5);
    end
    serialStr = hw.getSerial();
    outfolder = fullfile(storeResPath,serialStr);
    mkdirSafe(outfolder);
    
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
    fprintf('Done!\n');
    fprintf('Starting main loop\n');
    for d = 1:length(distances)
        allRes = [];
        fprintf('Moving to distance %d\n',distances(d));
        % set capture mode to default confidence and IR
        hw.setReg('DESTaltIrEn',0);
        hw.setConfidenceAs();
            
        % capture and label target
        alignFrame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,[],sprintf('move camera to distance %d mm',distances(d)));
        figure(1);
        imagesc(alignFrame.i), colormap gray;
        maximizeFig(1);
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
        params.BWMask = msk;
        
        % main loop
        for ridx=1:length(sweepVals)
            
            %set apd register
            regVal = sweepVals(ridx);
            fprintf_r(sprintf('Changing %s to %d',regToSweep,regVal),[]);
            hw.setReg(regToSweep,regVal);
            pause(0.1);
            hw.getFrame(10); %clear buffer;
            
            % set capture mode to default confidence and IR
            hw.setReg('DESTaltIrEn',0);
            hw.setConfidenceAs();
            pause(0.1);
            frames = hw.getFrame(framesPerValue,false);
            [~, results] = Validation.metrics.maxRange( frames, params );
            
            % set capture mode to duty cycle confidence and alternate IR (max peak)
            hw.setReg('DESTaltIrEn',1);
            hw.setConfidenceAs('dc');
            pause(0.1);
            frames = hw.getFrame(framesPerValue,false);
            [~, resultsAltIrDc] = Validation.metrics.maxRange( frames, params );
            
            mergedRes = struct();
            mergedRes.(regToSweep) = regVal;
            mergedRes.Distance = distances(d);
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
        fprintf('\n');
        fprintf('Writing Results and plots for distance %d...',distances(d));
        writetable(struct2table(allRes),fullfile(outfolder,sprintf('resultsDistance%d.csv',distances(d))));
        defaultIdx = 1;
        xAx = [allRes(defaultIdx+1:end).(regToSweep)];
        for pid=1:length(plotsToShow)
            fig = figure(pid);
            plt = plotsToShow{pid};
            fieldname = plt(~isspace(plt));
            yAx = [allRes(defaultIdx+1:end).(fieldname)];
            plot(xAx,yAx,'b',xAx,repmat(allRes(defaultIdx).(fieldname),size(xAx)),'r');
            title(sprintf('%s as a function of the %s',plt,regToSweep))
            xlabel([regToSweep 'register value'])
            ylabel(plt);
            legend({'Manual','Flyback'});
            saveas(fig,fullfile(outfolder,sprintf('%s to %s distance %d.png',fieldname,regToSweep,distances(d))));
        end
        allDistancesRes = [allDistancesRes allRes];
        fprintf('Done!\n');
    end
    writetable(struct2table(allDistancesRes),fullfile(outfolder,'allResults.csv'));
    fprintf('Finished!\n');
    if nargin == 0
        clear hw;
    end
    if isdeployed
        close all;
    end
    
end
