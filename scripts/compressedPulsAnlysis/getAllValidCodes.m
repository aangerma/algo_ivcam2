function c=getAllValidCodes(N)

c = [0 0;0 1; 1 0 ; 1 1]>0;
for i=3:N
    tic
    cn = [c false(size(c,1),1);c true(size(c,1),1)];
%
    s = sum(cn(:,end-2:end),2);
    gd = s==1 | s==2;
    c = cn(gd,:);
%     fprintf('%d %d %f\n',i,size(c,1),toc);
end

%%% check that codes are cyclic
s1 = sum(c(:,[end-1:end 1]),2);
s2 = sum(c(:,[end 1:2]),2);
gd = s1~=0 & s1~=3 & s2 ~=0 & s2~=3;
c = c(gd,:);
%%% DC
if(mod(N,2)==0)
    cs=sum(c,2)==N/2;
else
    cs=sum(c,2)==(N-1)/2 | sum(c,2)==(N+1)/2;
end
c = c(cs,:);

ind = mod(bsxfun(@plus,(1:N)',0:N-1)-1,N)+1;
L = (-pi).^(1:N)';
mat = L(ind);
cmat = c*mat;
inds = maxind(cmat,[],2);
for i=1:size(c,1)
    c(i,:) = circshift(c(i,:),[0 inds(i)-1]);
end
c = unique(c,'rows');

