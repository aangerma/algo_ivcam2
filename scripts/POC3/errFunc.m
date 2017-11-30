function e=tempFunc(P,v,dt)
params.irPreFilt = [3 166e6+[-30 30]*1e6];
params.irPostFilt = [3 0 64e6 ];
params.pzr2los = P;
params.angxFilt = [3 0 15e3 0];
params.angyFilt = [3 0 60e3 ];
params.locPreFreq = 120e6;
params.locPostFreq = 10e6;
params.outFreq = 125e6;
params.locIRdelay = 114;
params.outBin = 1024;
params.angxSO = [12 0];
params.angxSO = [1.9 0];

im=cellfun(@(x) scope2img(x,dt,params),v,'uni',0);
indv=Utils.indx2col(size(im{1}),[3 3]);
im = cellfun(@(x) reshape(nanmedian(x(indv)),size(im{1})),im,'uni',0);
im = cellfun(@(x) nan2zero(x),im,'uni',0);
im = cellfun(@(x) histeq(x),im,'uni',0);
try
    p = cellfun(@(x) detectCheckerboardPoints(x),im,'uni',0);
    imv=reshape([p{:}],size(p{1},1),size(p{1},2),[]);
    e=sqrt(mean(vec(var(imv,[],3))));
catch
    e=10;
    return;
end





end


function m=nan2zero(m)
m(isnan(m))=0;
end