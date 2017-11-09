function c = matchTemplate(I,T,type)


if(strcmpi(type,    'SQDIFF'))             ,typeNum = 1;
elseif(strcmpi(type,'SQDIFF_NORMED'))  ,typeNum = 2;
elseif(strcmpi(type,'CCORR'))             ,typeNum = 3;
elseif(strcmpi(type,'CCORR_NORMED'))         ,typeNum = 4;
elseif(strcmpi(type,'CCOEFF'))            ,typeNum = 5;
elseif(strcmpi(type,'CCOEFF_NORMED'))     ,typeNum = 6;
else
    error('unkonwn type');
end

Tt  = T -mean(T(:));
c = zeros(size(I)-size(T)+1);
sz = size(c);


for i=1:numel(c)
    [y,x]=ind2sub(sz,i);

        It = I(y:y+size(T,1)-1,x:x+size(T,2)-1);%#ok
        
        switch(typeNum)
            case 1
                cc = sum(It-T).^2;
            case 2
                nrmFac = sqrt((It(:)'*It(:))*(T(:)'*T(:)));
                cc = (It-T).^2/nrmFac;
            case 3
                cc=It.*T;
            case 4
                nrmFac = sqrt((It(:)'*It(:))*(T(:)'*T(:)));
                cc=It.*T/nrmFac;
            case 5
                Itt = It-mean(It(:));
                cc=Itt.*Tt;
            case 6
                Itt = It-mean(It(:));
                nrmFac = sqrt((Itt(:)'*Itt(:))*(T(:)'*T(:)));
                cc=Itt.*Tt./nrmFac;
        end
        c(i) = sum(cc(:));
end
