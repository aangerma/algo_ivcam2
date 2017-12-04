function [delayF,delayS,errS] = mSyncerPipe(ivs,regs,checkerboardTarget,verbose)
if(~exist('checkerboardTarget','var'))
    checkerboardTarget=false;
end
if(~exist('verbose','var'))
    verbose=false;
end
y = double(ivs.xy(2,:));
fy = abs(fft(y-mean(y)));
winSz = round(length(y)/maxind(fy(1:floor(length(fy)/2)))*.5);
y=conv(y,fspecial('gaussian',[1 winSz],winSz/5),'same');
%%
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
%%
vs=double(ivs.slow);
[delayS, errS] = crossSync(vs,y,c,checkerboardTarget,verbose);

%%
if(isempty(regs))
    delayF=delayS;
else
    codevec = vec(fliplr(dec2bin(regs.FRMW.txCode(:),32))')=='1';
    kF = double(vec(repmat(codevec(1:regs.GNRL.codeLength),1,regs.GNRL.sampleRate)'));
    vv=buffer(ivs.fast,length(kF),length(kF)-64);
    cr = Utils.correlator(vv,kF*2-1);
    peakVal = max(cr)*2/length(kF);
    peakVal=max(peakVal,0);
    [delayF errF] = crossSync(peakVal,y,c,checkerboardTarget,verbose);
end


end

function [delayOut , errOut] = crossSync(data,y,c,checkerboardTarget,verbose)

%%
dataF = data;%conv(data,fspecial('gaussian',[5 1],2),'valid');
n = round(mean(diff(c)));
R=5;
r = n/2;
d = n/2;


while(true)
    
    x =  round(r+linspace(-d,d,R))';
    if(all(diff(x)==0))
        break;
    end
  
    if(checkerboardTarget && d<=2)
       [err,sl] = arrayfun(@(k) calcErrFine(circshift(dataF,[0 k]),y,c),x,'uni',0);
    else
        [err,sl] = arrayfun(@(k) calcErrDiff(circshift(dataF,[0 k]),y,c),x,'uni',0);
    end

    err=[err{:}]';
    
    minInd=minind(err);
    r = x(minInd);
    errOut = err(minInd);
    
    d = floor(d/R*2);
    if(verbose)
        for i=1:R
            aa(i)=subplot(2,R,i);
            imagesc(sl{i},prctile_(sl{i}(sl{i}~=0),[10 90])+[0 1e-3]);
        end
        subplot(2,3,4:6)
        plot(x,err,'o-');set(gca,'xlim',[x(1)-d/2 x(end)+d/2]);
        line([r r ],minmax(err),'color','r');
        linkaxes(aa);
        drawnow;
    end
end
delayOut=r;
if(verbose)
    close(gcf);
    drawnow;
end
end

function dl=data2sl(data,y,c,N)
dl=arrayfun(@(i) [y(c(i):c(i+1));data(c(i):c(i+1))],1:length(c)-1,'uni',0);
r = minmax(y);
  dl = cellfun(@(x) interp1(linspace(0,1,length(x)),x(2,:),linspace(0,1,N))',dl,'uni',0);
%   dl = cellfun(@(x) interp1(x(1,:),x(2,:),linspace(r(1),r(2),N))',dl,'uni',0);
dl=[dl{:}];
dl=dl(:,1:floor(size(dl,2)/2)*2);
 dl(:,2:2:end)=flipud(dl(:,2:2:end));
end


function [err,im]=calcErrFine(data,y,c)

N=2048;
sl = data2sl(data,y,c,N);
img1=sl(:,1:2:end);
img2=(sl(:,2:2:end));
im = reshape([img1;img2],size(sl));
err = Calibration.aux.edgeUnifomity(im);
end

function [err,im]=calcErrDiff(data,y,c)

N=1024;
sl = data2sl(data,y,c,N);
sl(isnan(sl))=0;
img1=sl(:,1:2:end);
img2=(sl(:,2:2:end));
im = reshape([img1;img2],size(sl));
d=(img2-img1)./img1;
% [~,dy1]=gradient(img1);
% [~,dy2]=gradient(img2);
mask = imerode(img1~=0 & img2~=0,ones(3));
mask(1:N/4,:)=false;
mask(N*3/4:end,:)=false;

%   wImg = min(abs(dy1),abs(dy2));
%   d=d.*wImg;
graderr = mean(vec(abs(d(mask))));
centererr=-nnz(im(floor(size(im,1)/2),:))/size(im,2);
maskerr=-nnz(mask)/numel(mask);

err=graderr+centererr+maskerr;
end