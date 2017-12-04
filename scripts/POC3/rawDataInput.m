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
params.angyFilt = [3 0 50e3 ];
params.locPreFreq = 120e6;
params.locPostFreq = 10e6;
params.outFreq = 125e6;
params.locIRdelay = 114;
params.outBin = 1024;
params.angxSO = [12 0];
params.angySO = [2 0];
params.slowSO = [29e3 0];
% [im,ivs_]=scope2img(v,dt,params);
% indv=Utils.indx2col(size(im),[3 3]);
% im=reshape(nanmedian(im(indv)),size(im));
% figure;
% imagesc(im,[0 1500]);
% colormap gray
% linkaxes(findobj(0,'type','axes'))

%%
p1_best=fminsearch(@(x) errFuncA(x,v,dt,params),params.pzr2los,struct('Display','iter'));
p2_best=fminsearch(@(x) errFuncA(x,v,dt,params),[params.angxFilt(3) params.angyFilt(3)],struct('Display','iter'));

p3_best=fminsearch(@(x) errFuncB(x,v,dt,params),params.pzr2los,struct('Display','iter'));
p4_best=fminsearch(@(x) errFuncB(x,v,dt,params),[params.angxFilt(3) params.angyFilt(3)],struct('Display','iter'));

