function [score, coverageRes ] = validateCoverage( hw,isSphericalMode )
    % validate the IR coverage of the HW
    
    % handle missing inputs
    if ~exist('isSphericalMode','var')
        isSphericalMode = true;
    end
    
    
    % set hw and capture images
    nCaptures = 100;
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
    coverageRes.probIm = dbg.probIm;
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
