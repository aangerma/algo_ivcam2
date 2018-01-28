function [delaySlow, errSlow] = runCalibIrDelay(verbose)

hw = HWinterface();

fNameNoFiltersScript = fullfile(fileparts(mfilename('fullpath')),'IVCAM20Scripts','irDelayNoFilters.txt');
hw.runScript(fNameNoFiltersScript);

irDelayCmdTmpl = 'mwd a0060008 a006000c %08x //[m_regmodel.ansync_ansync_rt.RegsAnsyncAsLateLatencyFixEn] TYPE_REG';

baseDelay = 0;

maxCoarseIterations = 10;
nSampleIterations = 5;
R = nSampleIterations;

qScanLength = 1000; % 
step=ceil(2*qScanLength/R);

for ic=1:maxCoarseIterations
    
    delays = round(baseDelay+(-(R-1)/2:(R-1)/2)'*step);
    if(all(diff(delays)==0))
        break;
    end

    
    irImages = cell(1,5);
    errors = zeros(1,5);
    
    for i=1:nSampleIterations
        
        hw.stopStream();
        pause(0.5);
        
        irDelayCmd = sprintf(irDelayCmdTmpl, 17);
        hw.runCommand(irDelayCmd);
        
        hw.restartStream();
        
        frame = hw.getFrame();
        irImages{i} = frame.i;
        errors(i) = calcErrCoarse(irImages{i});
    end
    
    minInd = minind(errors);
    baseDelay = delays(minInd);
    errSlow = err(minInd);
        
    if(verbose)
        for i=1:R
            aa(i)=subplot(2,R,i);
            imagesc(sl{i},prctile_(sl{i}(sl{i}~=0),[10 90])+[0 1e-3]);
        end
        subplot(2,3,4:6)
        plot(delays,err,'o-');set(gca,'xlim',[delays(1)-step/2 delays(end)+step/2]);
        line([baseDelay baseDelay ],minmax(err),'color','r');
        linkaxes(aa);
        drawnow;
    end
    step = floor(step/2);
    
end
    
end

function [err] = calcErrCoarse(img)

img = double(img);
imgGrad = diff(img, 1, 2);
g2 = imgGrad.^2;
err = sum(g2(:));

end
