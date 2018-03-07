function [ivsFilename,gt,regs,luts]=patternGenerator(varargin)
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
[fw,p] = getInputRegs(varargin{:});
[regs,luts] = fw.get();

% check ROI cover
%  if( ~isROICovered(regs,luts))
%       error('Bad configuration: scan line not covering all ROI window');
%  end 
%

multiFocal = false;
if(any(regs.EPTG.multiFocalROI(3:4)~=regs.EPTG.multiFocalROI(1:2)))
    multiFocal = true;
end
if(multiFocal)
    configInputStruct=regs;
    configInputStruct.MTLB.txSymbolLength=single(1);
    configInputStruct.EPTG.multiFocalROI=int32([0 0 0 0]);
    [ivsFilename]=Pipe.patternGenerator(configInputStruct,'outputdir',p.outputDir);
    ivsA=io.readIVS(ivsFilename);
    
    configInputStruct.MTLB.txSymbolLength=single(2);
    [ivsFilename]=Pipe.patternGenerator(configInputStruct,'outputdir',p.outputDir);
    ivsB=io.readIVS(ivsFilename);
    
    xA=ivsA.xy(1,:);
    yA=ivsA.xy(2,:);
    
    xB=ivsB.xy(1,:);
    yB=ivsB.xy(2,:);
    
    xy00=regs.EPTG.multiFocalROI(1:2);
    xy11=regs.EPTG.multiFocalROI(3:4);
    roiindA = xA>xy00(1) & xA<xy11(1) & yA>xy00(2) & yA<xy11(2);
    roiindB = xB>xy00(1) & xB<xy11(1) & yB>xy00(2) & yB<xy11(2);
    
    inA = find(diff(roiindA)== 1);
    otA = find(diff(roiindA)==-1);
    
    inB = find(diff(roiindB)== 1);
    otB = find(diff(roiindB)==-1);
    
    n = min([length(inA) length(otA) length(inB) length(otB)]);
    inA=inA(1:n);
    otA=otA(1:n);
    inB=inB(1:n);
    otB=otB(1:n);
    ivs=ivsA;
    for i=n:-1:1
        ivs.slow  =[ivs.slow( 1:inA(i)-1) ivsB.slow( inB(i):otB(i)-1) ivs.slow( otA(i):end)];
        ivs.flags =[ivs.flags(1:inA(i)-1) ivsB.flags(inB(i):otB(i)-1) ivs.flags(otA(i):end)];
        ivs.xy    =[ivs.xy( :,1:inA(i)-1) ivsB.xy( :,inB(i):otB(i)-1) ivs.xy( :,otA(i):end)];
        ivs.fast =[ivs.fast(1:inA(i)*64-1) ivsB.fast(inB(i)*64:otB(i)*64-1) ivs.fast(otA(i)*64:end)];
    end
    
    
    io.writeIVS(ivsFilename,ivs);
    return;
end
    rng(regs.EPTG.seed)
if(regs.GNRL.rangeFinder)
    %%
    [ivs,flag_ld_on,flag_tx_code_start,flag_scandir,flag_txrx_mode] = rangeFinderData(regs);
else
    if(regs.EPTG.frameRate==0)
        error('cannot run EPTG with EPTGframeRate == 0');
    end
    
    ow = double(regs.FRMW.xres);
    oh = double(regs.FRMW.yres);
    osz = [oh ow];
    
    if ~isempty(p.zImg)
        gt.zImg = p.zImg;
    else
        gt.zImg = generateZimage(osz,regs.EPTG.zImageType,double(regs.EPTG.minZ),double(regs.EPTG.maxZ));
    end
    if ~isempty(p.aImg)
        gt.aImg = p.aImg;
    else
        gt.aImg = generateAlbedoImage(osz,regs.EPTG.irImageType);
    end
    
    gt.zImg = imresize_(gt.zImg,[oh ow]);
    gt.aImg = imresize_(gt.aImg,[oh ow]);
    
    %% calc
    
    
    
    chunkFreq = double(regs.GNRL.sampleRate)/(64*double(regs.MTLB.txSymbolLength)); %GHz
    
    dt = 1/chunkFreq;%nsec;
    returnTime = regs.EPTG.returnTime;
    t = (0:dt:1/double(regs.EPTG.frameRate)*1e9-dt);
    if(length(t)>regs.EPTG.nMaxSamples)
    t = t(1:min(regs.EPTG.nMaxSamples,length(t)));
    returnTime=0; %if truncating rest of frame - do not add return time
    end
    tF = (0:length(t)*64-1)*dt/64;
    
    codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
    c = codevec(1:regs.GNRL.codeLength);
    c = vec(repmat(c(:),1,regs.GNRL.sampleRate)');
    % [yg,xg]=ndgrid(linspace(-1,1,size(im.zImg,1)),linspace(-1,1,size(im.zImg,2)));
    % yg = yg*double(regs.FRMW.yfov)/double(regs.FRMW.xfov);
    % d=sqrt(xg.*xg+yg.*yg);
    
    
    
    angyIn =@(f,phi)  -regs.FRMW.yfov/2/2*cos(2*pi*t*double(f*1e-9)+phi); %fast
    retInd = find(t>=t(end)-double(returnTime*1e6),1);
    tscan = t(1:retInd);
    frameTime = tscan(end)-tscan(1);
    tret = t(retInd+1:end);
    switch(regs.EPTG.slowscanType)
        case 0%linear
            angxIn  = regs.FRMW.xfov/4*(tscan/frameTime*2-1);
        case 1%sine
            angxIn  =  -regs.FRMW.xfov/4*cos(tscan/frameTime*2*pi/2);
        case 2%atan
            angxIn  =  atand(tand(regs.FRMW.xfov/2) * (2 *  tscan/frameTime-1))/2;
        case 3%raster
            angxIn =(cumsum([diff(sin(2*pi*tscan/frameTime*2)>0) 0]>0)*2-1);
            angxIn =angxIn /angxIn (end);
            angxIn  =regs.FRMW.xfov/2*(angxIn*2-1);
            
        otherwise
            error('unknonw scan type');
            
    end
    if(length(tret)>1)
    angxInRet = interp1([tscan(end-1:end) tret(end-1:end)],[angxIn(end-1:end) angxIn(1:2)],tret,'spline');
    angxIn = [angxIn angxInRet];
    end
    scPhase = regs.EPTG.slowCouplingPhase;
    smPhase = regs.EPTG.scndModePhase;
    
    fmir = regs.EPTG.mirrorFastFreq;
    fscnd = regs.EPTG.scndModeFreq;
    
    scFactor = regs.EPTG.slowCouplingFactor;
    smFactor = regs.EPTG.scndModeFactor;
    
    
    angy = angyIn(regs.EPTG.mirrorFastFreq,0)+angxIn*regs.FRMW.projectionYshear;
    angx = angxIn ...
            + angyIn(fmir ,-scPhase*pi/180)*scFactor ...
            + angyIn(fscnd,-smPhase*pi/180)*smFactor;
    angx=double(angx);
    angy=double(angy);
    
    mm = @(x) max(-2047,min(2047,x));
    %12bit signed
    angxQ = mm(int16(round(angx/(regs.FRMW.xfov/2*.5)*(2^11-1))));
    angyQ = mm(int16(round(angy/(regs.FRMW.yfov/2*.5)*(2^11-1))));
    
    %     [yi,xi]=ndgrid(0:oh-1,0:ow-1);
    regs4digg=regs;
%     regs4digg.FRMW.marginL=int16(0);
%     regs4digg.FRMW.marginR=int16(0);
%     regs4digg.FRMW.marginT=int16(0);
%     regs4digg.FRMW.marginB=int16(0);
%     regs4digg.FRMW.gaurdBandH=single(0);
%     regs4digg.FRMW.gaurdBandV=single(0);
    regs4digg = Firmware.mergeRegs(regs4digg,Pipe.DIGG.FRMW.getAng2xyCoeffs(regs4digg));
    [regs4digg_,luts4digg_] = Pipe.DIGG.FRMW.buildLensLUT(regs4digg,[]);
    regs4digg = Firmware.mergeRegs(regs4digg,regs4digg_);
    luts4digg = Firmware.mergeRegs(luts    ,luts4digg_);

    
    [xA,yA]=Pipe.DIGG.ang2xy(angxQ,angyQ,regs4digg,Logger(),[]);
    [xA,yA] = Pipe.DIGG.undist(xA,yA,regs4digg,luts4digg,Logger(),[]);
    dn = @(x) bitshift(x+2^(double(regs.DIGG.bitshift)-1),-double(regs.DIGG.bitshift));
    %     plot(angx,angy)
    %%
    xA = dn(xA);
    yA = dn(yA);
    
    %% HW contraints
    %     ok=Pipe.CBUF.xRateCheck(x,y,regs);
    %     if(~ok)
    %         error('slow scan is too fast');
    %     end
    
    %%
    
    
    okloc =xA>=0 & xA<size(gt.zImg,2) & yA>=0 & yA<size(gt.zImg,1);
    ind=sub2ind(size(gt.zImg),yA(okloc)+1,xA(okloc)+1);
    angxg=accumarray(vec(ind),vec(angx(okloc)),[numel(gt.zImg) 1],@mean);
    angyg=accumarray(vec(ind),vec(angy(okloc)),[numel(gt.zImg) 1],@mean);
    angxg = reshape(angxg,size(gt.zImg));
    angyg = reshape(angyg,size(gt.zImg));
    %    [angyg,angxg]=ndgrid(double(linspace(min(angy),max(angy),oh)),double(linspace(min(angx),max(angx),ow)));
    %
    [sinx,cosx,siny,cosy]=Pipe.DEST.getTrigo(size(gt.zImg),regs);
    %     pixangx = atand(double(regs.DEST.p2axa *xi+ regs.DEST.p2axb));
    %     pixangy = atand(double(regs.DEST.p2aya *yi+ regs.DEST.p2ayb));
    
    %delay vector
    if(regs.DEST.hbaseline)
        bx=regs.DEST.baseline;  by=0;
    else
        bx=0; by=regs.DEST.baseline;
    end
    tanx = sinx./cosx;
    tany = siny./cosy;
    r1 = gt.zImg.*sqrt(tanx.^2+tany.^2+1);
    r2 =sqrt((gt.zImg.*tanx-bx).^2+(gt.zImg.*tany-by).^2+gt.zImg.^2);
    rtdImg = double(r1+r2);
    
    
    
    
    C = 299.792458;
    dImg = rtdImg/C; % Round Trip Time
    dImg = dImg + randn(size(dImg))*double(regs.EPTG.sampleJitter);
    dvct = griddata(angxg,angyg,dImg,double(angx),double(angy));

    dvctF = interp1(t,dvct,tF,'linear','extrap');
    %%
    %genereate slow
    albedoImg = max(0,gt.aImg);
    ivs.slow = griddata(angxg,angyg,albedoImg,angx,angy);
    %genererate fast
    ivs.fast = repmat(c,ceil(length(t)*64/length(c)),1);
    ivs.fast = double(ivs.fast);
    ivs.fast = ivs.fast(1:length(tF));
    
    %channel delay
    ivs.slow  = Utils.timePropogate(ivs.slow,dvct/dt);
    ivs.fast  = Utils.timePropogate(ivs.fast,dvctF/(dt/64));
    
    %apply distance attenuation
    ivs.slow = ivs.slow./(Utils.dtnsec2rmm(dvct ).^2*1e-6);
    ivs.fast = ivs.fast./(Utils.dtnsec2rmm(dvctF).^2*1e-6);
    
    ivs.fast(isnan(ivs.fast))=0;
    
    %shot noise
    ivs.slow = ivs.slow +sqrt( ivs.slow).*randn(size(ivs.slow))*double(regs.EPTG.noiseLevel);
    ivs.fast = ivs.fast + sqrt(ivs.fast).*randn(size(ivs.fast))*double(regs.EPTG.noiseLevel);
    
    
    % AWGN
    ivs.slow = ivs.slow + randn(size(ivs.slow))*double(regs.EPTG.noiseLevel);
    ivs.fast = ivs.fast + randn(size(ivs.fast))*double(regs.EPTG.noiseLevel);
    
    
    
    %HPF
    [b,a]=butter_(1,4e-3/(32/dt),'high');
    
    ivs.fast = filter(b,a,ivs.fast);
    
    %dynamic range
    ivs.slow = ivs.slow*(2^12-1);
    ivs.slow = uint16(min(2^12-1,max(0,ivs.slow)));
    ivs.fast = ivs.fast>0;
    %slow sampling rate
    irSampleFreq = regs.FRMW.pllClock/double(regs.EPTG.irSampleFreqPLLdiv);
    irInOutRatio = round(chunkFreq/irSampleFreq);
    if(irInOutRatio>1)
        ivs.slow = vec(repmat(ivs.slow(1:irInOutRatio:end),irInOutRatio,1))';
    end
    ivs.slow = ivs.slow(1:length(t));
    %%
    
    %         [gty,gtx]=ndgrid(0:oh-1,0:ow-1);
    %         gtImg = griddata(xPipe,yPipe,dvct,gtx,gty);
    %         gtImg = Utils.dtnsec2rmm(gtImg);
    %
    %         okloc =xPipe>=0 & xPipe<ow & yPipe>=0 & yPipe<oh;
    %         ind=sub2ind(osz,yPipe(okloc)+1,xPipe(okloc)+1);
    %         angxg=accumarray(ind,angx(okloc),[ow*oh 1],@mean);
    %         angyg=accumarray(ind,angy(okloc),[ow*oh 1],@mean);
    %         angxg = reshape(angxg,osz);
    %         angyg = reshape(angyg,osz);
    %
    %         gtImg = gtImg.*(cosd(2*angxg).*cosd(2*angyg));
    
    if(regs.FRMW.xR2L)
        angxQ = fliplr(angxQ);
    end
    ivs.xy = [vec(angxQ) vec(angyQ)]';
    % regs.MTLB.txSymbolLength=1? txrx_mode=0 1Ghz
    % regs.MTLB.txSymbolLength=2? txrx_mode=1 500Mhz
    % regs.MTLB.txSymbolLength=4? txrx_mode=2 250Mhz
    % else? txrx_mode=3
    flag_ld_on = uint8(abs(double(angyQ))<2^11-2);
    
    for i=1:regs.EPTG.ldonFallIncidents
        i0 = round(rand*(length(flag_ld_on)-1)+1);
        i1 = i0 +round(double(regs.EPTG.ldonmaxFallTime)/dt*rand);
        i1 = min(i1,length(flag_ld_on));
        flag_ld_on(i0:i1)=false;
    end
    
    flag_ld_on(retInd:end)=false;
    
    flag_tx_code_start = uint8(zeros(size(ivs.slow)));
    %     nSlowPacktesPerScanLine = .5/(regs.EPTG.mirrorFastFreq*1e-9*dt);
    nPacketsPerCode = double(regs.GNRL.tmplLength)/64;
    if(rem(nPacketsPerCode,1)~=0)
        [~,fact]=rat(nPacketsPerCode);
        nPacketsPerCode=nPacketsPerCode*fact;
    end
    %     tx_start_locs = floor((0:nSlowPacktesPerScanLine:length(ivs.slow)-1)/nPacketsPerCode)*nPacketsPerCode;
    %     flag_tx_code_start(tx_start_locs+1)=true;
    flag_tx_code_start(1:nPacketsPerCode:end)=true;
    flag_scandir = uint8([diff(double(angy))>0 0]);
    if(regs.FRMW.yflip)
        flag_scandir = 1-flag_scandir;
    end
    flag_tx_code_start(1)=true; %set first packet to 1 for RTL compatability
    if(multiFocal)
        flag_txrx_mode=uint8(iff(regs.MTLB.txSymbolLength,0,1,3,2)*ones(size(ivs.slow)));
    else
        flag_txrx_mode=uint8(zeros(size(ivs.slow)));
    end
end
ivs.flags = bitshift(flag_ld_on        ,0)+...
    bitshift(flag_tx_code_start,1)+...
    bitshift(flag_scandir      ,2)+...
    bitshift(flag_txrx_mode    ,3);

%% write to dir

newregs.DEST.txFRQpd=single([0 0 0]);
newregs.MTLB.fastChDelay = uint32(0);
newregs.MTLB.slowChDelay = uint32(0);

if(~exist(p.outputDir,'dir'))
    mkdir(p.outputDir);
end
if(regs.EPTG.calibVariationsP~=0)
    randp =@(x) (1+(rand*2-1)*regs.EPTG.calibVariationsP)*x;
    minmaxval =@(x,m) max(m(1),min(m(2),x));
    randpSafe=@(x,s) minmaxval(randp(x),metaMM(s));
    
    newregs.FRMW.xfov             = randpSafe(regs.FRMW.xfov             ,fw.getMeta('FRMWxfov'             ));
    newregs.FRMW.yfov             = randpSafe(regs.FRMW.yfov             ,fw.getMeta('FRMWyfov'             ));
    newregs.FRMW.xoffset          = randpSafe(regs.FRMW.xoffset          ,fw.getMeta('FRMWxoffset'          ));
    newregs.FRMW.yoffset          = randpSafe(regs.FRMW.yoffset          ,fw.getMeta('FRMWyoffset'          ));
    newregs.FRMW.projectionYshear = randpSafe(regs.FRMW.projectionYshear ,fw.getMeta('FRMWprojectionYshear' ));
    newregs.FRMW.laserangleH      = randpSafe(regs.FRMW.laserangleH      ,fw.getMeta('FRMWlaserangleH'      ));
    newregs.FRMW.laserangleV      = randpSafe(regs.FRMW.laserangleV      ,fw.getMeta('FRMWlaserangleV'      ));
    newregs.FRMW.undistLensCurve  = randpSafe(regs.FRMW.undistLensCurve  ,fw.getMeta('FRMWundistLensCurve'  ));
    newregs.FRMW.shadingCurve     = randpSafe(regs.FRMW.shadingCurve     ,fw.getMeta('FRMWshadingCurve'     ));
    newregs.FRMW.undistXfovFactor = randpSafe(regs.FRMW.undistXfovFactor ,fw.getMeta('FRMWundistXfovFactor' ));
    newregs.FRMW.undistYfovFactor = randpSafe(regs.FRMW.undistYfovFactor ,fw.getMeta('FRMWundistYfovFactor' ));
    
    newregs.FRMW.destRxpdGen    = randpSafe(regs.FRMW.destRxpdGen    ,fw.getMeta('FRMWdestRxpdGen_000'    ));
    newregs.FRMW.destTxpdGen    = randpSafe(regs.FRMW.destTxpdGen    ,fw.getMeta('FRMWdestTxpdGen_000'    ));

end

fw.setRegs(newregs,p.configOutputFilename);
fw.writeUpdated(p.configOutputFilename);
calibFilename = fullfile(p.outputDir,filesep,'calib.csv');
fid=fopen(calibFilename,'w');
fclose(fid);
calibFilename = fullfile(p.outputDir,filesep,'mode.csv');
fid=fopen(calibFilename,'w');
fclose(fid);

ivsFilename = fullfile(p.outputDir,filesep,'patternGenerator.ivs');
io.writeIVS(ivsFilename,ivs);




if(p.verbose)
    %%
    n = round(linspace(1,length(angx),min(length(angx),10e3)));
    figure(938545);
    subplot(221)
    plot(angx(n),angy(n));
    title('Input angles')
    xlabel('x angle');
    ylabel('y angle');
    
    subplot(222)
    plot(xA(n),yA(n),'.-');
    title('projected locations')
    xlabel('x');
    ylabel('y');
    grid on;axis tight
    
    subplot(223)
    scatter(xA(n),yA(n),10,ivs.slow(n),'fill');
    title('IR')
    xlabel('x');
    ylabel('y');
    grid on;axis tight;
    
    subplot(223)
    imagesc(albedoImg);
    hold on
    scatter(xA(n)+1,yA(n)+1,10,ivs.slow(n)/max(ivs.slow(:)),'fill','MarkerEdgeColor',[0 0 0]);
    hold off
    title('IR')
    xlabel('x');
    ylabel('y');
    grid on;axis tight;
    
    subplot(224)
    imagesc(dImg);
    hold on
    scatter(xA(n),yA(n),30,dvct(n),'fill','MarkerEdgeColor',[0 0 0]);
    hold off
    title('delay')
    xlabel('x');
    ylabel('y');
    grid on;axis tight;
    
    
    
end
[regs,luts] = fw.get();

if(p.runPipe)
    Pipe.autopipe(ivsFilename);
end

end


function im = generateZimage(sz,type,minZ,maxZ)
if(type==1)
    im = ones(sz)*maxZ;
else
    im = genVarDepth(sz,type-2)*(maxZ-minZ)+minZ;
end
end

function im = generateAlbedoImage(sz,type)

switch(type)
    
    case 1 %wall
        im = ones(sz)*.2;
        
    case 2 %checkerboard
        if(any(sz<64))
            nx=2;
        else
            nx = 4;
        end
        ny = max(1,round(sz(1)/sz(2)*nx));
        
        im = repmat(kron([.15 .5;.5 .15],ones(ceil(sz./[ny nx]*.5))),[ny nx]);
        im = im(1:sz(1),1:sz(2));
    case 3 %randomCubes
        im = genRandImg(sz,false);
        
    otherwise
        error('Pipe.patternGenerator : unknonwn IRimage Type');
end
end



function img=genVarDepth(sz,ordr)
N=4;
ordr=double(ordr);
s = ceil(sz/N);
[yg,xg]=ndgrid(linspace(-1,1,s(1)),linspace(-1,1,s(2)));

img = zeros(N*s);
for i=0:ordr
    img = img+kron(rand(N)*2-1,ones(s)).*kron(xg.^i,ones(N))+kron(rand(N)*2-1,ones(s)).*kron(yg.^i,ones(N));
end
img = img(1:sz(1),1:sz(2));
r=[min(img(:)) max(img(:))];
img = (img-r(1))/diff(r);
end

function img=genRandImg(sz,edgy)
if(edgy)
    intrpMethod = 'nearest';
else
    intrpMethod = 'spline';
end
[ygs,xgs]=ndgrid(0:32:256,0:32:256);
[angyg,angxg]=ndgrid(linspace(1,256,sz(1)),linspace(1,256,sz(2)));
img =interp2(xgs,ygs,rand(9),angxg,angyg,intrpMethod);
r=[min(img(:)) max(img(:))];
img = (img-r(1))/diff(r)*.8+0.2;
end


function [fw,p] =getInputRegs(varargin)
isflag = @(x) or(isnumeric(x),islogical(x));
isimg = @(x) ismatrix(x) && min(x(:))>=0;

inputData=varargin{1};

if(ischar(inputData) && exist(inputData,'file')~=0)
    defOutDir=fileparts(inputData);
else
    defOutDir = tempdir;
end
p = inputParser;
addOptional(p,'outputDir',defOutDir);
addOptional(p,'verbose',false,isflag);
addOptional(p,'zImg',[],isimg);
addOptional(p,'aImg',[],isimg);
addOptional(p,'runPipe',false,isflag);
addOptional(p,'regHandle','throw',@ischar);

parse(p,varargin{2:end});
p = p.Results;



p.configOutputFilename = fullfile(p.outputDir,filesep,'config.csv');



fw = Firmware();
fw.setRegHandle(p.regHandle);
if(isstruct(inputData)) %regs struct
    configOutputFilename = fullfile(p.outputDir,'config.csv');
    fw.setRegs(inputData,configOutputFilename);
elseif(contains(inputData,'.csv')) %config.csv
    if(~exist(inputData,'file'))
        error('COuld not find file %s',inputData);
    end
    if(~strcmpi(inputData,p.configOutputFilename))
        copyfile(inputData,p.configOutputFilename,'f')
    end
    fw.setRegs(p.configOutputFilename);
    
    
    
elseif(ischar(inputData))
    switch(inputData)
        case 'wall'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.minZ = single(1000);
            patgenregs.EPTG.maxZ = single(1000);
            patgenregs.FRMW.xres = uint16(320);
            patgenregs.FRMW.yres = uint16(240);
            patgenregs.EPTG.frameRate = single(60);
            patgenregs.EPTG.noiseLevel=single(0);
            patgenregs.EPTG.sampleJitter=single(0);
            patgenregs.EPTG.calibVariationsP=single(0);
            patgenregs.DEST.hbaseline=false;
            patgenregs.DEST.baseline=single(30);
            
        case 'debug'
            patgenregs.EPTG.maxZ = single(1500);
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.noiseLevel = single(0.01);
            patgenregs.FRMW.xres=uint16(64);
            patgenregs.FRMW.yres=uint16(64);
            patgenregs.JFIL.dnnBypass=true;
            patgenregs.EPTG.frameRate=single(600);
            
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( Codes.propCode(16,1) );
        case 'checkerboard'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(2);
            patgenregs.EPTG.noiseLevel = single(0.01);
            patgenregs.EPTG.frameRate = single(60);
        case 'largeFOV'
            patgenregs.EPTG.zImageType = uint8(1);
            patgenregs.EPTG.irImageType = uint8(2);
            patgenregs.DIGG.undistBypass = false;
            patgenregs.EPTG.frameRate = single(60);
        case 'randomA'
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(3);
            patgenregs.EPTG.frameRate = single(60);
        case 'randomB'
            patgenregs.EPTG.zImageType = uint8(5);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.frameRate = single(60);
        case 'helloworld'
            patgenregs.EPTG.zImageType = uint8(3);
            patgenregs.EPTG.irImageType = uint8(1);
            patgenregs.EPTG.frameRate = single(60);
        case 'rangefinder'
            
            patgenregs.GNRL.rangeFinder= true;
            patgenregs.FRMW.xres=uint16(2);
            patgenregs.FRMW.yres=uint16(1);
            patgenregs.RAST.biltBypass=true;
            patgenregs.CBUF.bypass=true;
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( Codes.propCode(128,1) );
        case 'ironly'
            
            [patgenregs.FRMW.txCode, patgenregs.GNRL.codeLength] = Utils.bin2uint32( [1 0 1 0 1 0 1 0] );
            patgenregs.DCOR.bypass=true;
            patgenregs.DEST.bypass=true;
            patgenregs.JFIL.edge1bypassMode = uint8(1);
            patgenregs.JFIL.edge3bypassMode = uint8(1);
            patgenregs.JFIL.edge4bypassMode = uint8(1);
            patgenregs.JFIL.dnnBypass = true;
            patgenregs.DIGG.notchBypass = true;
        case 'multifocal'
            
            patgenregs.EPTG.zImageType = uint8(2);
            patgenregs.EPTG.irImageType = uint8(3);
            patgenregs.EPTG.multiFocalROI=int32([-600 -400 1000 1000]);
            patgenregs.EPTG.frameRate=single(60);
        otherwise
            error('Unknonw patgen input');
            
    end
    fw.setRegs(patgenregs,p.configOutputFilename);
    
else
    error('Unknonw input');
end



end





function [ivs,flag_ld_on,flag_tx_code_start,flag_scandir,flag_txrx_mode] = rangeFinderData(regs)



nNESTpackets = 1000+randi(32);
nTrainPackets = 1000+randi(32);
nDeassertPackets = 1000+randi(32);
nDepthArepeatitations = 16;
distance = regs.EPTG.maxZ;%mm
snrA = 10;
snrB = double(regs.EPTG.noiseLevel)*snrA;





%FREQ is always 250Mhz
txrxMode = iff(regs.MTLB.txSymbolLength,0,1,-1,2);
sampleFreq = double(regs.GNRL.sampleRate)/regs.MTLB.txSymbolLength;

c = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
c = c(1:regs.GNRL.codeLength);
c = vec(repmat(c(:),1,regs.GNRL.sampleRate)')';
c = repmat(c,1,nDepthArepeatitations);
nSamplesDelay = round(Utils.rmm2dtnsec(distance)*sampleFreq);
c=[zeros(1,nSamplesDelay) c(1:end-nSamplesDelay)];


ivs.slow=zeros(0,'uint16');
ivs.xy=zeros(2,0,'uint16');
ivs.fast=false(0);

flag_ld_on =zeros(0,'uint8');
flag_tx_code_start=zeros(0,'uint8');
flag_scandir=zeros(0,'uint8');
flag_txrx_mode=zeros(0,'uint8');

%0.NEST(A)
ivs.slow           = [ivs.slow           ones(1,nNESTpackets,'uint16')];
ivs.fast           = [ivs.fast           false(1,nNESTpackets*64)];
ivs.xy             = [ivs.xy             repmat([0;0],1,nNESTpackets)];
flag_ld_on         = [flag_ld_on         zeros(1,nNESTpackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nNESTpackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nNESTpackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nNESTpackets,'uint8')];
%1. TRAIN(A)
ivs.slow           = [ivs.slow           randi(2^12-1, [1,nTrainPackets],'uint16')];
ivs.fast           = [ivs.fast           randi(2, [1,nTrainPackets*64],'uint8')==1];
ivs.xy             = [ivs.xy             repmat([0;2],1,nTrainPackets)];
flag_ld_on         = [flag_ld_on         ones(1,nTrainPackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nTrainPackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nTrainPackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nTrainPackets,'uint8')];
%2. DEPTH(A)
ivs.slow           = [ivs.slow           min(2^12-1, randi(ceil(sqrt(2^snrA)), [1 length(c)/64],'uint16')+2^snrA)];
ivs.fast           = [ivs.fast           c+randn(size(c))*2/double(snrA)>.5];
ivs.xy             = [ivs.xy             repmat([0;3],1,length(c)/64)];
flag_ld_on         = [flag_ld_on         ones(1,length(c)/64,'uint8')];
flag_tx_code_start = [flag_tx_code_start 1 zeros(1,length(c)/64-1,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,length(c)/64,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,length(c)/64,'uint8')];
%5. BACKUP(A)

%4.ld_on deassert
ivs.slow           = [ivs.slow           zeros(1,nDeassertPackets,'uint16')];
ivs.fast           = [ivs.fast           false(1,nDeassertPackets*64)];
ivs.xy             = [ivs.xy             repmat([0;5],1,nDeassertPackets)];
flag_ld_on         = [flag_ld_on         zeros(1,nDeassertPackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nDeassertPackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nDeassertPackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nDeassertPackets,'uint8')];

%5.NEST(B)
ivs.slow           = [ivs.slow           ones(1,nNESTpackets,'uint16')];
ivs.fast           = [ivs.fast           false(1,nNESTpackets*64)];
ivs.xy             = [ivs.xy             repmat([1;5],1,nNESTpackets)];
flag_ld_on         = [flag_ld_on         zeros(1,nNESTpackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nNESTpackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nNESTpackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nNESTpackets,'uint8')];
%6. TRAIN(B)
ivs.slow           = [ivs.slow           randi(2^12-1, [1,nTrainPackets],'uint16')];
ivs.fast           = [ivs.fast           randi(2, [1,nTrainPackets*64],'uint8')==1];
ivs.xy             = [ivs.xy             repmat([1;4],1,nTrainPackets)];
flag_ld_on         = [flag_ld_on         ones(1,nTrainPackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nTrainPackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nTrainPackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nTrainPackets,'uint8')];
%7. DEPTH(B)
ivs.slow           = [ivs.slow           min(2^12-1, randi(ceil(sqrt(2^snrB)), [1 length(c)/64],'uint16')+2^snrB)];
ivs.fast           = [ivs.fast           c+randn(size(c))*2/double(snrB)>.5];
ivs.xy             = [ivs.xy             repmat([1;3],1,length(c)/64)];
flag_ld_on         = [flag_ld_on         ones(1,length(c)/64,'uint8')];
flag_tx_code_start = [flag_tx_code_start 1 zeros(1,length(c)/64-1,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,length(c)/64,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,length(c)/64,'uint8')];
%8. BACKUP(B)

%9.ld_on deassert
ivs.slow           = [ivs.slow           zeros(1,nDeassertPackets,'uint16')];
ivs.fast           = [ivs.fast           false(1,nDeassertPackets*64)];
ivs.xy             = [ivs.xy             repmat([1;1],1,nDeassertPackets)];
flag_ld_on         = [flag_ld_on         zeros(1,nDeassertPackets,'uint8')];
flag_tx_code_start = [flag_tx_code_start zeros(1,nDeassertPackets,'uint8')];
flag_scandir       = [flag_scandir       zeros(1,nDeassertPackets,'uint8')];
flag_txrx_mode     = [flag_txrx_mode     txrxMode*ones(1,nDeassertPackets,'uint8')];

%{
    subplot(6,1,1)
    plot((0:length(ivs.fast)-1)/64,ivs.fast);
    title('Fast');axis tight
    subplot(6,1,2)
    plot((0:length(ivs.slow)-1),ivs.slow);
    title('Slow');axis tight
    subplot(6,1,3)
    plot((0:length(ivs.slow)-1),ivs.xy(1,:));
    title('x');axis tight
    subplot(6,1,4)
    plot((0:length(ivs.slow)-1),ivs.xy(2,:));
    title('y');axis tight
    
    subplot(6,1,5)
    plot((0:length(ivs.slow)-1),flag_ld_on);
    title('ld\_on');axis tight
    subplot(6,1,6)
    stem((0:length(ivs.slow)-1),flag_tx_code_start,'.');
    title('tx\_code\_start');axis tight
%}
end


function imgot=imresize_(imgin,szot)
szin = size(imgin);
[yin,xin]=ndgrid(linspace(0,1,szin(1)),linspace(0,1,szin(2)));
[yot,xot]=ndgrid(linspace(0,1,szot(1)),linspace(0,1,szot(2)));
imgot=interp2(xin,yin,imgin,xot,yot,'nearest'); %tmund - nearest neighbor method seems better for learning depth across the edges.  
end


function mm=metaMM(m)
v=[];
if(~isempty(m.rangeStruct.fromTo))
    v=[v [m.rangeStruct.fromTo.val0] [m.rangeStruct.fromTo.val1]];
end
if(~isempty(m.rangeStruct.scalar))
    v=[v [m.rangeStruct.scalar.val]];
end
mm=minmax(v);
end

% function isCovered = isROICovered(regs,luts)
% % if regs.CBUF.bypass
% %     isCovered = 1;
% %     return;
% % end
% roiH = double(regs.GNRL.imgVsize);
% roiB = double(regs.FRMW.marginB);
% roiT = roiB + roiH;
% angy = [-1 -1 -1 1 1 1] * 2047;
% angx = [-1 0 1 -1 0 1] * 2047;
% 
% [xA,yA]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
% [xA,yA] = Pipe.DIGG.undist(xA,yA,regs,luts,Logger(),[]);  
% dn = @(x) bitshift(x+2^(double(regs.DIGG.bitshift)-1),-double(regs.DIGG.bitshift));
% %xA = dn(xA);
% yA = dn(yA);
% 
% if regs.FRMW.yflip
%   yA = [yA(4:6) yA(1:3)];
% end
% isCovered =  ~any(yA(1:3)>roiB | yA(4:6)<roiT);
% 
% end