function im=raw2slImg(ivs,s,N,exactLocation)
if(~exist('N','var'))
    N=2048;
end
if(~exist('exactLocation','var'))
    exactLocation=false;
end

%     c=find(diff(double(bitget(ivs.flags,3)))~=0);
y = double(ivs.xy(2,:));
winSz = round(length(y)/maxind(abs(fft(y)))*.5);
y=conv(y,fspecial('gaussian',[1 winSz],winSz/5),'same');
c = round(crossing([],y,mean(y)));
if(y(1)>mean(y))%first always rising edge
    c=[1;c];
end
c=c(1:length(c)-mod(length(c),2));
cc = zeros(2,length(c)/2-1);
mxround = @(x) round(mean(find(x==max(x))));
mnround = @(x) round(mean(find(x==min(x))));
for i=1:length(c)/2-1
    i0=(i-1)*2+1;
    i1=(i-1)*2+2;
    i2=(i-1)*2+3;
    
    c0 =c(i0);
    c1 =c(i1);
    c2 =c(i2);
    
    cc(1,i)=mxround(y(c0:c1))+c0-1;
    cc(2,i)=mnround(y(c1:c2))+c1-1;
end
c=cc(:);

data=circshift(double(ivs.slow),s);
if(exactLocation)
 sl=arrayfun(@(i) [y(c(i):c(i+1));data(c(i):c(i+1))],1:length(c)-1,'uni',0);
 g = minmax(y);
 sl = cellfun(@(x) accumarray(round((x(1,:)'-g(1))/(g(2)-g(1))*(N-1))+1,x(2,:)',[N 1],@mean),sl,'uni',0);
 im=[sl{:}];
else


sl=arrayfun(@(i) data(c(i):c(i+1)),1:length(c)-1,'uni',0);
sl = cellfun(@(x) interp1(linspace(0,1,length(x)),x,linspace(0,1,N))',sl,'uni',0);
im=[sl{:}];
im(:,1:2:end)=flipud(im(:,1:2:end));
end


end
