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
%%
%{
 params.pzr2los = [0.5248    0.0000    0.4942    0.1273    1.0214   -0.1234];
 params.angxFilt(3) = 12089.7330567241;
 params.angyFilt(3) = 57976.8520966172;
%}
%% 
 [im,ivs_]=scope2img(v{1},dt,params);
 indv=Utils.indx2col(size(im),[3 3]);
 im=reshape(nanmedian(im(indv)),size(im));
%%
 figure;
 subplot(121)
 imagesc(imo);axis image
 subplot(122)
 imagesc(im);axis image
 
% colormap gray
 linkaxes(findobj(0,'type','axes'))

%%
fa_0 = errFuncA(params.pzr2los,v,dt,params);
[p1_best,fa1]=fminsearch(@(x) errFuncA(x,v,dt,params),params.pzr2los,struct('Display','iter'));
[p2_best,fa2]=fminsearch(@(x) errFuncA(x,v,dt,params),[params.angxFilt(3) params.angyFilt(3)],struct('Display','iter'));


fb_0 = errFuncB(params.pzr2los,v,dt,params);
[p3_best,fb1]=fminsearch(@(x) errFuncB(x,v,dt,params),params.pzr2los,struct('Display','iter'));
[p4_best,fb2]=fminsearch(@(x) errFuncB(x,v,dt,params),[params.angxFilt(3) params.angyFilt(3)],struct('Display','iter'));

[fa_0 fb_0]./[fa1 fb1]-1
[fa_0 fb_0]./[fa2 fb2]-1
