function [regsOut,lutsOut] = findOpticalSetupParam(ivs,fw)



fwc=copy(fw);
rxpropregs.DEST.rxPWRpd=single([-0.0268449783325195 -0.0252129249274731 -0.0236396975815296 -0.0221243984997272 -0.0206661224365234 -0.0192639753222466 -0.0179170593619347 -0.0166244767606258 -0.0153853232041001 -0.0141987064853311 -0.013063726015389 -0.0119794821366668 -0.0109450798481703 -0.00995961762964725 -0.00902219861745834 -0.00813192408531904 -0.00728789530694485 -0.00648921262472868 -0.00573498057201505 -0.00502429902553558 -0.0043562687933445 -0.00383868534117937 -0.00340324896387756 -0.00299753248691559 -0.00262086745351553 -0.00227258633822203 -0.00195202091708779 -0.00165850203484297 -0.00139136239886284 -0.00114993331953883 -0.00093354657292366 -0.000741533935070038 -0.000573227414861321 -0.000427958555519581 -0.000305059365928173 -0.000203860923647881 -0.000123695936053991 -6.38952478766441e-05 -2.37911008298397e-05 -2.71573662757874e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]);
setregs.DEST.rxPWRpd=rxpropregs.DEST.rxPWRpd;
setregs.FRMW.destRxpdGen = single([0 0 0]);
setregs.FRMW.destTxpdGen = single([0 0 0]);
setregs.FRMW.xres = uint16(640);
setregs.FRMW.yres = uint16(640);
setregs.DIGG.undistBypass=false;


setregs.JFIL.bypass = false;
setregs.JFIL.bilt1bypass = true;
setregs.JFIL.bilt2bypass = true;
setregs.JFIL.bilt3bypass = true;
setregs.JFIL.biltIRbypass=true;
setregs.JFIL.dnnBypass=true;
setregs.JFIL.geomBypass=true;
setregs.JFIL.irShadingBypass=true;
setregs.JFIL.grad1bypass=true;
setregs.JFIL.grad2bypass=true;
setregs.JFIL.innBypass=true;
setregs.JFIL.invBypass=true;
setregs.JFIL.upscalexyBypass=true;
setregs.JFIL.gammaBypass=true;
setregs.JFIL.sort1Edge01=true;
setregs.JFIL.sort1Edge03=true;
setregs.JFIL.edge3bypassMode=uint8(1);

fwc.setRegs(setregs,[]);

[regs,~]=fwc.get();

shortpipe=false;



%%

% regs.MTLB.fastChDelay=regs.MTLB.fastChDelay+22

[glohi]=round(prctile(double(ivs.slow(ivs.slow~=0)),[1 100]));
glohi(2)=round(glohi(2)*1.2);%add 20% margin;
multFact = 2^12/diff(glohi);
if(multFact>4)
    error('IR dynamci range of input image is too low(min=%d,max=%d)',glohi);
end

gammaRegs.DIGG.gammaScale=bitshift(int16([round(multFact) 1]),10);
gammaRegs.DIGG.gammaShift=int16([-round(glohi(1)*multFact) 0]);
fwc.setRegs(gammaRegs,[]);

%










if(shortpipe)
k=vec(repmat(Utils.uint322bin(regs.FRMW.txCode,regs.GNRL.codeLength),1,regs.GNRL.sampleRate)');
nPcktsPerDepth = length(k)/64;
ivs2=ivs;
ivs2.fast = circshift(ivs2.fast,[0 regs.MTLB.fastChDelay*64]);
ivs2.slow = circshift(ivs2.slow,[0 regs.MTLB.slowChDelay]);
ivs2.flags= circshift(ivs2.flags,[0 regs.MTLB.fastChDelay]);
[cma,xy,ir]=Utils.ivsCodechunker(ivs2,nPcktsPerDepth*2);
cma = permute((mean(reshape(cma,[],2,size(cma,2)),2)),[1 3 2]);

cma = circshift(cma,[0 1]);

c=Utils.correlator(cma,k*2-1);
c=c*2/length(k);
%
ok=max(c)>.3;
c_=c(:,ok);
raw.xy=int16(round(xy(:,ok)));
raw.ir=ir(ok);
[raw.mxv,mxc]=max(c_);

    ind = sub2ind(size(c_),mod(mxc+(-1:1)'-1,size(c_,1))+1,(1:size(c_,2)).*[1;1;1]);
    cm=c_(ind);
    pk=(cm(1,:)-cm(3,:))./(cm(1,:)+cm(3,:)-2*cm(2,:))+mxc;
    raw.rtd=pk*double(regs.DEST.sampleDist(1));
    runPipe  = @(regs_,luts_) shortPipe (raw,regs_,luts_);
else
    runPipe  = @(regs_,luts_) longPipe (ivs,regs_,luts_);
end

% scatter3(xy_(1,:)/4,xy_(2,:),double(z)/8,10,ir_,'fill')
% errFunc1(xbest,fwc,runPipeF)


%% Phase #1: geometric distortion
[yg,xg]=ndgrid(linspace(1,double(regs.GNRL.imgVsize),32),linspace(1,double(regs.GNRL.imgHsize),32));
undistx_=zeros(32);
undisty_=zeros(32);
undistLuts.FRMW.xLensModel=typecast(single(vec(undistx_)'/double(regs.GNRL.imgHsize)),'uint32');
undistLuts.FRMW.yLensModel=typecast(single(vec(undisty_)'/double(regs.GNRL.imgVsize)),'uint32');
fwc.setLut(undistLuts);
%%

%{
 xbest=[44.6380387897461 45.4856448651313 7181.74673062551 -0.528033888844045 0.381634554288861]
xbest =  [47.3482686908418 47.5213992906887 7311.55601853396 0.534818968265146 1.43425961018034];
%}

% xbest =  [47.9713447686545 48.1857796574158 7294.39224926682 0.424012250712631 1.99813751250044];
xbest = [48.335197 51.458416 7436.094808 1.741173 0.912716 ];

xL = [40   40    6000  -3  -3 ];
xH = [70   56    8000   3   3 ];
warning('off','vision:calibrate:boardShouldBeAsymmetric');
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
warning('off','pipe:RAST');

err=[];
THR=0.1;
fvalPre = inf;

fminSearchOpt=struct('tolx',inf,'TolFun',THR,'OutputFcn',[],'MaxIter',15);
for i=1:3
    
    %% fov+delay
    [xbest(1:3),fval]=fminsearchbnd(@(x) errFunc(x,fwc,runPipe,false),xbest(1:3),xL(1:3),xH(1:3),fminSearchOpt);
    %% laser angles
    [xbest(4:5),fval]=fminsearchbnd(@(x) errFunc(x,fwc,runPipe,false),xbest(4:5),xL(4:5),xH(4:5),fminSearchOpt);
    err(i)=fval;
    
    %%
    figure(1);
    ah=arrayfun(@(i) subplot(2,2,i),1:4,'uni',false);ah=[ah{:}];
    
    
    %% UNDISTORT
    
    [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
    %find distortion
    uvmes=(dataOut.kMat(1:2,:)*dataOut.xyzmes./(dataOut.kMat(3,:)*dataOut.xyzmes)+1)*0.5.*size(dataOut.iImg)';
    uvopt=(dataOut.kMat(1:2,:)*dataOut.xyzopt./(dataOut.kMat(3,:)*dataOut.xyzopt)+1)*0.5.*size(dataOut.iImg)';
    uverr = uvopt-uvmes;
    tps=TPS(uvmes',uverr');
    undist=tps.at([xg(:) yg(:)]);
    undistx=reshape(undist(:,1),size(xg));
    undisty=reshape(undist(:,2),size(xg));
    
    interError=max([interp2(xg,yg,undistx,uvmes(1,:),uvmes(2,:))+uvmes(1,:)-uvopt(1,:) interp2(xg,yg,undisty,uvmes(1,:),uvmes(2,:))+uvmes(2,:)-uvopt(2,:)]);
    
    
    undistx_ = undistx_+undistx;
    undisty_ = undisty_+undisty;
    %find optical params
    undistLuts.FRMW.xLensModel=typecast(single(vec(undistx_)'/single(regs.GNRL.imgHsize)),'uint32');
    undistLuts.FRMW.yLensModel=typecast(single(vec(undisty_)'/single(regs.GNRL.imgVsize)),'uint32');
    fwc.setLut(undistLuts);
    rmserr = rms([undistx(:);undisty(:)]);
    quiverCmplx(uvmes(1,:)+1j*uvmes(2,:),uvopt(1,:)+1j*uvopt(2,:),'parent',ah(2))
    title(sprintf('distortion(%f)',rmserr),'parent',ah(2))
    grid(ah(2),'on');
    axis(ah(2),'equal');
    drawnow;
    
    %% RX DELAY
    
    rmserrPre=inf;
    
    while(true )
        [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
        %rx delay
        
        %     [h,w] = size(dataOut.imgPts);
        %     whiteInd = ((-1).^(1:h)'*(-1).^(1:w)>0);
        
        %     abc=(dataOut.xyzmes(1:3,whiteInd).*[1;1;0]+[0;0;1])'\dataOut.xyzmes(3,whiteInd)';
        %     e=(dataOut.xyzmes(1:3,:).*[1;1;0]+[0;0;1])'*abc-dataOut.xyzmes(3,:)';
        e=vec(dataOut.xyzopt(3,:)-dataOut.xyzmes(3,:));
        c = dataOut.colData;
        rxc=linspace(0,4095,65)';
        th=((c/4096*2-1).^[3 2 1 0])\e;
        f=((rxc/4096*2-1).^[3 2 1 0])*th;
        %f = interp1(c,e,rxc,'phichip',0);
        plot(c,e,'.',rxc,f,'parent',ah(3));
        %
        
        %
        %     drawnow;
        rxpropregs.DEST.rxPWRpd=-single(f(:)'/2^10)+rxpropregs.DEST.rxPWRpd;
        fwc.setRegs(rxpropregs,[]);
        rmserr = rms(e);
        title(sprintf('RX fix (%f)',rmserr),'parent',ah(3))
        drawnow;
        if(abs(rmserrPre-rmserr)<THR)
            break;
        end
        rmserrPre=rmserr;
    end
    %%
    if(abs(fvalPre-fval)<THR)
        break;
    end
    fvalPre=fval;
end
%%
newregs = th2regs(xbest);
newregs = Firmware.mergeRegs(newregs,rxpropregs);
newregs = Firmware.mergeRegs(newregs,gammaRegs);
newregs.DIGG.undistBypass = false;
fwc.setRegs(newregs,[]);
%{
  [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
regtxt=cellfun(@(X) cell2str(strcat(X,fieldnames(newregs.(X))),'|'),fieldnames(newregs),'uni',0);regtxt=cell2str(regtxt,'|');
fwc.disp(regtxt);
io.writeBin('FRMWxLensModel.bin32',undistLuts.FRMW.xLensModel);
io.writeBin('FRMWyLensModel.bin32',undistLuts.FRMW.yLensModel);
stlwriteMatrix('1.stl',dataOut.rawout(:,:,1),dataOut.rawout(:,:,2),dataOut.rawout(:,:,3),'color',dataOut.rawout(:,:,4))
%}

%% phase #2: TX delay
lutsOut=undistLuts;
regsOut = newregs;
save dbg3
end

function [e,ptsOptR]=p2e(xyzmes,h,w)
%%
tileSizeMM = 30;

[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';

whiteInd = ((-1).^(1:h)'*(-1).^(1:w)>0);
% %find best plane
% [mdl,d]=planeFit(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),whiteInd,2)
% %project point to best plane
% ptP=xyzmes-d.*mdl(1:3)-[0;0;mdl(4)];
% %PCA
% [v,l]=eig(ptP*ptP');
% ptPR=v(:,[3 2])'*ptP;

meanpv=mean(xyzmes,2);
ptsInzm=xyzmes-meanpv;
errVec = zeros(numel(whiteInd),1);
for i=1:1
    thr = prctile(errVec,75);
    inliers = whiteInd(:)&errVec<=thr;
    pvc=ptsInzm(:,inliers);
    %find best plane
    hMat=[ones(size(pvc,2),1) pvc' ];
    [c,n] = clsq(hMat,3);
    %project all point to plane
    pvp=pvc-n*([ones(size(pvc,2),1) pvc' ]*[c;n])';
    
    pvp=pvp-mean(pvp,2);
    %shift to center, find rotation along PCA
    [u,~,vt]=svd(pvp*ptsOpt(:,inliers)');
    rotmat=u*vt';
    
    ptsOptR = rotmat*ptsOpt;
    ptsOptR = ptsOptR+meanpv;
    errVec = vec(sqrt((sum((xyzmes-ptsOptR).^2))));
    %{
    plot3(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),'ro',ptsOptR(1,:),ptsOptR(2,:),ptsOptR(3,:),'g.');
    
    %}
end

 e = sqrt((mean(errVec(inliers).^2)));
%  e=prctile(errVec,85);

end


function newregs = th2regs(x)
n = length(x);
switch(n)
    case 3
        newregs.FRMW.xfov = single(x(1));
        newregs.FRMW.yfov = single(x(2));
        newregs.DEST.txFRQpd=single([1 1 1]*x(3));
    case 2
        newregs.FRMW.laserangleH = single(x(1));
        newregs.FRMW.laserangleV = single(x(2));
    case 5
        newregs.FRMW.xfov = single(x(1));
        newregs.FRMW.yfov = single(x(2));
        newregs.DEST.txFRQpd=single([1 1 1]*x(3));
        newregs.FRMW.laserangleH = single(x(4));
        newregs.FRMW.laserangleV = single(x(5));
        
end
end
function [err,dataOut] = errFunc(X,fwc,runPipe,axesH)

newregs = th2regs(X);
fwc.setRegs(newregs,[]);


dataOut=struct();

[regs,luts]=fwc.get();
dataOut.rawout = runPipe(regs,luts);
w=double(regs.GNRL.imgHsize);
h=double(regs.GNRL.imgVsize);
pout =dataOut.rawout;
iImg=pout(:,:,4);

to255 = @(x) uint8(x/max(x(:))*255);
[p,bsz]=detectCheckerboardPoints(to255(conv2(double(iImg),fspecial('gaussian',3,1))));
p=p-1;%????
if(~all(bsz==[10 14]))
    err=1e3;
return;
end
p=reshape(p(:,1)+1j*p(:,2),bsz-1);
if(mean(vec(diff(real(p),[],2)))<0)
    p=fliplr(p);
end
if(mean(vec(diff(imag(p))))<0)
    p=flipud(p);
end
stepSz=min(mean(vec(diff(real(p),[],2))),mean(vec(diff(imag(p)))));
r = max(stepSz/4,1);
[yg,xg]=ndgrid(1:double(regs.GNRL.imgVsize),1:double(regs.GNRL.imgHsize));
q=(p(1:end-1,1:end-1)+p(1:end-1,2:end)+p(2:end,1:1:end-1)+p(2:end,2:end))/4;

inp=vec(xg)+1j*vec(yg);
insample=arrayfun(@(x) abs(x-inp)<r,q,'uni',false);
insample=([insample{:}]);
insample=double(insample)./sum(insample);
pout(isnan(pout))=0;
xyzcAv=[vec(pout(:,:,1)) vec(pout(:,:,2)) vec(pout(:,:,3))  vec(pout(:,:,4))]'*insample;

%     sampleImg = @(qq,i) arrayfun(@(x) mean(double(vec(i( (xg-real(x)).^2+(yg-imag(x)).^2<r^2)))),qq);
%
%
%     x = sampleImg(q,pout.vImg(:,:,1));%interp2(xg,yg,pout.vImg(:,:,1),real(q),imag(q));
%     y = sampleImg(q,pout.vImg(:,:,2));%interp2(xg,yg,pout.vImg(:,:,2),real(q),imag(q));
%     z = sampleImg(q,pout.vImg(:,:,3));%interp2(xg,yg,pout.vImg(:,:,3),real(q),imag(q));
%     c = sampleImg(q,pout.iImgRAW    );%interp2(xg,yg,double(pout.iImgRAW),real(q),imag(q));

%orientation check

x=xyzcAv(1,:);
y=xyzcAv(2,:);
z=xyzcAv(3,:);
c=xyzcAv(4,:);
%find K
qn = (real(q)/w*2-1)+1j*(imag(q)/h*2-1);
fpx=[vec(x)./vec(z) ones(numel(x),1)]\real(qn(:));
fpy=[vec(y)./vec(z) ones(numel(y),1)]\imag(qn(:));
%     fitErr=norm([vec(x)./vec(z) ones(numel(x),1)]*fpx-real(qn(:)))+norm([vec(y)./vec(z) ones(numel(x),1)]*fpy-imag(qn(:)));
dataOut.kMat = [fpx(1) 0 fpx(2);0 fpy(1) fpy(2); 0 0 1];

dataOut.xyzmes=[x(:) y(:) z(:)]';
dataOut.colData = c(:);
dataOut.iImg = iImg;
dataOut.imgPts = q;


[dataOut.err,dataOut.xyzopt]=p2e(dataOut.xyzmes,bsz(1)-2,bsz(2)-2);

if(exist('axesH','var') && ishandle(axesH))
    plot3(vec(dataOut.xyzmes(1,:,:)),vec(dataOut.xyzmes(2,:,:)),vec(dataOut.xyzmes(3,:,:)),'ro',dataOut.xyzopt(1,:),dataOut.xyzopt(2,:),dataOut.xyzopt(3,:),'go','parent',axesH);
    hold(axesH,'on');
    quiver3(dataOut.xyzopt(1,:),dataOut.xyzopt(2,:),dataOut.xyzopt(3,:),dataOut.xyzmes(1,:)-dataOut.xyzopt(1,:),dataOut.xyzmes(2,:)-dataOut.xyzopt(2,:),dataOut.xyzmes(3,:)-dataOut.xyzopt(3,:),0,'parent',axesH);
    hold(axesH,'off');
    view(axesH,200,45)
    axis(axesH,'square');
    grid(axesH,'on');
    title(axesH,sprintf('err=%f',dataOut.err));
    
    
end


err=dataOut.err;
fprintf('err: %f\t\t',err);
fprintf('%f ',X);
fprintf('\n');



end



function v=longPipe(ivs,regs,luts)
pout = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
v=cat(3,double(pout.vImg),double(pout.iImgRAW));
end

function v=shortPipe(raw_,regs_,luts_)
indata.slow=raw_.ir;
indata.fast=[];
indata.flags=bitshift(uint8(gradient(double(raw_.xy(2,:)))>0),2);
indata.xy=raw_.xy;
[slow,xy] = Pipe.DIGG.DIGG( indata, regs_,luts_,Logger(),[]);
xy=double(xy)./[4;1];
slow=double(slow);
W = double(regs_.GNRL.imgHsize);
H = double(regs_.GNRL.imgVsize);
ind3x3=Utils.indx2col([H W],[5 5]);
xy = round(xy);
ok = all(xy<[W;H] & xy>=0);
ind = sub2ind([H W],xy(2,ok)+1,xy(1,ok)+1);
rtd = accumarray(vec(ind),vec(raw_.rtd(ok)),[H*W 1],@mean,nan);
ir  = accumarray(vec(ind),vec(slow(ok))    ,[H*W 1],@mean,nan);
ir=reshape(nanmedian(ir(ind3x3)),[H W]);
rtd=reshape(nanmedian(rtd(ind3x3)),[H W]);

z=double(Pipe.DEST.rtd2depth(Pipe.DEST.rtdDelays(rtd,regs_,ir,ones(size(ir))),regs_));

[sinx,cosx,~,~,sinw,cosw,~]=Pipe.DEST.getTrigo(size(z),regs_);


x = z.*double(sinx./cosx);
y = z.*double(sinw./(cosw.*cosx));

v = cat(4,x,y,z,ir);
end

