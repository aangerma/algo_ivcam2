function [regsOut,lutsOut] = findOpticalSetupParam(ivs,fw)


BASE_SIZE = 640;
fwc=copy(fw);
rxpropregs.DEST.rxPWRpd=zeros(1,65,'single');
setregs.DEST.rxPWRpd=rxpropregs.DEST.rxPWRpd;
setregs.FRMW.destRxpdGen = single([0 0 0]);
setregs.FRMW.destTxpdGen = single([0 0 0]);
setregs.FRMW.xres = uint16(BASE_SIZE);
setregs.FRMW.yres = uint16(BASE_SIZE);
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
setregs.DIGG.sphericalEn = true;

fwc.setRegs(setregs,[]);

[regs,~]=fwc.get();




%%

% regs.MTLB.fastChDelay=regs.MTLB.fastChDelay+22

[glohi]=round(prctile(double(ivs.slow(ivs.slow~=0)),[1 99]));
glohi=round(glohi.*[.8 1.2]);%add 20% margin;

multFact = 2^12/diff(glohi);
if(multFact>4)
    error('IR dynamci range of input image is too low(min=%d,max=%d)',glohi);
end

gammaRegs.DIGG.gammaScale=bitshift(int16([round(multFact) 1]),10);
gammaRegs.DIGG.gammaShift=int16([-round(glohi(1)*multFact) 0]);
fwc.setRegs(gammaRegs,[]);

%



% 
% [regs,luts]=fwc.get();
% pout = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
% 
% [p,bsz] = detectCheckerboardPoints(pout.iImgRAW);
% [yg,xg]=ndgrid(1:BASE_SIZE);
% rtd = interp2(xg,yg,pout.rtdImg,p(:,1),p(:,2));
% c = interp2(xg,yg,double(pout.iImgRAW),p(:,1),p(:,2));
% raw= reshape([p/BASE_SIZE*2-1  rtd c],bsz(1)-1,bsz(2)-1,4);
% 






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


xbest = [55 50 8000 -1 1];

xL = [40   40    8000  -3  -3 ];
xH = [70   56    8700   3   3 ];
warning('off','vision:calibrate:boardShouldBeAsymmetric');
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
warning('off','pipe:RAST');


runPipe = @(r,l) longPipe(ivs,r,l);

err=[];
THR=0.1;
fvalPre = inf;

fminSearchOpt=struct('tolx',inf,'TolFun',THR,'OutputFcn',[],'MaxIter',25);

% [xbest(1:3),fval]=fminsearchbnd(@(x) p2e(raw2xyzc(x,regs.DEST.baseline,raw),false),xbest(1:3),xL(1:3),xH(1:3),struct('Display','iter','OutputFcn',[]));

for i=1:3
       figure(1);
    ah=arrayfun(@(i) subplot(2,2,i),1:4,'uni',false);ah=[ah{:}];
    %% fov+delay
    [xbest(1:3),fval]=fminsearchbnd(@(x) errFunc(x,fwc,runPipe,false),xbest(1:3),xL(1:3),xH(1:3),fminSearchOpt);
    newregs = th2regs(xbest(1:3));
    fwc.setRegs(newregs,[]);
    %% laser angles
    [xbest(4:5),fval]=fminsearchbnd(@(x) errFunc(x,fwc,runPipe,false),xbest(4:5),xL(4:5),xH(4:5),fminSearchOpt);
    newregs = th2regs(xbest(4:5));
    fwc.setRegs(newregs,[]);

    err(i)=fval;
    
    %%
 
    
    
    %% UNDISTORT
    
    [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
    %find distortion
    xyzm = reshape(dataOut.xyzmes(:,:,1:3),[],3)';
    xyzo = reshape(dataOut.xyzopt(:,:,1:3),[],3)';
    uvmes=(dataOut.kMat(1:2,:)*xyzm./(dataOut.kMat(3,:)*xyzm)+1)*0.5.*size(dataOut.iImg)';
    uvopt=(dataOut.kMat(1:2,:)*xyzo./(dataOut.kMat(3,:)*xyzo)+1)*0.5.*size(dataOut.iImg)';
    
        [udyg,udxg]=ndgrid(linspace(-1,1,32));
    uverr = uvopt-uvmes;
    tps=TPS(uvmes',uverr');
    undist=tps.at([udyg(:) udxg(:)]);
    undistx=reshape(undist(:,1),size(udxg));
    undisty=reshape(undist(:,2),size(udxg));

    oo = ones(numel(udxg),1);
    %remove scale
    undistx=undistx-reshape([vec(udxg) oo]*([vec(udxg) oo]\vec(undistx)),32,32);
    undisty=undisty-reshape([vec(udyg) oo]*([vec(udyg) oo]\vec(undisty)),32,32);
    
    
%     interError=max([interp2(xg,yg,undistx,uvmes(1,:),uvmes(2,:))+uvmes(1,:)-uvopt(1,:) interp2(xg,yg,undisty,uvmes(1,:),uvmes(2,:))+uvmes(2,:)-uvopt(2,:)]);
    
    
    undistx_ = undistx_+undistx;
    undisty_ = undisty_+undisty;
    %find optical params
    undistLuts.FRMW.xLensModel=typecast(single(vec(undistx_)'/single(regs.GNRL.imgHsize)),'uint32');
    undistLuts.FRMW.yLensModel=typecast(single(vec(undisty_)'/single(regs.GNRL.imgVsize)),'uint32');
    fwc.setLut(undistLuts);
    rmserr = rms([undistx(:);undisty(:)]);
    quiver(udxg,udyg,undistx,undisty,'parent',ah(2))
    title(sprintf('distortion(%f)',rmserr),'parent',ah(2))
    grid(ah(2),'on');
    axis(ah(2),'equal');
    drawnow;
    
    %% RX DELAY
    
    rmserrPre=inf;
    rxpropregs.DEST.rxPWRpd=zeros(1,65,'single');
    

    while(true )
        fwc.setRegs(rxpropregs,[]);
        [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
            
            [mdl,d,in]=planeFit(dataOut.xyzmes(:,:,1),dataOut.xyzmes(:,:,2),dataOut.xyzmes(:,:,3),[],200);
            p=conv2(dataOut.imgPts,ones(2)/4,'valid');
            [yg,xg]=ndgrid(1:size(dataOut.rawout,1),1:size(dataOut.rawout,2));
            cptsxyz=...
            cat(3,interp2(xg,yg,dataOut.rawout(:,:,1),real(p),imag(p)),...
                  interp2(xg,yg,dataOut.rawout(:,:,2),real(p),imag(p)),...
                  interp2(xg,yg,dataOut.rawout(:,:,3),real(p),imag(p)));
             cptsc=interp2(xg,yg,dataOut.rawout(:,:,4),real(p),imag(p));
             cptsxyz = reshape(cptsxyz,[],3);
             mm=mdl(1:3)*mdl(1:3)';
             
             cptsxyzP=cptsxyz*(eye(3)-mm)+(mm*[0;0;mdl(4)])';
             e = sqrt(sum((cptsxyzP-cptsxyz).^2,2));
             m = generateLSH(cptsc(:),2)\e;
             rxc=linspace(0,4095,65)';
             lut = generateLSH(rxc,2)*m;
            plot(cptsc(:),e,'.',rxc,lut,'parent',ah(3))
            drawnow;
            

        rxpropregs.DEST.rxPWRpd=rxpropregs.DEST.rxPWRpd-single(lut(:)'/2^10);
        
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
  [~,dataOut] = errFunc(xbest,fwc,longPipe,ah(1));
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

function xyzmes=raw2xyzc(p,bl,raw)
angx=raw(:,:,1).*p(1)*pi/180;
angy=raw(:,:,2).*p(2)*pi/180;
rtd =raw(:,:,3)-p(3);


tanx = tan(angx);
sinx = sin(angx);
cosx = cos(angx);
cosy = cos(angy);
sing=sin(atan(tanx.*cosy));
cosw=cos(atan(tan(angy)./sqrt(1+tanx.^2)));
sinw=sin(atan(tan(angy)./sqrt(1+tanx.^2)));
r= (0.5*(rtd.^2 - bl^2))./(rtd - bl.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
xyzmes=cat(3,x,y,z,raw(:,:,4));
end

function [e,ptsOut]=p2e(p,verbose)
%%
tileSizeMM = 30;
h=size(p,1);
w=size(p,2);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';
xyzmes =reshape(p,[],4)';
xyzmes=xyzmes(1:3,:);


    %find best plane
    [mdl,d,in]=planeFit(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),[],200);
    if(nnz(in)/numel(in)<.90)
        e=1e3;
        ptsOut=xyzmes;
        return;
    end
    pvc=xyzmes-mean(xyzmes(:,in),2);
%     
    %project all point to plane
    pvp=pvc(:,in)-mdl(1:3).*d(:,in);
    
    pvp=pvp-mean(pvp,2);
    %shift to center, find rotation along PCA
    [u,~,vt]=svd(pvp*ptsOpt(:,in)');
    rotmat=u*vt';
    
    ptsOptR = rotmat*ptsOpt;
    
    errVec = vec(sqrt((sum((pvc-ptsOptR).^2))));
    if(exist('verbose','var') && verbose)
   
    plot3(pvc(1,in),pvc(2,in),pvc(3,in),'go',pvc(1,~in),pvc(2,~in),pvc(3,~in),'Ro',ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),'b+')
%     quiver3(ptsOptR(1,in),ptsOptR(2,in),ptsOptR(3,in),xyzmes(1,in)-ptsOptR(1,in),xyzmes(2,in)-ptsOptR(2,in),xyzmes(3,in)-ptsOptR(3,in),0)
%     plotPlane(mdl);
%     plot3(xyzmes(1,:),xyzmes(2,:),xyzmes(3,:),'ro',ptsOptR(1,:),ptsOptR(2,:),ptsOptR(3,:),'g.');
    end

 e = sqrt((mean(errVec(in).^2)));
%  e=prctile(errVec,85);
ptsOut = reshape(ptsOptR'+mean(xyzmes(:,in),2)',size(p,1),size(p,2),3);
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
function [err,dataOut] = errFunc(X,fw,runPipe,axesH)
lookAtCenters=false;
doRadialAveraging = false;
fwc = copy(fw);
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
if(lookAtCenters)
    p=(p(1:end-1,1:end-1)+p(1:end-1,2:end)+p(2:end,1:1:end-1)+p(2:end,2:end))/4;
end
if(doRadialAveraging)
    stepSz=min(mean(vec(diff(real(p),[],2))),mean(vec(diff(imag(p)))));
    r = max(stepSz/4,1);
else
    r=1;
end
[yg,xg]=ndgrid(1:double(regs.GNRL.imgVsize),1:double(regs.GNRL.imgHsize));

inp=vec(xg)+1j*vec(yg);
insample=arrayfun(@(x) abs(x-inp)<r,p,'uni',false);
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
qn = (real(p)/w*2-1)+1j*(imag(p)/h*2-1);
fpx=[vec(x)./vec(z) ones(numel(x),1)]\real(qn(:));
fpy=[vec(y)./vec(z) ones(numel(y),1)]\imag(qn(:));
%     fitErr=norm([vec(x)./vec(z) ones(numel(x),1)]*fpx-real(qn(:)))+norm([vec(y)./vec(z) ones(numel(x),1)]*fpy-imag(qn(:)));
dataOut.kMat = [fpx(1) 0 fpx(2);0 fpy(1) fpy(2); 0 0 1];


dataOut.xyzmes=reshape(xyzcAv',size(p,1),size(p,2),[]);%[x(:) y(:) z(:)]';
dataOut.colData = c(:);
dataOut.iImg = iImg;
dataOut.imgPts = p;


[dataOut.err,dataOut.xyzopt]=p2e(dataOut.xyzmes);


if(exist('axesH','var') && ishandle(axesH))
    plot3(vec(dataOut.xyzmes(:,:,1)),vec(dataOut.xyzmes(:,:,2)),vec(dataOut.xyzmes(:,:,3)),'ro',dataOut.xyzopt(:,:,1),dataOut.xyzopt(:,:,2),dataOut.xyzopt(:,:,3),'go','parent',axesH);
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

