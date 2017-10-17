function ivlpiStruct = scopeData2ivs(data, tblXY,xyT,resI)




%     prmsFn = fullfile(baseDir,'pipeParams.xml');
% prmsFn = fullfile(baseDir,'scopeData2imageParams.xml');


%     if(exist(prmsFn,'file'))
%         prms = xml2structWrapper(prmsFn);
%     else
%         error('Reconstruction params file is missing');
%     end

% OUTPUT: constant xy resolution
w = 640*4; %prms.rasterizer.width;
h = 480*4; %prms.rasterizer.height;

fastF = round(1/data.Tfst*1e3)/1e3;

mirTicks = data.mirTicks;
tA = 0:xyT:(length(data.vfst)/fastF)-xyT;

tblXYc = tblXY(1:size(tblXY,1)/2,:);
tblXYc = bsxfun(@times,tblXYc,[w h]*resI./([640 480]*8));
clk = interp1(mirTicks,1:length(mirTicks),tA,'linear','extrap');
tblend = find(clk>size(tblXYc,1),1)-1;

xy=interp1(1:size(tblXYc,1),tblXYc,clk(1:tblend));
xy = int16(round(xy));


qSlow = max(min(data.vslw, 1), 0)*(2^12-1); % crop to [0,1] and scale to fit 12-bit
ivlpiStruct = struct;



ivlpiStruct.properties = struct('fastF',uint32(fastF*1e3),'slowT',uint32(data.Tslw*1e3),'templateT',uint32(data.txT*1000),'xyT',uint32(xyT*1e3));

%align # sample to xy
nxy = size(xy,1);
nslow = round(nxy*data.Tslw/xyT);
nfast = nxy*64;


ivlpiStruct.fast = data.vfst(1:nfast);
ivlpiStruct.slow = uint16(qSlow(1:nslow));
ivlpiStruct.xy = xy(1:nxy,:);
ivlpiStruct.flags=uint8(zeros(1,nxy));


%switch xy
ivlpiStruct.xy  = ivlpiStruct.xy (:,[2 1]);
%decrease Y accuracy
ivlpiStruct.xy(:,2)=bitshift(ivlpiStruct.xy(:,2),-2);
%transpose
ivlpiStruct.xy=ivlpiStruct.xy';
end