function plotEGeom(frames,coolingStage,regs)
Temp = [];
eGeomErr = [];
Time = [];
lastTime = 0;
for i = 1:numel(frames)
    iterFrames = frames{i};
    currtmp = [iterFrames.temp];
    currtmp = [currtmp.ldd]';
    errors = arrayfun(@(f) eGeom(f,regs), iterFrames);
    Temp = [Temp;currtmp];
    eGeomErr = [eGeomErr;errors(:)];
    currtime = [iterFrames.time]';
    Time = [Time;lastTime+currtime];
    if isempty(coolingStage(i).data)
        collingTimeLength = 0;
    else
        collingTimeLength =  coolingStage(i).data(end,1)-currtime(end);
    end
    
    lastTime = max(Time) +collingTimeLength;
end
figure,
subplot(211);
plot(Temp,eGeomErr,'*');
xlabel('ldd temperature [degrees]');
ylabel('eGeom [mm]');
title('Grid Inter Dist Over Temperature')
subplot(212);
plot(Time/3600,eGeomErr,'*');
xlabel('[hours]');
ylabel('eGeom [mm]');
title('Grid Inter Dist Over Time')
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