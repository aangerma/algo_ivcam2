function [thX,v]=calibrateDFZ(rxy)
   
    th0=[0 72 56 0 0 ];
    O = [20 2 2 2 2];
    
%     th0=[0 72 56 ];
%     O = [40 2 5 ];

    
    thL=th0-O;
    thH=th0+O;
    
    
%     thX=fminsearchbnd(@(x) calcErr(rxyth2xyz(rxy,x)),th0,thL,thH);
    N=5;
    vL=arrayfun(@(i) linspace(thL(i),thH(i),N),1:length(thL),'uni',0);
    d=cell(length(vL),1);
    [d{:}]=ndgrid(vL{:});
    e=zeros(size(d{1}));
    n=numel(d{1});
    for ii=1:n
        th=cellfun(@(x) x(ii),d);
        xyz=rxyth2xyz(rxy,[th;0;0]);
        e(ii) = calcErr(xyz);
        
    end
    
    %%
    X=cell2mat(cellfun(@(x) x(:)',d,'uni',false));
    
    matH = generateLSH((X'-thL)./O-1,4);
     v=pinv(matH)*e(:);
    
%     e_hat=reshape(matH*v,size(e));
    calcErr_hat = @(x) abs(generateLSH((x-thL)./O-1,4)*v);
 if(0)
     %%

     nn=cell(5,1);
     [nn{:}]=ind2sub(size(e),minind(e(:)));
    
    e_hat=reshape(calcErr_hat(X'),size(e));rms(vec(e-e_hat));
    subplot(5,2,1) ;plot(vL{1},[squeeze(e(:    ,nn{2},nn{3},nn{4},nn{5})) squeeze(e_hat(:    ,nn{2},nn{3},nn{4},nn{5}))])
    subplot(5,2,3) ;plot(vL{2},[squeeze(e(nn{1},:    ,nn{3},nn{4},nn{5}));squeeze(e_hat(nn{1},:    ,nn{3},nn{4},nn{5}))]')
    subplot(5,2,5) ;plot(vL{3},[squeeze(e(nn{1},nn{2},:    ,nn{4},nn{5})) squeeze(e_hat(nn{1},nn{2},:    ,nn{4},nn{5}))])
    subplot(5,2,7) ;plot(vL{4},[squeeze(e(nn{1},nn{2},nn{3},:    ,nn{5})) squeeze(e_hat(nn{1},nn{2},nn{3},:    ,nn{5}))])
    subplot(5,2,9) ;plot(vL{5},[squeeze(e(nn{1},nn{2},nn{3},nn{4},:    )) squeeze(e_hat(nn{1},nn{2},nn{3},nn{4},:    ))])
    subplot(5,2,2) ;plot(vL{1},[squeeze(e(:    ,nn{2},nn{3},nn{4},nn{5}))-squeeze(e_hat(:    ,nn{2},nn{3},nn{4},nn{5}))])
    subplot(5,2,4) ;plot(vL{2},[squeeze(e(nn{1},:    ,nn{3},nn{4},nn{5}))-squeeze(e_hat(nn{1},:    ,nn{3},nn{4},nn{5}))])
    subplot(5,2,6) ;plot(vL{3},[squeeze(e(nn{1},nn{2},:    ,nn{4},nn{5}))-squeeze(e_hat(nn{1},nn{2},:    ,nn{4},nn{5}))])
    subplot(5,2,8) ;plot(vL{4},[squeeze(e(nn{1},nn{2},nn{3},:    ,nn{5}))-squeeze(e_hat(nn{1},nn{2},nn{3},:    ,nn{5}))])
    subplot(5,2,10);plot(vL{5},[squeeze(e(nn{1},nn{2},nn{3},nn{4},:    ))-squeeze(e_hat(nn{1},nn{2},nn{3},nn{4},:    ))])

	
 end
%     
    options.TolFun=0;
    options.TolX=0;
    options.Display='final';
    options.MaxFunEvals=1e5;
    thX=fminsearch(calcErr_hat,th0,options);
    
    thX=thX(:);
% % %     plot([squeeze(e(8,8,:)) squeeze(e_hat(8,8,:))])
% % %     %%
% % %     matH = matH.*[1 2 2 2 2 1 2 2 2 1 2 2 1 2 1 1 1 1 1 1 1];%multiply by these coefficients, so that the correlation matrix will be the vector of coeficients
% % %     v=matH\e(:);
% % %     
% % %     S=[
% % %        v( 1) v( 2) v( 3) v( 4) v( 5);
% % %        v( 2) v( 6) v( 7) v( 8) v( 9);
% % %        v( 3) v( 7) v(10) v(11) v(12);
% % %        v( 4) v( 8) v(11) v(13) v(14);
% % %        v( 5) v( 9) v(12) v(14) v(15)
% % %        ];
% % %    u=v(16:20);
% % %    c =v(21);
% % %    
% % %    e_hat=reshape(arrayfun(@(i) X(:,i)'*S*X(:,i)+u'*X(:,i)+c,1:n),size(e));
% % % 
% % %    
% % %     thX=-0.5*S^-1*u;
   
   
end

% function s = genMDSev(m)
%     n=size(m,2);
%     J=eye(n)-1/n*ones(n);
%     
%     genDmat2 = @(m) (sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
%     [~,s,~]=svd(0.5*J*genDmat2(m)*J);
%     s=sqrt(diag(s));
% end
function e = calcErr(xyz)
    [~,op]=Calibration.getTargetParams();
    
    genDmat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
    dO=genDmat(op);
    dM=genDmat(xyz);
    

%      e=rms(vec(dO-dM)).^2;
   
        e=mean(vec((dO-dM).^2));
    
end
    

function xyz=rxyth2xyz(rxy,th)
    rtd=rxy(1,:);
    thX=rxy(2,:);
    thY=rxy(3,:);
    bk=30;
    
    tau  = th(1);
    xfov = th(2)*pi/180;
    yfov = th(3)*pi/180;
   
    lx   = th(4)*pi/180;
    ly   = th(5)*pi/180;
 
    
    angles2xyz = @(angx,angy) [ cos(angy').*sin(angx') sin(angy') cos(angx').*cos(angy')].';
    laserIncidentDirection = angles2xyz( lx, ly+pi); %+180 because the vector direction is toward the mirror
    
    oXYZfunc = @(mirNormalXYZ_)  laserIncidentDirection-2*(laserIncidentDirection.'*mirNormalXYZ_).*mirNormalXYZ_;

    angXfactor = xfov*(0.25/(2^11-1));
    angYfactor = yfov*(0.25/(2^11-1));

    angx_ = thX*angXfactor;
    angy_ = thY*angYfactor;
    
    nout= oXYZfunc(angles2xyz(angx_,angy_));
    rtd_=rtd-tau;
    sing = nout(1,:);
    r= (0.5*(rtd_.^2 - bk^2))./(rtd_ - bk.*sing);
    
    xyz=nout.*r;
    
    
end
