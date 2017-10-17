function scanStats = scanStats( angx,angy,xyQout,regs,lgr)
sz = double([regs.GNRL.imgVsize,regs.GNRL.imgHsize]);

xq = vec(xyQout(1,:));
yq = vec(xyQout(2,:));

xeqb = find(abs(angy)==min(abs(angy(xq<0))) & xq<0,1);
xeqe = find(abs(angy)==min(abs(angy(xq>=regs.GNRL.imgHsize*4))) & xq>=regs.GNRL.imgHsize*4,1);


yeqb = find(abs(angx)==min(abs(angx(yq<1))) & yq<0,1);
yeqe = find(abs(angx)==min(abs(angx(yq>=regs.GNRL.imgVsize))) & yq>regs.GNRL.imgVsize,1);


scanStats.actualFOV.x = (angx(xeqe)-angx(xeqb))*2;
scanStats.actualFOV.y = (angy(yeqe)-angy(yeqb))*2;

outfov = @(xy) xy(1,:)<4 | xy(1,:)>regs.GNRL.imgHsize*4 | xy(2,:)<1 | xy(2,:)>regs.GNRL.imgVsize;



transLocs = find([abs(diff(xyQout(2,:)))==1 false]); %ytrans
xyChunks = arrayfun(@(i) xyQout(:,transLocs(i):transLocs(i+1)-1),1:length(transLocs)-1,'uni',false);
chunkData = cellfun(@(x) [round(mean(x(1,:))-eps);double(x(2,1));size(x,2)],xyChunks,'uni',false);
chunkData=[chunkData{:}];


bdchunk = outfov(chunkData);
chunkData(:,bdchunk)=[];
ind = sub2ind(sz,chunkData(2,:),chunkData(1,:)/4);
v=accumarray(ind',chunkData(3,:)',[prod(sz) 1]);
txy = 64/double(regs.GNRL.sampleRate);

scanStats.nvisits = reshape(v,sz);
scanStats.coverage = sum(scanStats.nvisits(:)*txy>regs.GNRL.codeLength)/numel(scanStats.nvisits);
[scanStats.cdf.y,scanStats.cdf.x]=hist(chunkData(3,:)*txy,0:txy:double(regs.GNRL.codeLength)*10);
scanStats.cdf.y = cumsum(scanStats.cdf.y)/sum(scanStats.cdf.y);

end

