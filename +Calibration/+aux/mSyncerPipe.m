function [delayF,delayS,errS] = mSyncerPipe(ivs,regs,verbose)
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
[delayS, errS] = crossSync(vs,c,verbose);

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
    [delayF errF] = crossSync(peakVal,c,verbose);
end
% % % %%?????????????????????? EMPIRIC TEST???????????
% % delayS = delayS+1;
% % delayF = delayF+1;

end

function [delayOut , errOut] = crossSync(data,c,verbose)

%%
dataF = data;%conv(data,fspecial('gaussian',[5 1],2),'valid');
n = round(mean(diff(c)))*2;
R=5;
r = n/2;
d = n/4;


while(true)
    
    x = r+ round(linspace(-d,d,R))';
    if(all(diff(x)==0))
        break;
    end
  
    runExact = false;
    if(d<=2)
        runExact=true;
    end
    
    if(runExact)
        try
            [err,sl] = arrayfun(@(k) calcErrFine(circshift(dataF,[0 k]),c),x,'uni',0);
            
        catch e,
            warning(['could not find checkerboard image:\n' e.message]);
            runExact=false;
        end
    end
    
    if(~runExact)
            [err,sl] = arrayfun(@(k) calcErrDiff(circshift(dataF,[0 k]),c),x,'uni',0);
    end

    err=[err{:}]';
    
    minInd=minind(err);
    r = x(minInd);
    if runExact
        errOut = err(minInd);
    else
        errOut = nan;
    end
    d = floor(d/R*2);
    if(verbose)
        for i=1:R
            aa(i)=subplot(2,R,i);
            imagesc(sl{i},prctile(sl{i}(:),[10 90])+[0 1e-3]);
        end
        subplot(2,3,4:6)
        plot(x,err,'o-');
        line([r r ],minmax(err),'color','r');
        axis tight
        drawnow;
    end
end
delayOut=r;
if(verbose)
    close(gcf);
    drawnow;
end
end

function sl=data2sl(data,c,N)
sl=arrayfun(@(i) data(c(i):c(i+1)),1:length(c)-1,'uni',0);

sl = cellfun(@(x) interp1(linspace(0,1,length(x)),x,linspace(0,1,N))',sl,'uni',0);
sl=[sl{:}];
sl=sl(:,1:floor(size(sl,2)/2)*2);
end


function [err,im]=calcErrFine(data,c)

N=2048;
sl = data2sl(data,c,N);
img1=sl(:,1:2:end);
img2=flipud(sl(:,2:2:end));
im = reshape([img1;img2],size(sl));
err = Calibration.aux.edgeUnifomity(im);
end

function [err,im]=calcErrDiff(data,c)

N=1024;
sl = data2sl(data,c,N);

img1=sl(:,1:2:end);
img2=flipud(sl(:,2:2:end));
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