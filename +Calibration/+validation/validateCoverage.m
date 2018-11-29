function [score, coverageRes ] = validateCoverage( hw,isSphericalMode,figH )
    % validate the IR coverage of the HW
    
    % handle missing inputs
    if ~exist('isSphericalMode','var')
        isSphericalMode = true;
    end
    if ~exist('figH','var')
        figH = [];
    end
    
    % set hw and capture images
    nCaptures = 100;
    r = Calibration.RegState(hw);
    r.add('JFILBypass$',true);
    r.add('RASTbiltBypass',true);
    if isSphericalMode
        r.add('DIGGsphericalEn',true);
    else
        r.add('DIGGsphericalEn',false);
    end
    r.set();
    frames = hw.getFrame(nCaptures,false);
    
    %calculate ir coverage metric
    [score, coverageRes,dbg] = Validation.metrics.irCoverage(frames);
    
    %display image if necessary
    if ~isempty(figH)
        set(0, 'CurrentFigure', figH)
        imagesc(dbg.probIm);
        title('Coverage Map');
        colormap jet;
        colorbar;
    end
    
    %clean up hw
    r.reset();
    
end
