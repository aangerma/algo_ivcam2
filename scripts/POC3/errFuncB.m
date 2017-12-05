function e=errFuncB(P,v,dt,params)
warning('off',    'vision:calibrate:boardShouldBeAsymmetric');
switch(length(P))
    case 6
        params.pzr2los = P;
    case 2
        params.angxFilt(3)=P(1);
        params.angyFilt(3)=P(2);
    otherwise
        error('bad input');
end

im=scope2img(v{1},dt,params);
indv=Utils.indx2col(size(im),[3 3]);
im =  reshape(nanmedian(im(indv)),size(im));
im = nan2zero(im);


try
    e=Calibration.aux.edgeUnifomity(im);

catch
    e=10000;
    return;
end





end


function m=nan2zero(m)
m(isnan(m))=0;
end