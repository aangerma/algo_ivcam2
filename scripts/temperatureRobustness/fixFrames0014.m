function fixFrames0014()
    % For each frame - load it, change it and replace it with the fixed
    % version
fw = Pipe.loadFirmware('X:\Data\IvCam2\temperaturesData\rptCollection\F8480014\PC03\AlgoInternal');
badregs = fw.get();
load('X:\Data\IvCam2\temperaturesData\rptCollection\0014_bad_regs\iter_0000\frameData_00000.mat');
load('X:\Data\IvCam2\temperaturesData\rptCollection\0014_latest\regs.mat');

dataDir = 'X:\Data\IvCam2\temperaturesData\rptCollection\0014_bad_regs - Copy';

iterations = dir(dataDir);
for iter = 1:numel(iterations)
   itName = iterations(iter).name;
   if ~contains(itName,'iter')
      continue; 
   end
   subDir = fullfile(dataDir,itName);
   framesPaths = dir(subDir);
   for f = 1:numel(framesPaths)
      frname = framesPaths(f).name;
      if ~contains(frname,'frameData')
         continue; 
      end
      fullName = fullfile(subDir,frname);
      fprintf('%s\n',fullName);
      load(fullName);
      frame = fixFrame(frame,regs,badregs);
      save(fullName,'frame');
   end
    
end
end

function frame = fixFrame(frame,regs,badregs)

zOrig = rpt2z(frame,badregs);

frame = z2rpt(zOrig,frame,regs);

end
function frame = z2rpt(zOrig,frame,regs)
    xym = reshape(frame.pts,[],2)-1+0.5;
    [ v ] = squeeze(Calibration.aux.xy2vec( xym(:,1),xym(:,2),regs ));
    v = v./v(:,3).*zOrig;
    r = sqrt(sum(v.^2,2));
    
    [~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(xym(:,1)-0.5,xym(:,2)-0.5,regs);
    C=2*r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
    rtd=r+sqrt(r.^2-C);
    rtd=rtd+regs.DEST.txFRQpd(1);
    
    
    [angx,angy]=Calibration.aux.xy2angSF(xym(:,1),xym(:,2),regs,1);
    angx = Calibration.Undist.inversePolyUndist(angx,regs);
    
    frame.rpt = cat(2,rtd(:),angx(:),angy(:));
    frame.rpt(isnan(rtd(:)),:) = nan;
end
function z = rpt2z(frame,regs)
    rpt = frame.rpt;
%     [x,y] = Calibration.aux.ang2xySF(Calibration.Undist.applyPolyUndist(rpt(:,2),regs),rpt(:,3),regs,[],1);
%     x = x - 0.5; y = y-0.5;
    
    xym = reshape(frame.pts,[],2)-1;

    
    [~,cosx,~,~,~,cosw,sing]=Pipe.DEST.getTrigo(xym(:,1),xym(:,2),regs);


    rtd = rpt(:,1) - regs.DEST.txFRQpd(1);
    dnm = (rtd - regs.DEST.baseline.*sing);
    %     dnm = (rtd - regs.DEST.baseline.*sinx); %BUG
    calcDenum = 1./ dnm;
    
    r = (0.5*(rtd.^2 - regs.DEST.baseline2)).*calcDenum;

    % lgr.print2file(sprintf('\trange = %X\n',typecast(r(lgrOutPixIndx),'uint32')));

    %% calc depth
    z = r;
    coswx=cosw.*cosx;
    z = z.*coswx;
    

end