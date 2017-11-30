function e=errFunc(P,v,dt,params)
warning('off',    'vision:calibrate:boardShouldBeAsymmetric');
params.pzr2los = P;

im=cellfun(@(x) scope2img(x,dt,params),v,'uni',0);
indv=Utils.indx2col(size(im{1}),[3 3]);
im = cellfun(@(x) reshape(nanmedian(x(indv)),size(im{1})),im,'uni',0);
im = cellfun(@(x) nan2zero(x),im,'uni',0);
im = cellfun(@(x) histeq(normByMax(x)),im,'uni',0);
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