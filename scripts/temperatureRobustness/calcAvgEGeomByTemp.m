function [ data ] = calcAvgEGeomByTemp( frames,regs )
Temp = nan(numel(frames),1);
eGeomErr = nan(numel(frames),1);
for i = 1:numel(frames)
    iterFrames = frames{i};
    if isempty(iterFrames)
        continue;
    end
    currRpt = reshape([iterFrames.rpt],[20*28,size(iterFrames(1).rpt,2),numel(iterFrames)]);
    d.rpt = currRpt;
    currtmp = iterFrames(1).temp.ldd;
    errors = arrayfun(@(f) eGeom(f,regs), d);
    Temp(i) = currtmp;
    eGeomErr(i) = errors(:);
    
end
data.Temp = Temp;
data.eGeomErr = eGeomErr;
% figure,
% plot(Temp,eGeomErr,'*');
% xlabel('ldd temperature [degrees]');
% ylabel('eGeom [mm]');
% title('Grid Inter Dist Over Temperature')
end

function e1 = eGeom(f,regs)
    v = calcVerices(f,regs);
    vNoNull = reshape(v,[20,28,3]);
    vNoNull = vNoNull(find(sum(~isnan(vNoNull(:,:,1)),2)>0)',find(sum(~isnan(vNoNull(:,:,1)),1)>0),:);
    grid = [size(vNoNull,1),size(vNoNull,2)];
    vNoNull = reshape(vNoNull,[prod(grid),3]);
    sz = 30;
    [e1, e2, e3] = Validation.aux.gridError(vNoNull, grid, sz);

end
function [v,x,y,z] = calcVerices(d,regs)
    
    rpt = d.rpt;
    
    vUnit = Calibration.aux.ang2vec(Calibration.Undist.applyPolyUndist(rpt(:,2) ,regs),rpt(:,3),regs,[])';
    %vUnit = reshape(vUnit',size(d.rpt));
    %vUnit(:,:,1) = vUnit(:,:,1);
    % Update scale to take margins into acount.
    if regs.DEST.hbaseline
        sing = vUnit(:,1);
    else
        sing = vUnit(:,2);
    end
    rtd_=rpt(:,1)-regs.DEST.txFRQpd(1) + regs.DEST.tmptrOffset;
    r = (0.5*(rtd_.^2 - regs.DEST.baseline2))./(rtd_ - regs.DEST.baseline.*sing);
    v = double(vUnit.*r);
    if nargout>1
        x = v(:,1);
        y = v(:,2);
        z = v(:,3);
    end
    
end