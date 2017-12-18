fldr='\\invcam322\data\lidar\EXP\20171016_RF\100\';
ivs=io.FG.readFrames(fldr,100,false);
%%
ker=kron(Codes.propCode(32,1),ones(16,1));
begIndx = @(x) find(bitget(x.flags,2),1);
endInd = @(x)  mod(length(x.fast),length(ker));

ivs_=arrayfun(@(x) struct('fast',x.fast((begIndx(x)-1)*64+1:end),'slow',x.slow(begIndx(x):end),'flags',x.flags(begIndx(x):end)),ivs);
ivs_=arrayfun(@(x) struct('fast',x.fast(1:endInd(x)*64),'slow',x.slow(1:endInd(x)),'flags',x.flags(1:endInd(x))),ivs_);
%%

ff=[ivs_.fast];
% ff=ff(1:1e7);
v=buffer_(ff,length(ker));
v(:,all(v==0))=[];
c = Utils.correlator(v,ker*2-1);
imagesc(c)
