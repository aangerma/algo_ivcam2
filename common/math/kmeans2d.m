function [currMid1,currMid2, mn1_v, mn2_v,i] = kmeans(x,k)

N = size(x,1);
rnd_pts = randi(N,k,1);

prevMid1 = x(rnd_pts(1),:); currMid1 = x(mod(rnd_pts(1)+1,N),:);
prevMid2 = x(rnd_pts(2),:); currMid2 = x(mod(rnd_pts(2)+1,N),:);
i=1;

while (prevMid1~=currMid1 | prevMid2~=currMid2)
    prevMid1=currMid1; prevMid2=currMid2;
    diffs1 = sqrt((x(:,1)-prevMid1(1)).^2 + (x(:,2)-prevMid1(2)).^2);
    diffs2 = sqrt((x(:,1)-prevMid2(1)).^2 + (x(:,2)-prevMid2(2)).^2);
    mn1_v=x(diffs1<diffs2,:); currMid1 = mean(mn1_v);
    mn2_v=x(diffs1>diffs2,:); currMid2 = mean(mn2_v);
   i=i+1;
end

