function [score, coverageRes, dbg, frames ] = validateCoverage( hw,isSphericalMode, nCaptures,runParams )
    % validate the IR coverage of the HW
    if ~exist('runParams','var')
        runParams = [];
    end
    % handle missing inputs
    if ~exist('isSphericalMode','var') || isempty(isSphericalMode)
        isSphericalMode = true;
    sphericalmode = 'spherical Enable';
else
    sphericalmode = 'spherical disable';
    end
    
    if ~exist('nCaptures','var')
        nCaptures = 100;
    end
    
    % set hw and capture images
    r = Calibration.RegState(hw);
    r.add('JFILBypass$',true);
    if isSphericalMode
        r.add('DIGGsphericalEn',true);
    else
        r.add('DIGGsphericalEn',false);
    end
    r.set();
    pause(0.1);
    frames = hw.getFrame(nCaptures,false);
    
    %calculate ir coverage metric
    [score, coverageRes,dbg] = Validation.metrics.irCoverage(frames);
    dbg.probIm;
    % Save image 
    if ~isempty(runParams) && isfield(runParams, 'outputFolder')
		ff = Calibration.aux.invisibleFigure;
		imagesc(dbg.probIm);

		title(sprintf('Coverage Map %s',sphericalmode)); colormap jet;colorbar;
		Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('Coverage Map %s',sphericalmode),1);
        ff = Calibration.aux.invisibleFigure();
        plot(dbg.probImV');
        title(sprintf('Coverage %s per horizontal slice',sphericalmode));legend('1-H','2','3-C','4','5-L');xlim([0 size(frames(1).i,2)]);
		Calibration.aux.saveFigureAsImage(ff,runParams,'Validation',sprintf('Coverage %s per horizontal slice',sphericalmode),1);
    end
    
    
    
    %clean up hw
    r.reset();
    
end
