function [resStruct] = calibrationGridSearch(xL,xH,nFov,nDelay,nZ,hw)
%% Evaluate the geometric error on a  grid of values per each:
% Receives lower and upper bound for x:
% [fovX,fovY,delay,zenithX,zenithY]
% Creates a 5 dimensional grid. 
% nFov is number of fovs (per each axis)
% nDelay - number of delays.
% nZ number of Zenith values.

% Load the configuration file that was used to capture the frames %%
fw = hw.getFirmware();
[regs, luts] = fw.get();

d = Calibration.aux.readAvgFrame(hw,30);

%some filtering - remove NANS in the IR image(to make it easier to find
%checkerboard corners
im = double(d.i);
im(im==0)=nan;
N=3;
imv = im(Utils.indx2col(size(im),[N N]));
bd = vec(isnan(im));
im(bd)=nanmedian_(imv(:,bd));

%calc RTD 
[~,r] = Pipe.z16toVerts(d.z,regs);
[~,~,~,~,~,~,sing]=Pipe.DEST.getTrigo(size(r),regs);
C=r*regs.DEST.baseline.*sing- regs.DEST.baseline2;
rtd=r+sqrt(r.^2-C);
rtd=rtd+regs.DEST.txFRQpd(1);

%calc angles per pixel
[yg,xg]=ndgrid(0:size(rtd,1)-1,0:size(rtd,2)-1);
[angx,angy]=Pipe.CBUF.FRMW.xy2ang(xg,yg,regs);

%xy2ang verification
% [~,~,xF,yF]=Pipe.DIGG.ang2xy(angx,angy,regs,Logger(),[]);
% assert(max(vec(abs(xF-xg)))<0.1,'xy2ang invertion error')
% assert(max(vec(abs(yF-yg)))<0.1,'xy2ang invertion error')

%find CB points
[p,bsz] = detectCheckerboardPoints(normByMax(im)); % p - 3 checkerboard points. bsz - checkerboard dimensions.
it = @(k) interp2(xg,yg,k,reshape(p(:,1)-1,bsz-1),reshape(p(:,2)-1,bsz-1)); % Used to get depth and ir values at checkerboard locations.

%rtd,ohi,theta
rpt=cat(3,it(rtd),it(angx),it(angy)); % Convert coordinate system to angles instead of xy. Makes it easier to apply zenith optimization.

% Define optimization settings
%%

vFovX = linspace(xL(1),xH(1),nFov);
vFovY = linspace(xL(2),xH(2),nFov);
vDelay = linspace(xL(3),xH(3),nDelay);
vZX = linspace(xL(4),xH(4),nZ);
vZY = linspace(xL(5),xH(5),nZ);

[fovX,fovY,delay,zX,zY] = comb(vFovX,vFovY,vDelay,vZX,vZY);

eAlex = zeros(size(fovX));
eFit = zeros(size(fovX));

eAlexOpt = zeros(size(fovX));
eFitOpt = zeros(size(fovX));
inputX0 = [fovX,fovY,delay,zX,zY];
outputX = zeros(size(inputX0));

opt.maxIter=1000;
opt.OutputFcn=[];
opt.TolFun = 0.0025;
opt.TolX = 1e-2;
opt.Display='none';


for i = 1:numel(fovX)
    if mod(i,100) == 0 || i == 1 
       fprintf('Processing combination %d/%d.\n',i,numel(fovX)) 
    end
    x0 = double([fovX(i),fovY(i),delay(i),zX(i),zY(i)]);
    [eAlex(i),eFit(i)] = errFunc(rpt,regs,x0,0);
%     [outputX(i,:),~]=fminsearchbnd(@(x) errFunc(rpt,regs,x,0),x0,xL,xH,opt);
%     [eAlexOpt(i),eFitOpt(i)]=errFunc(rpt,x2regs(outputX(i,:),regs),outputX(i,:),0);
end


resStruct.eAlex = reshape(eAlex,nFov,nFov,nDelay,nZ,nZ);
resStruct.eFit = reshape(eFit,nFov,nFov,nDelay,nZ,nZ);
resStruct.fX = reshape(fovX,nFov,nFov,nDelay,nZ,nZ);
resStruct.fY = reshape(fovY,nFov,nFov,nDelay,nZ,nZ);
resStruct.delay = reshape(delay,nFov,nFov,nDelay,nZ,nZ);
resStruct.zX = reshape(zX,nFov,nFov,nDelay,nZ,nZ);
resStruct.zY = reshape(zY,nFov,nFov,nDelay,nZ,nZ);
resStruct.varsVecs = {vFovX,vFovY,vDelay,vZX,vZY};
resStruct.varsLength = {nFov,nFov,nDelay,nZ,nZ};

% resStruct.optim.eAlexOpt = eAlexOpt;
% resStruct.optim.eFitOpt = eFitOpt;
% resStruct.optim.inputX0 = inputX0;
% resStruct.optim.outputX = outputX;
    

end
function varargout = comb(varargin)
   varargout = cell(1, nargout);
   [varargout{:}] = ndgrid(varargin{:});  %distribute to varargout
   varargout = cellfun(@(m) reshape(m, [], 1), varargout, 'UniformOutput', false); %reshape into columns
end


function [e,e_dist]=errFunc(rpt,rtlRegs,X,verbose)
%build registers array

rtlRegs = x2regs(X,rtlRegs);

[~,~,xF,yF]=Pipe.DIGG.ang2xy(rpt(:,:,2),rpt(:,:,3),rtlRegs,Logger(),[]);


rtd_=rpt(:,:,1)-rtlRegs.DEST.txFRQpd(1);


[sinx,cosx,~,cosy,sinw,cosw,sing]=Pipe.DEST.getTrigo(round(xF),round(yF),rtlRegs);

r= (0.5*(rtd_.^2 - rtlRegs.DEST.baseline2))./(rtd_ - rtlRegs.DEST.baseline.*sing);

z = r.*cosw.*cosx;
x = r.*cosy.*sinx;
y = r.*sinw;
v=cat(3,x,y,z);


[e,e_dist,~]=Calibration.aux.evalGeometricDistortion(v,verbose);

end
function rtlRegs = x2regs(x,rtlRegs)



iterRegs.FRMW.xfov=single(x(1));
iterRegs.FRMW.yfov=single(x(2));
iterRegs.FRMW.gaurdBandH=single(0);
iterRegs.FRMW.gaurdBandV=single(0);
iterRegs.FRMW.xres=rtlRegs.GNRL.imgHsize;
iterRegs.FRMW.yres=rtlRegs.GNRL.imgVsize;
iterRegs.FRMW.marginL=int16(0);
iterRegs.FRMW.marginT=int16(0);

iterRegs.FRMW.xoffset=single(0);
iterRegs.FRMW.yoffset=single(0);
iterRegs.FRMW.undistXfovFactor=single(1);
iterRegs.FRMW.undistYfovFactor=single(1);
iterRegs.DEST.txFRQpd=single([1 1 1]*x(3));
iterRegs.DIGG.undistBypass = false;
iterRegs.GNRL.rangeFinder=false;


iterRegs.FRMW.laserangleH=single(x(4));
iterRegs.FRMW.laserangleV=single(x(5));

rtlRegs =Firmware.mergeRegs( rtlRegs ,iterRegs);

trigoRegs = Pipe.DEST.FRMW.trigoCalcs(rtlRegs);
rtlRegs =Firmware.mergeRegs( rtlRegs ,trigoRegs);

diggRegs = Pipe.DIGG.FRMW.getAng2xyCoeffs(rtlRegs);
rtlRegs=Firmware.mergeRegs(rtlRegs,diggRegs);
end
