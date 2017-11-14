function a=plotCam(R,t,scaleFact,col,K)
if(~exist('K','var'))
    K=eye(3);
end
%X up - red
%Y up - green
%Z up - cam dir
if(~exist('scaleFact','var') || isempty(scaleFact))
    scaleFact = 0.05;
end
if(~exist('col','var') || isempty(col))
    col = [1 1 1];
end

dx = 1/K(1,1);
dy = 1/K(2,2);

 P = [     0    -dx    -dx     0    -dx     dx     0     dx     dx     0     dx    -dx    0   dx    0   -.1    0   .1     
           0    -dy     dy     0     dy     dy     0     dy    -dy     0    -dy    -dy  -.1    0   .1     0   dy    0 
           0     1      1     0       1      1     0      1      1     0      1      1    0    0    0     0    0    0  ];
%  P(3,:)=P(3,:)-1;
 P = P/max(dx,dy)*0.5;
cdata = permute(repmat(linspace(1,1,4),3,1).*repmat(col',1,4),[3 2 1]);



cdata(1,end+1,:) = [1 0 0];
cdata(1,end+1,:) = [0 1 0];
 P = P*scaleFact;
 P = R*P + repmat(t,1,size(P,2)); 
 xdata=reshape(P(1,:),3,6);
 ydata=reshape(P(2,:),3,6);
 zdata=reshape(P(3,:),3,6);
 

 a=patch(xdata,ydata,zdata,cdata,'FaceColor','flat');


end

