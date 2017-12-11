function [e,im]=errFuncC(P,v,dt,params)

switch(length(P))
    case 6
        params.pzr2los = P;
    case 2
        params.angxFilt(3)=P(1);
        params.angyFilt(3)=P(2);
    otherwise
        error('bad input');
end
imsz=params.outBin*[1 1];
im=cell(length(v),1);
indv=Utils.indx2col(imsz,[5 5]);
for i=1:length(v)
im{i}=scope2img(v{i},dt,params);
im{i}=reshape(nanmedian(im{i}(indv)),imsz);
end
im_=reshape([im{:}],imsz(1),imsz(2),[]);
d = var(im_,[],3);
e=sqrt(nanmean(d(:)));

	





end

