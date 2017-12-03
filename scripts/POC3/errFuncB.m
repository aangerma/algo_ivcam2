function e=errFunc(P,v,dt,params)
warning('off',    'vision:calibrate:boardShouldBeAsymmetric');
params.angxFilt(3)=P(1);
params.angyFilt(3)=P(2);

im=cellfun(@(x) scope2img(x,dt,params),v,'uni',0);
indv=Utils.indx2col(size(im{1}),[3 3]);
im = cellfun(@(x) reshape(nanmedian(x(indv)),size(im{1})),im,'uni',0);
im = cellfun(@(x) nan2zero(x),im,'uni',0);
im = cellfun(@(x) histeq(normByMax(x)),im,'uni',0);
try
       p = cellfun(@(x)  Utils.findCheckerBoardCorners(x,[9 13],true),im,'uni',0);
    p=reshape([p{:}],9,13,[]);
    
    e=sqrt(mean(vec(var(real(p),[],3)+var(imag(p),[],3))));
catch
    e=10;
    return;
end





end


function m=nan2zero(m)
m(isnan(m))=0;
end