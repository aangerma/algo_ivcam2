%function x=rawDataInput()
%%

fldrs= dirFolders('\\invcam450\D\data\ivcam20\exp\20171129\','*',true);

[v,dt]=cellfun(@(x) folder2scopeData(x),fldrs,'uni',0);
dt=dt{1};
%%
params.irPreFilt = [3 166e6+[-30 30]*1e6];
params.irPostFilt = [3 0 64e6 ];
params.pzr2los = [  .5       0          .5       1/8 1 -1/8];
params.angxFilt = [3 0 15e3 0];
params.angyFilt = [3 0 60e3 ];
params.locPreFreq = 120e6;
params.locPostFreq = 10e6;
params.outFreq = 125e6;
params.locIRdelay = 114;
params.outBin = 512;
params.angxSO = [12 0];
params.angySO = [2 0];
params.slowSO = [29e3 0];


Pbest=fminsearch(@(x) errFunc(x,v,dt,params),params.pzr2los,struct('Display','iter'));

[im,ivs]=cellfun(@(x) scope2img(x,dt,params),v,'uni',0);
imagesc(im);
