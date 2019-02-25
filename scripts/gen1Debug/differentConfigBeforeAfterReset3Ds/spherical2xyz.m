function [v] = spherical2xyz(frames,regs)
    v = calcVerices(frames,regs);
       
end

function [v] = calcVerices(d,rtlRegs)
    rpt = d.rpt;
    undistFunc = @(ax,polyVars) ax + ax/2047*polyVars(1)+(ax/2047).^2*polyVars(2)+(ax/2047).^3*polyVars(3);

    vUnit = Calibration.aux.ang2vec(undistFunc(rpt(:,2),[rtlRegs.FRMW.polyVars]),rpt(:,3),rtlRegs,[])';
    %vUnit = reshape(vUnit',size(d.rpt));
    %vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    if rtlRegs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    rtd_=rpt(:,1)-rtlRegs.DEST.txFRQpd(1);
    r = (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);
    v = double(vUnit.*r);
    
    
end