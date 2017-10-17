%add the norms to the figure
function [n,c]=calcNorms(v,tri)
n=nan(size(tri,1),3);
c=nan(size(tri,1),3);
for i=1:size(tri,1)
    xyz=v(tri(i,:),:);
    p1 =xyz(2,:)-xyz(1,:);
    p2 =xyz(3,:)-xyz(1,:);
    n(i,:)=cross(p1,p2);
    n(i,:)=n(i,:)./sqrt(sum(n(i,:).^2));
    c(i,:)=mean(xyz,1);
end
end