function [regsOut,lutsOut] = findOpticalSetupParam(ivs,fw)


BASE_SIZE = 640;
fwc=copy(fw);

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
setregs.DIGG.sphericalEn = false;
% setregs.FRMW.marginL=int16(0);
% setregs.FRMW.marginR=int16(0);
% setregs.FRMW.marginT=int16(0);
% setregs.FRMW.marginB=int16(0);
fwc.setRegs(setregs,[]);

[regs,~]=fwc.get();




%%

% regs.MTLB.fastChDelay=regs.MTLB.fastChDelay+22

[glohi]=round(prctile(double(ivs.slow(ivs.slow~=0)),[1 99]));
glohi=round(glohi.*[.8 1.5]);%add  margin;

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

undistx_=zeros(32);
undisty_=zeros(32);
undistLuts.FRMW.undistModel=zeros(2048,1,'uint32');

fwc.setLut(undistLuts);
%%
rxpropregs.DEST.rxPWRpd=zeros(1,65,'single');
fwc.setRegs(rxpropregs,[]);
%%

%{
 xbest=[44.6380387897461 45.4856448651313 7181.74673062551 -0.528033888844045 0.381634554288861]
xbest =  [47.3482686908418 47.5213992906887 7311.55601853396 0.534818968265146 1.43425961018034];
%}


xbest = [55 50 8000 -1 1];

xL = [40   40    7000  -3  -3 ];
xH = [70   56    9000   3   3 ];
warning('off','vision:calibrate:boardShouldBeAsymmetric');
warning('off','MATLAB:scatteredInterpolant:DupPtsAvValuesWarnId');
warning('off','pipe:RAST');


runPipe = @(r,l) longPipe(ivs,r,l);

err=[];
THR=0.1;
fvalPre = inf;

fminSearchOpt=struct('tolx',inf,'TolFun',THR,'OutputFcn',[],'MaxIter',30);

% [xbest(1:3),fval]=fminsearchbnd(@(x) p2e(raw2xyzc(x,regs.DEST.baseline,raw),false),xbest(1:3),xL(1:3),xH(1:3),struct('Display','iter','OutputFcn',[]));
figure(1);
ah=arrayfun(@(i) subplot(2,2,i),1:4,'uni',false);ah=[ah{:}];
u322s=@(v) typecast(uint32(v),'single');
s2u32=@(v) typecast(single(v),'uint32');
for i=1:5
    %% fov+delay
    [xbest(1:3),~]=fminsearchbnd(@(x) errFunc(x,fwc,runPipe,false),xbest(1:3),xL(1:3),xH(1:3),fminSearchOpt);
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
       [~,s,d]=Calibration.aux.evalProjectiveDisotrtion(dataOut.iImg);
        wh=fliplr(size(dataOut.iImg));
        [~,undistx,undisty]=Calibration.aux.generateUndistTables(s,d,wh);
    %     quiver(s(:,1),s(:,2),d(:,1)-s(:,1),d(:,2)-s(:,2),'r');     hold on  ;   quiver(xg,yg,undistx,undisty,'g');     hold off
    
    
    %      %remove scale
    %       oo = ones(numel(udxg),1);
    %
    %       undistx=undistx-reshape([vec(udxg) oo]*([vec(udxg) oo]\vec(undistx)),32,32);
    %       undisty=undisty-reshape([vec(udyg) oo]*([vec(udyg) oo]\vec(undisty)),32,32);
    %
    undistx_ = undistx_+undistx;
    undisty_ = undisty_+undisty;
    
    %find optical params
    undistLuts.FRMW.undistModel=typecast(vec(single([undistx_(:) undisty_(:)])'./single([dataOut.regs.GNRL.imgHsize;dataOut.regs.GNRL.imgVsize])),'uint32');
    fwc.setLut(undistLuts);
    rmserr = rms([undistx(:);undisty(:)]);
    quiver(xg,yg,undistx_,undisty_,'parent',ah(2))
    title(sprintf('step distortion(%f)',rmserr),'parent',ah(2))
    grid(ah(2),'on');
    axis(ah(2),'equal');
    drawnow;
    
    %% RX DELAY
    
    
    
    rxx=linspace(0,4095,65);
    [~,dataOut] = errFunc(xbest,fwc,runPipe,ah(1));
    inordr = @(v) [v(1:2) v(4) v(3)];
    msk = poly2mask(inordr(real(dataOut.imgPts([1 end],[1 end]))),inordr(imag(dataOut.imgPts([1 end],[1 end]))),size(dataOut.iImg,1),size(dataOut.iImg,2));
    [mdl,d,in]=planeFitRansac(dataOut.rawout(:,:,1),dataOut.rawout(:,:,2),dataOut.rawout(:,:,3),msk,200);
    ii = dataOut.rawout(:,:,4);
    txdly=conv(accumarray(ii(msk)+1,d(msk),[4096 1],@median),fspecial('gaussian',[150 1],75),'same');
    lut = interp1(0:4095,txdly,rxx');
    rxpropregs.DEST.rxPWRpd=rxpropregs.DEST.rxPWRpd-single(lut(:)'/2^10);
    fwc.setRegs(rxpropregs,[]);
    plot(rxx,rxpropregs.DEST.rxPWRpd*2^10,rxx,rxpropregs.DEST.rxPWRpd*2^10+lut(:)','parent',ah(3))
    drawnow;
    title(sprintf('planefit error (%f) RX step fix(%f)',rms(d(msk)),rms(txdly)),'parent',ah(3))
    drawnow;
    
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

%% phase #2: TX delay
lutsOut=undistLuts;
regsOut = newregs;
save dbg3
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
lookAtCenters=true;
doRadialAveraging = true;
fwc = copy(fw);
newregs = th2regs(X);
fwc.setRegs(newregs,[]);


dataOut=struct();

[regs,luts]=fwc.get();
dataOut.regs=regs;
dataOut.luts=luts;
dataOut.rawout = runPipe(regs,luts);
w=double(regs.GNRL.imgHsize);
h=double(regs.GNRL.imgVsize);
pout =dataOut.rawout;
iImg=pout(:,:,4);

imgv=iImg(Utils.indx2col(size(iImg),[3 3]));
imgv(imgv==0)=nan;
imgv(5,isnan(imgv(5,:)))=nanmedian(imgv(:,isnan(imgv(5,:))));
iImg = normByMax(reshape(imgv(5,:),size(iImg)));
iImg = conv2(iImg,fspecial('gaussian',3,1),'same');
[p,bsz]=detectCheckerboardPoints(iImg);

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


[dataOut.err,dataOut.xyzopt]=Calibration.aux.evalGeometricDistortion(dataOut.xyzmes);


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



function [v,regs]=longPipe(ivs,regs,luts)
pout = Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
v=cat(3,double(pout.vImg),double(pout.iImgRAW));

end
