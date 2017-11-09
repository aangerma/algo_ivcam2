function [regs,autogenRegs,autogenLuts] = bootCalcs(regs,luts,autogenRegs,autogenLuts)
%% CBUF calcs

if(regs.GNRL.imgVsize>=721)
    MAX_BUFFER_SIZE=64;
elseif(regs.GNRL.imgVsize>=513)
    MAX_BUFFER_SIZE=85;
else
    MAX_BUFFER_SIZE=120;
end
MAX_BUFFER_SIZE = min(MAX_BUFFER_SIZE,double(regs.GNRL.imgHsize-1));
BUFFER_TOP_MARGIN=10;

MAX_BUFFER_SIZE = MAX_BUFFER_SIZE-BUFFER_TOP_MARGIN;
MIN_BUFFER_SIZE = 8;

autogenRegs.CBUF.xBitShifts =uint8(ceil(log2(double(regs.GNRL.imgHsize-1)))-4);
n =  bitshift(double(regs.GNRL.imgHsize-1),-int16(autogenRegs.CBUF.xBitShifts))+1;
assert(n<=16);
if(regs.FRMW.cbufConstLUT || regs.GNRL.rangeFinder)
    lutData = ones(1,n)*(MAX_BUFFER_SIZE);
else
    %%
    xcrossPix = bitshift((0:n-1),autogenRegs.CBUF.xBitShifts);
    [xcrossAngQ,~] = xy2ang(xcrossPix,ones(size(xcrossPix))*double(regs.GNRL.imgVsize)/2,regs);
    angStep = 8;
    [angyQ,angxQ] = ndgrid(int16(-2^11-1:angStep:2^11-1),xcrossAngQ);
    [~,~,x,y] = Pipe.DIGG.ang2xy(angxQ,angyQ,regs,Logger(),[]);
    x = reshape(x,size(angxQ));
    y = reshape(y,size(angyQ));
    
    roiMask = (y>=0 & y<regs.GNRL.imgVsize);
    x(~roiMask)=nan;

%     lutData = max(x.*(y>=0 & y<regs.GNRL.imgVsize))-min(x+((y<0 | y>regs.GNRL.imgVsize)*10000))+1+MIN_BUFFER_SIZE;
     lutData = max(ceil(nanmax(x)-nanmin(x)),MIN_BUFFER_SIZE);
     lutData = min(lutData,MAX_BUFFER_SIZE);
    
end
% lutData
autogenRegs.CBUF.xRelease = uint16(zeros(1,16));
autogenRegs.CBUF.xRelease(1:n) = uint16(round(lutData));
%
regs = Firmware.mergeRegs(regs,autogenRegs);

if(0)
    %%
    figure(111222);plot(xPixCross,lutData);
    
end
end


% function x=movmax_(v,n)
%
% i=max(1,min(bsxfun(@plus,1:length(v),(0:n)'),numel(v)));
% x=max(v(i));
%
% end

function [angx,angy] = xy2ang(x,y,regs)
angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
invrotmat = [cosd(mirang) -sind(mirang);sind(mirang) cosd(mirang)];
angles2xyz = @(angx,angy) [ sind(angx) cosd(angx).*sind(angy) cosd(angx).*cosd(angy)]';
marginT = regs.FRMW.marginT;
marginL = regs.FRMW.marginL;
xyz2nrmx = @(xyz) xyz(1,:)./xyz(3,:);
xyz2nrmy = @(xyz) xyz(2,:)./xyz(3,:);
xyz2nrmxy= @(xyz) [xyz2nrmx(xyz)  ;  xyz2nrmy(xyz)];
laserIncidentDirection = angles2xyz( regs.FRMW.laserangleH, regs.FRMW.laserangleV+180); %+180 because the vector direction is toward the mirror
oXYZfunc = @(mirNormalXYZ_)  bsxfun(@plus,laserIncidentDirection,-bsxfun(@times,2*laserIncidentDirection'*mirNormalXYZ_,mirNormalXYZ_));
rangeR = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz( regs.FRMW.xfov*0.25,                   0)));rangeR=rangeR(1);
rangeL = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(-regs.FRMW.xfov*0.25,                   0)));rangeL=rangeL(1);
rangeT = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   , regs.FRMW.yfov*0.25)));rangeT =rangeT (2);
rangeB = rotmat*rotmat*xyz2nrmxy(oXYZfunc(angles2xyz(0                   ,-regs.FRMW.yfov*0.25)));rangeB=rangeB(2);

gaurdXinc = regs.FRMW.gaurdBandH*single(regs.FRMW.xres);
gaurdYinc = regs.FRMW.gaurdBandV*single(regs.FRMW.yres);

xresN = single(regs.FRMW.xres) + gaurdXinc*2;
yresN = single(regs.FRMW.yres) + gaurdYinc*2;

xys = [xresN;yresN]./[rangeR-rangeL;rangeT-rangeB];
xy00 = [rangeL;rangeB];


xy = [x(:)+double(marginL+int16(gaurdXinc)) y(:)+double(marginT+int16(gaurdYinc))];
xy = bsxfun(@rdivide,xy,xys');
xy = bsxfun(@plus,xy,xy00');
xynrm = invrotmat*xy';


v = normr([xynrm' ones(size(xynrm,2),1)]);
n = normr(repmat(laserIncidentDirection',size(v,1),1) - v);
angxQ = asind(n(:,1));
angyQ = atand(n(:,2)./n(:,3));
angy = single(angyQ)/angYfactor;
angx = single(angxQ)/angXfactor;
end