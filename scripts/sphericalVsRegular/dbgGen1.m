fw = Pipe.loadFirmware('C:\temp\unitCalib\F8480012\PC27\AlgoInternal');
[regs,luts] = fw.get();
load('framesRegAndSpherical.mat');
framesSpherical = spherical;
figure,tabplot; imagesc(frames.i);tabplot; imagesc(framesSpherical.i);



targetInfo = targetInfoGenerator('Iv2A1');
targetInfo.cornersX = 20;
targetInfo.cornersY = 28;
%% For the regular frame, compare eGeom with calibDFZ 

pts = CBTools.findCheckerboardFullMatrix(frames.i, 1);
regs.DEST.depthAsRange=0;regs.DIGG.sphericalEn=0;
[rptRegular,frames.r,frames.sing,frames.verts] = mySamplePointsRtd(frames.z,pts,regs);

frames.pts3d = create3DCorners(targetInfo)';
frames.rpt = rptRegular;
rptRegular = reshape(rptRegular,[20,28,3]);
rtd = rptRegular(:,:,1);
cols = find(sum(~isnan(rtd),1)); 
rows = find(sum(~isnan(rtd),2)); 
rpt = rptRegular*nan;
rpt(rows(2:end-1),cols(2:end-1),1) = rptRegular(rows(2:end-1),cols(2:end-1),1);
rpt(rows(2:end-1),cols(2:end-1),2) = rptRegular(rows(2:end-1),cols(2:end-1),2);
rpt(rows(2:end-1),cols(2:end-1),3) = rptRegular(rows(2:end-1),cols(2:end-1),3);
frames.rpt = reshape(rpt,[20*28,3]);

calibParams = xml2structWrapper('calibParams.xml');

frames.pts = pts;
frames.grid = [size(pts,1),size(pts,2),1];
[~,dfzRes,frames] = calibDFZ(frames,regs,calibParams,@sprintf,0,1);


%% For the spherical frame, compare eGeom with calibDFZ 

pts = CBTools.findCheckerboardFullMatrix(framesSpherical.i, 1);
regs.DEST.depthAsRange=1;regs.DIGG.sphericalEn=1;
[rptSpherical,framesSpherical.r,framesSpherical.sing] = mySamplePointsRtd(framesSpherical.z,pts,regs);
rptSpherical = reshape(rptSpherical,[20,28,3]);
rtd = rptSpherical(:,:,1);
cols = find(sum(~isnan(rtd),1)); 
rows = find(sum(~isnan(rtd),2)); 
rpt = rptSpherical*nan;
rpt(rows(2:end-1),cols(2:end-1),1) = rptSpherical(rows(2:end-1),cols(2:end-1),1);
rpt(rows(2:end-1),cols(2:end-1),2) = rptSpherical(rows(2:end-1),cols(2:end-1),2);
rpt(rows(2:end-1),cols(2:end-1),3) = rptSpherical(rows(2:end-1),cols(2:end-1),3);

framesSpherical.pts3d = create3DCorners(targetInfo)';
framesSpherical.rpt = reshape(rpt,[20*28,3]);
framesSpherical.rpt(isnan(frames.rpt)) = nan;
framesSpherical.rpt(:,1) = frames.rpt(:,1);
% framesSpherical.rpt(:,2) = frames.rpt(:,2);
% framesSpherical.rpt(:,3) = frames.rpt(:,3);

framesSpherical.pts = pts;
framesSpherical.grid = [size(pts,1),size(pts,2),1];
[~,dfzResSp,framesSpherical] = calibDFZ(framesSpherical,regs,calibParams,@sprintf,0,1);

figure,
for i = 1:3
tabplot;
imagesc(rptRegular(:,:,i)-rptSpherical(:,:,i)); colorbar;
end


tabplot
imagesc(reshape(frames.r,[20,28])-reshape(framesSpherical.r,[20,28])); colorbar;

figure,
histogram(rptRegular(:,:,1)-rptSpherical(:,:,1))
% 
% vxyDfz = reshape(frames.vCalibDfz,[20,28,3]);
% vspDfz = reshape(framesSpherical.vCalibDfz,[20,28,3]);
% 
% figure,
% for i = 1:3
% tabplot
% imagesc(vxyDfz(:,:,i)-vspDfz(:,:,i)); colorbar;
% end
% % 

figure, imagesc(frames.i);
hold on;
vec = @(x) reshape(x(~isnan(x)),[],1);
scatter(vec(frames.pts(:,:,1)),vec(frames.pts(:,:,2)),10*(vec(rptRegular(:,:,1)-rptSpherical(:,:,1))+1.5),'filled')
% % Remarks - interdist is the same as geometric error in dfz. 
% 
% 
% % Compare rtd for points - Identical!
% frames.rtdVal = reshape(dbg.r + sqrt(sum((dbg.v - [0,10,0]).^2,2)),[12,21]);
% frames.rtdCal = reshape(frames.rpt(:,1),[20,28]);
% figure,subplot(121), imagesc(frames.rtdCal-regs.DEST.txFRQpd(1)),subplot(122), imagesc(frames.rtdVal);
% 
% %
% [x,y] = Pipe.DIGG.ang2xy(frames.rpt(:,2),frames.rpt(:,3),regs,[],[]);
% [xt,yt] = Pipe.DIGG.undist(x,y,regs,luts,[],[] );
% figure, imagesc(frames.i); hold on;plot(double(xt)/2^15+0.5,double(yt)/2^15+0.5,'r*')