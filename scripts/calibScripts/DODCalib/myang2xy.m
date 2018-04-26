function [xF,yF,oXYZ] = myang2xy(angxQin,angyQin,regs,useFix)

%% ----STAIGHT FORWARD------

angXfactor = single(regs.FRMW.xfov*0.25/(2^11-1));
angYfactor = single(regs.FRMW.yfov*0.25/(2^11-1));
mirang = atand(regs.FRMW.projectionYshear);
rotmat = [cosd(mirang) sind(mirang);-sind(mirang) cosd(mirang)];
if ~useFix
    angles2xyz = @(angx,angy) [             sind(angx) cosd(angx).*sind(angy) cosd(angy).*cosd(angx)]';
else
    angles2xyz = @(angx,angy) [ cosd(angy).*sind(angx)             sind(angy) cosd(angy).*cosd(angx)]';
end
marginB = regs.FRMW.marginB;
marginT = regs.FRMW.marginT;
marginR = regs.FRMW.marginR;
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

angyQ=angyQin(:);angxQ =angxQin(:);
angx = single(angxQ)*angXfactor;
angy = single(angyQ)*angYfactor;
xy00 = [rangeL;rangeB];
xys = [xresN-1;yresN-1]./[rangeR-rangeL;rangeT-rangeB];
oXYZ = oXYZfunc(angles2xyz(angx,angy));
xynrm = [xyz2nrmx(oXYZ);xyz2nrmy(oXYZ)];
xynrm = rotmat*xynrm;
xy = bsxfun(@minus,xynrm,xy00);
xy    = bsxfun(@times,xy,xys);
xy = bsxfun(@minus,xy,double([marginL+int16(gaurdXinc);marginT+int16(gaurdYinc)]));
% plot(xy(1,:),xy(2,:));
% rectangle('position',[0 0 double(regs.GNRL.imgHsize) double(regs.GNRL.imgVsize)])
xF = reshape(xy(1,:),size(angxQin));
yF = reshape(xy(2,:),size(angyQin));
end
%% 

%
%SYMBOLIC CALC OF XY
%{
syms rangeRS rangeLS rangeTS rangeBS res_DIGG_resV res_DIGG_resH csx snx csy sny res_DIGG_laserangleH res_DIGG_laserangleV res_DIGG_projectionYshear res_DIGG_marginL res_DIGG_marginT
mirangS = atan(res_DIGG_projectionYshear);
rotmatS = [cos(mirangS) sin(mirangS);-sin(mirangS) cos(mirangS)];
angles2xyzS = @(angx,angy) [ sin(angx) cos(angx).*sin(angy) cos(angx).*cos(angy)].';
laserIncidentDirectionS = angles2xyzS( res_DIGG_laserangleH, (res_DIGG_laserangleV+pi));
oXYZfuncS = @(mirNormalXYZ_)  laserIncidentDirectionS-2*(laserIncidentDirectionS.'*mirNormalXYZ_)*mirNormalXYZ_;
xyz2nrmxS = @(xyz) xyz(1)./xyz(3);
xyz2nrmyS = @(xyz) xyz(2)./xyz(3);
xy00S = [rangeLS;rangeBS];
xysS = [res_DIGG_resH;res_DIGG_resV]./[rangeRS-rangeLS;rangeTS-rangeBS];
oXYZS = oXYZfuncS([ snx csx*sny csx*csy].');
xynrmS = [xyz2nrmxS(oXYZS);xyz2nrmyS(oXYZS)];
xynrmS = rotmatS*xynrmS;
xyS = (xynrmS-xy00S).*xysS-[res_DIGG_marginL;res_DIGG_marginT];
% xyS=(simplify(xyS, 'Criterion','preferReal', 'IgnoreAnalyticConstraints', true, 'Steps', 100));
xyS =expand(xyS, 'IgnoreAnalyticConstraints', true,'ArithmeticOnly',true);
ccode(collect(xyS,[snx sny csx csy]));
%}


function val = triFuncIntrp(ii,inverseTable)
 N_LUT_BIN = 2^7;
% x = vec(linspace(0,90,N_LUT_BIN));
% triLUT_HARDCODED = single(sind(x));
triLUT_HARDCODED = typecast(uint32(hex2dec({'00000000','3C4AA3D2','3CCA9FDB','3D17F2EE','3D4A8FFC','3D7D251B','3D97D828','3DB117D0','3DCA5089','3DE38155','3DFCA939','3E0AE39B','3E176D2A','3E23F0CB','3E306E00','3E3CE44C','3E495333','3E55BA37','3E6218DC','3E6E6EA7','3E7ABB1B','3E837EDF','3E899B0A','3E8FB1D1','3E95C2F8','3E9BCE42','3EA1D371','3EA7D24A','3EADCA90','3EB3BC08','3EB9A677','3EBF899F','3EC56548','3ECB3936','3ED1052E','3ED6C8F7','3EDC8456','3EE23713','3EE7E0F3','3EED81BF','3EF3193E','3EF8A738','3EFE2B75','3F01D2DF','3F048AED','3F073DCB','3F09EB5D','3F0C9389','3F0F3633','3F11D341','3F146A99','3F16FC22','3F1987C0','3F1C0D5C','3F1E8CDA','3F210624','3F23791F','3F25E5B3','3F284BC8','3F2AAB45','3F2D0414','3F2F561C','3F31A146','3F33E57B','3F3622A5','3F3858AD','3F3A877D','3F3CAEFE','3F3ECF1C','3F40E7C1','3F42F8D8','3F45024C','3F47040A','3F48FDFB','3F4AF00E','3F4CDA2F','3F4EBC49','3F50964B','3F526822','3F5431BB','3F55F305','3F57ABEE','3F595C65','3F5B0459','3F5CA3B9','3F5E3A74','3F5FC87C','3F614DC1','3F62CA32','3F643DC2','3F65A862','3F670A03','3F686298','3F69B213','3F6AF867','3F6C3588','3F6D6968','3F6E93FD','3F6FB539','3F70CD12','3F71DB7D','3F72E06F','3F73DBDF','3F74CDC1','3F75B60D','3F7694BA','3F7769BF','3F783513','3F78F6AF','3F79AE8B','3F7A5CA0','3F7B00E6','3F7B9B59','3F7C2BF1','3F7CB2A8','3F7D2F7A','3F7DA262','3F7E0B5B','3F7E6A61','3F7EBF71','3F7F0A86','3F7F4B9F','3F7F82B8','3F7FAFD0','3F7FD2E4','3F7FEBF3','3F7FFAFD','3F800000'})),'single');
if(inverseTable)
    triLUT_HARDCODED = flipud(triLUT_HARDCODED);
end
sz = size(ii);
ii = ii(:);
i0 = max(floor(ii),0); % the index round down
i1 = min(i0+1,N_LUT_BIN-1); % the index rounded up
y0 = triLUT_HARDCODED(i0+1); % LUT value of index i0
y1 = triLUT_HARDCODED(i1+1); % LUT value of index i1
val=(y1-y0).*(ii-i0)+y0; %weighted mean of the input (linear interp)
val = reshape(val,sz);
end