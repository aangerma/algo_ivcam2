function [score, coverageRes, dbg, frames ] = validateCoverage( hw,isSphericalMode, nCaptures )
    % validate the IR coverage of the HW
    
    % handle missing inputs
    if ~exist('isSphericalMode','var') || isempty(isSphericalMode)
        isSphericalMode = true;
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
%     
%     set(0, 'CurrentFigure', figH)
%     imagesc(dbg.probIm);
%     title('Coverage Map');
%     colormap jet;
%     colorbar;
    
    
    %clean up hw
    r.reset();
    
end
