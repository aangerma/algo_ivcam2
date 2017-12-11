%function x=rawDataInput()
%%

fldrs= dirFolders('\\invcam450\D\data\ivcam20\exp\20171129\','*',true);

[v,dt]=cellfun(@(x) folder2scopeData(x),fldrs,'uni',0);
dt=dt{1};
%%
params.irPreFilt = [3 166e6+[-30 30]*1e6];
params.irPostFilt = [3 0 64e6 ];
params.pzr2los = [  .5       0          .5       1/8 1 -1/8];
params.angxFilt = [3 0 15e3 ];
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
 params.pzr2los = [0.4886 -1.4041e-04 0.5545 0.1371 1.0042 -0.1316];
 params.angxFilt(3) = 1.3340e+04;
 params.angyFilt(3) = 4.8581e+04;
%}
%% 
 [im,ivs_]=scope2img(v{1},dt,params);
%  [im,ivs_]=cellfun(@(x) scope2img(x,dt,params),v,'uni',0);
 indv=Utils.indx2col(size(im),[3 3]);
  im=reshape(nanmedian(im(indv)),size(im));
% im=cellfun(@(x) reshape(nanmedian(x(indv)),size(im{1})),im,'uni',0);
%%
 figure;
 subplot(121)
 imagesc(imo);axis image
 subplot(122)
 imagesc(im);axis image
 linkaxes(findobj(0,'type','axes'))
 %%

 

[fa_0,im,p] = errFuncA(params.pzr2los,v,dt,params); 
fc_0 = errFuncC(params.pzr2los,v,dt,params);
%%
while(true)
[p3_best,fc1]=fminsearch(@(x) errFuncC(x,v,dt,params),params.pzr2los);
params.pzr2los=p3_best;
[p4_best,fc2]=fminsearch(@(x) errFuncC(x,v,dt,params),[params.angxFilt(3) params.angyFilt(3)]);
params.angxFilt(3)=p4_best(1);params.angyFilt(3)=p4_best(2);
[ fc1 fc2]

params
end
