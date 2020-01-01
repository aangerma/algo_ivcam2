function [C,grad,dbg] = costGrad(rgbPmat,D,Dx,Dy,W,V,Krgb,rgbDistort)
    tic;
    d = rgbDistort;
    [uvMap,xin,yin] = projectVToRGB(V,rgbPmat,Krgb,rgbDistort);
    V = [V,ones(size(V(:,1)))];

    
    
    % the donation of vertex i to the gradient of C with respect to rgbPmat
    DVals = interp2(D,uvMap(:,1)+1,uvMap(:,2)+1);
    DxVals = interp2(Dx,uvMap(:,1)+1,uvMap(:,2)+1);
    DyVals = interp2(Dy,uvMap(:,1)+1,uvMap(:,2)+1);
    
    % derivative of homogenues coordinates w.r.t rgbPmat
   
    x1 = (xin-Krgb(1,3))/Krgb(1,1);
    y1 = (yin-Krgb(2,3))/Krgb(2,2);
    r2 = x1.^2+y1.^2;
    rc = (1 + d(1)*r2 + d(2)*r2.^2 + d(5)*r2.^3);
    
    drc_dx1 = 2*d(1)*x1 + 4*d(2)*r2.*x1 + 6*d(5)*(r2.^2).*x1;
    drc_dy1 = 2*d(1)*y1 + 4*d(2)*r2.*y1 + 6*d(5)*(r2.^2).*y1;
    
    dXout_dXin =  (rc + x1.*drc_dx1 + 2*d(3)*y1 + 6*d(4)*x1 );
    dXout_dYin =  (x1.*drc_dy1 + 2*d(3)*x1 + 2*d(4)*y1 )*Krgb(1,1)/Krgb(2,2);
    dYout_dXin =  (y1.*drc_dx1 + 2*d(4)*y1 + 2*d(3)*x1 )*Krgb(2,2)/Krgb(1,1);
    dYout_dYin =  (rc + y1.*drc_dy1 + 2*d(4)*x1 + 6*d(3)*y1 );
           
    % For implementation
    for i = 1:size(V,1)
        dXin_dA = [V(i,:)/dot(rgbPmat(3,:),V(i,:));...
               zeros(1,4);...
               -dot(rgbPmat(1,:),V(i,:))*V(i,:)/(dot(rgbPmat(3,:),V(i,:))^2)];
        dYin_dA = [zeros(1,4);...
               V(i,:)/dot(rgbPmat(3,:),V(i,:));...       
               -dot(rgbPmat(2,:),V(i,:))*V(i,:)/(dot(rgbPmat(3,:),V(i,:))^2)];
    
        gradi(i,:,:) =  W(i)*(DxVals(i)*(dXout_dXin(i)*dXin_dA + dXout_dYin(i)*dYin_dA) + ...
                      DyVals(i)*(dYout_dXin(i)*dXin_dA + dYout_dYin(i)*dYin_dA));
   
                  
        dbg.dXout_dA(i,:,:) = (dXout_dXin(i)*dXin_dA + dXout_dYin(i)*dYin_dA);
        dbg.dYout_dA(i,:,:) = (dYout_dXin(i)*dXin_dA + dYout_dYin(i)*dYin_dA);
        dbg.dXin_dA(i,:,:) = dXin_dA;
        dbg.dYin_dA(i,:,:) = dYin_dA;
        dbg.dXh_dA1 = V(i,:);
    end
    grad = squeeze(nanmean(gradi,1));
    C = nanmean(DVals.*W);
    dbg.dXout_dA = squeeze(nanmean(dbg.dXout_dA,1));
    dbg.dYout_dA = squeeze(nanmean(dbg.dYout_dA,1));
    dbg.dXin_dA = squeeze(nanmean(dbg.dXin_dA,1));
    dbg.dYin_dA = squeeze(nanmean(dbg.dYin_dA,1));
    dbg.dXh_dA1 = V(i,:);
    
    time = toc;
    fprintf('Calculating grad and cost took %3.2f seconds\n',time);
end