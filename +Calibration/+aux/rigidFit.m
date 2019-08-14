function [e_dist,fitP,rotmat,c1,c2] = rigidFit(p1,p2)
% finds optimal rot and translation. Returns the error.
c1 = mean(p1,1);
p1m=p1-c1;
c2 = mean(p2);
p2m=p2-c2;

%shift to center, find rotation along PCA
[u,~,vt]=svd(p1m'*p2m);
rotmat=u*vt';
e_dist = mean(vec(sqrt((sum((p1m'-rotmat*p2m').^2)))));
fitP = p2m*rotmat'+c1; %(p2-c2)*rotmat'+c1
end