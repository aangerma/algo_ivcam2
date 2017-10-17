function yi=relocateTimeFrame(t,y,ti)

% Tc = t(2)-t(1);
% %yi(indx) = sum(y(ti==t(indx));
% yi=zeros(size(t));
% parfor indx = 1:length(t)
% yi(indx) = sum(y(abs(ti-t(indx))<Tc/2));
% end


%
ti(isinf(ti))=nan;
dt=diff(t);
dc = find(dt<=0)+1;
dc = [1;dc;length(t)];
yi=zeros(size(t));
for i=1:length(dc)-1
    src_t = ti(dc(i):dc(i+1)-1);
    src_y = y(dc(i):dc(i+1)-1);
    bd = isnan(src_t);
    src_t(bd)=[];
    src_y(bd)=[];
    ngood=nnz(~bd);
    if(ngood<2)
        continue;
    end
    yi=yi+interp1_(src_t,src_y,t);
end

end


function yi=interp1_(x,y,xi)
if(length(x)==1)
     yi=zeros(size(xi));
    if(y==0)
        return;
    end
   indx0 = find(x<xi,1);
   if(isempty(indx0) || indx0 == length(xi))
       return;
   end
   indx1 = indx0+1;
   p = x-floor(x);
  
   yi(indx0)=y*(1-p);
   yi(indx1)=y*p;
   return;
end
yi=interp1(x,y,xi,'linear',0);
end