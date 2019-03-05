function testGeom()
if ~exist('hw','var')
    hw = HWinterface;
    hw.cmd('dirtybitbypass');
    hw.cmd('ALGO_THERMLOOP_EN 10');
    hw.getFrame();
    pause(5);
    
end
load("X:\Data\IvCam2\temperaturesData\demoData\F9010093_8_views_collectedFrames\regs.mat");
% fw = Pipe.loadFirmware('C:\temp\unitCalib\F9010077\PC12\AlgoInternal');
% regs = fw.get();

memorySz = 200;
tmpType = 'ldd';
timeVec = nan(1,memorySz);
temperatures = nan(1,memorySz);
gid = nan(1,memorySz);
maxPerimeterErr = nan(1,memorySz);
rmsError = nan(1,memorySz);

params.target.squareSize = 30;

warning off;
tic;
indices = 1:memorySz;
for j = 1:1e5 
    i = mod(j-1,memorySz)+1;
    indOrder = indices([i+1:memorySz, 1:i]);
    
    f = hw.getFrame(1,1);
    [f.temp.ldd,f.temp.mc,f.temp.ma,f.temp.tSense,f.temp.vSense] = hw.getLddTemperature;
    f.pts = Calibration.aux.CBTools.findCheckerboardFullMatrix(f.i, 1);
    f.rpt = Calibration.aux.samplePointsRtd(f.z,f.pts,regs,1);
    f.time = toc;
    
    indR = find(sum(~isnan(f.pts(:,:,1)),2)>0)';
    indC = find(sum(~isnan(f.pts(:,:,1)),1)>0);
    indR = indR(2:end-1); indC = indC(2:end-1);
%     indR = indR(2:end-1); indC = indC(2:end-1);
%     indR = indR(2:end-1); indC = indC(2:end-1);
    f.pts = f.pts(indR,indC,:);
    rptGrid = reshape(f.rpt,[20,28,size(f.rpt,2)]);
    rpt = nan(size(rptGrid));
    rpt(indR,indC,:) = rptGrid(indR,indC,:);
    f.rpt = reshape(rpt,[],size(f.rpt,2)); 
    
    
    f.i = rot90(f.i,2);
    timeVec(i) = f.time/60;
    temperatures(i) = f.temp.(tmpType);
    [gid(i),v] = eGeom(f,regs);
    vNoNull = reshape(v,[20,28,3]);
    vNoNull = vNoNull(indR,indC,:);
    [gty, gtx] = ndgrid(0:size(vNoNull,1)-1,0:size(vNoNull,2)-1);
    gty = gty*params.target.squareSize;
    gtx = gtx*params.target.squareSize;
    vGt = cat(3,gtx,gty,zeros(size(gtx)));
    
    
    distX = sqrt(diff(vNoNull(:,:,1),1,2).^2+diff(vNoNull(:,:,2),1,2).^2+diff(vNoNull(:,:,3),1,2).^2)-params.target.squareSize;
    distY = sqrt(diff(vNoNull(:,:,1),1,1).^2+diff(vNoNull(:,:,2),1,1).^2+diff(vNoNull(:,:,3),1,1).^2)-params.target.squareSize;
    
    errs = vec(sqrt(((distX(1:end-1,:)).^2 + (distY(:,1:end-1)).^2)));
    edgeErrors = squeeze([vNoNull(1,1,:) - vNoNull(1,end,:);
        vNoNull(1,end,:) - vNoNull(end,end,:);
        vNoNull(end,end,:) - vNoNull(end,1,:);
        vNoNull(end,1,:) - vNoNull(1,1,:)]);
    edgeErrors = sqrt(sum(edgeErrors.^2,2));
    edgeErrorsGT = squeeze([vGt(1,1,:) - vGt(1,end,:);
        vGt(1,end,:) - vGt(end,end,:);
        vGt(end,end,:) - vGt(end,1,:);
        vGt(end,1,:) - vGt(1,1,:)]);
    edgeErrorsGT = sqrt(sum(edgeErrorsGT.^2,2));
    pts = f.pts;
    edgePts = [640,360] + 1 - squeeze([pts(end,end,:); pts(end,1,:); pts(1,1,:); pts(1,end,:)]);
    
    maxPerimeterErr(i) = max(abs(edgeErrors-edgeErrorsGT));
    rmsError(i) = rms(errs(~isnan(errs)));
    
    
    
    
    
    
    
    tempPlot = subplot(2,3,3);
    plot(timeVec(indOrder),temperatures(indOrder));
    ylabel(sprintf('%s temperature [degrees]',tmpType));
    xlabel('time [minutes]')
    gidPlot = subplot(2,3,6);
    plot(temperatures(indOrder),gid(indOrder),'g');
    xlabel(sprintf('%s temperature [degrees]',tmpType));
    ylabel('mm');
    title('Geometric Errors');
    hold on
    plot(temperatures(indOrder),rmsError(indOrder),'r');
    hold on
    plot(temperatures(indOrder),maxPerimeterErr(indOrder),'b');
    hold off
    legend({'GID';'RMS';'MaxPerimeterErr'});
    title(sprintf('%s temperature: %2.2f',tmpType,temperatures(i)));
    grid on,
    
    
    irPlot = subplot(2,3,[1,2,4,5]);
    imagesc(f.i)
    colormap gray
    title(sprintf('Max Perimeter Err: %2.4g mm  RMS: %2.4g GID: %2.4g z: %3.0fcm',maxPerimeterErr(i),rmsError(i),gid(i),mean(mean(f.z(160:200,300:340)/4))/10))
    hold on
    %     drawpolygon('Position',repPos,'FaceAlpha',0);
    fill(edgePts(:,1),edgePts(:,2),'g','FaceAlpha',.05,'linewidth',2,'EdgeColor',[0,0,1])
    
    for k = 0:3
        rot = mod(k,2)*90;
        offX = mod(k,2)*10.*(mod(floor(k/2),2)*-2 +1);
        offY = mod(k+1,2)*10.*(mod(floor(k/2),2)*2 -1);
        text((edgePts(mod(k+1,4)+1,1) + edgePts(mod(k,4)+1,1))/2+offX,...
            (edgePts(mod(k+1,4)+1,2) + edgePts(mod(k,4)+1,2))/2+offY,...
            sprintf('%2.4g GT %2.4g',edgeErrors(k+1),edgeErrorsGT(k+1)),...
            'Rotation',rot,'Color','red','FontSize',14)
    end
    drawnow;
end
end

function [e1,v,vNoNull] = eGeom(f,regs)
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