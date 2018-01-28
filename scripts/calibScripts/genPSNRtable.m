function [regs, unitTestS] = genPSNRtable(verbose)
N=2^8;
%% flags
if(nargin==0)
%     m_cw = 3000/(2^12);
    verbose = 1;
end

%% vars init


%Ms,Mn: given later in the pipe so we need to simulate them
MnSim = linspace(0,1,N);
%to get alpha (denoted here 'a') we need Ms and go back to alpha
alphaSim = linspace(0,1,N);





%% calc


% given Mcw measurments with no noise, gamma is constant
% gamma = (pi/2)^0.25*sqrt(max(m_cw-0,0));%Mcw > Mn always... it's an assumption
gamma=2; %OHAD: GET NEW WAY TO GET GAMMA
%% ::0:: init
[m_n,m_p] = meshgrid(MnSim,alphaSim);
phi = @(x) cdf('Normal',x,0,1);



%% ::1:: evaluate peak function
s = m_n*sqrt(pi/2);


elem0 = gamma.*m_p./(2.*s);

elem1 = sqrt(s.^2+gamma.^2.*m_p);

elem2 = s.*exp(-0.5.*(elem0.^2));

elem3 = elem1.*exp(-gamma.*m_p.^2./(8.*elem1.^2));

m_s = 1./sqrt(2.*pi).*(elem2+elem3)+gamma.*m_p./2.*(phi(gamma.*m_p./(2.*s))-phi(-gamma.*m_p./(2.*elem1)));
m_s = min(1,max(0,m_s));
m_s(isnan(m_s))=0;
if(verbose)
    %%
    figure(252134);tabplot;
    plot3(m_n(:),m_p(:),m_s(:),'.');
    xlabel('M_n');ylabel('\alpha');zlabel('M_s');
    axis square
end
% ::2:: inverse function
%m_s = f(m_n,m_p)
% convert to:
%m_p = f(m_n,m_s);

m_nI=m_n;
m_sI=m_n';

v = m_n<=m_s;
m_pI=griddata(m_n(v),m_s(v),m_p(v),m_nI,m_sI);
m_pI(isnan(m_pI) & m_nI>m_sI)=0;
m_pI(isnan(m_pI) & m_nI<m_sI)=1;
m_pI=min(1,max(0,m_pI));
snrLUT = 20*log(m_pI./s);
MIN_SNR=-10;
MAX_SNR=4;
snrLUT = min(MAX_SNR,max(MIN_SNR,snrLUT));
snrLUT = normByMax(snrLUT);
%% ::3:: set low res grid with non-linear sampling

finv = @(x) interp1(normByMax(x),linspace(0,1,length(x)),linspace(0,1,length(x)));

lutx =linspace(0,1,16);
dg = absgrad(snrLUT);
dglims=prctile(dg(:),[5 95]);
dg=min(1,max(0,(dg-dglims(1))/diff(dglims)));
nLUT=interp1(linspace(0,1,N),finv(cumsum(sum(dg,1)+eps*N^2)),lutx);
sLUT=interp1(linspace(0,1,N),finv(cumsum(sum(dg,2)+eps*N^2)),lutx);


m_nIv=repmat(nLUT(:),1,16);
m_sIv=repmat(sLUT(:)',16,1);
snrLUTv=griddata(m_nI(:),m_sI(:),snrLUT(:),m_nIv,m_sIv);

if(verbose)
    %%
    tabplot;
    surf(m_nI,m_sI,snrLUT,'edgecolor','none');
    hold on
    plot3(m_nIv(:),m_sIv(:),snrLUTv(:),'.r');
    hold off
    xlabel('M_n');ylabel('M_s');zlabel('\alpha');
    axis equal
end

%% ::4:: get regs
regType = {'amb', 'ir'};
for i=1:length(regType)
    data = sLUT;
    if i==1
        data = nLUT;
    end
    ind = 0:1:63;
    stepInd = zeros(size(ind));
    stepInd(round(data*63)+1) = 1;
    regs.DCOR.([regType{i} 'Map']) = uint8(cumsum(stepInd)-1);
end

regs.DCOR.psnr = rot90(fliplr(uint8(round(snrLUTv*63))));

if(verbose)
    %%
    tabplot
    subplot(121);imagesc(snrLUT);colorbar
    subplot(122);imagesc(regs.DCOR.psnr);colorbar
end
%
% %% for unit test
% unitTestS.Ms = MsSim;
% unitTestS.Mn = MnSim;
% unitTestS.psnrT = psnrT;
end


