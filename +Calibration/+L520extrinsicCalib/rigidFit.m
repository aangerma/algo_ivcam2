function [e_dist,fitP,rotmat,c1,c2] = rigidFit(p1,p2)
% finds optimal rot and translation. Returns the error.
c1 = mean(p1,1);
p1m=p1-c1;
c2 = mean(p2,1);
p2m=p2-c2;

%shift to center, find rotation along SVD 
[u,~,v]=svd(p1m'*p2m);% p1m'*p2m - projection direction
rotmat=u*v';

e_dist = mean(vec(sqrt((sum((p1m'-rotmat*p2m').^2)))));

fitP = (p2-c2)*rotmat'+c1; 
figure;
hold all

plot(fitP(:,1),fitP(:,2),'bo')
plot(p2(:,1),p2(:,2),'rx')
plot(p1(:,1),p1(:,2),'b+')
grid on; 
legend('fitted p2','p2- orig','p1- orig'); 
end