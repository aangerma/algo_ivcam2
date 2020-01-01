j = 3000;
Vj = [0,0,0];
uvMap = projectVToRGB(Vj,camerasParams.rgbPmat,camerasParams.Krgb,camerasParams.rgbDistort);


% frames.D =  frames.D*0+linspace(0,1,1920);
initRgbPmat = camerasParams.rgbPmat;
[C,grad,dbg] = costGrad(initRgbPmat,frames.D,frames.Dx,frames.Dy,frames.W(j),Vj,camerasParams.Krgb,camerasParams.rgbDistort);

% Calc numeric grad
eps = 10^-3;
for i = 1:12
    cParams = camerasParams;
    cParams.rgbPmat(i) = cParams.rgbPmat(i) + eps; 
    Cplus = calculateCost(frames.V(j,:),frames.W(j),frames.D,cParams);
    [uvMapPlus(i,:),xyinPlus(i,1),xyinPlus(i,2),dbg] = projectVToRGB(Vj,cParams.rgbPmat,cParams.Krgb,cParams.rgbDistort);
    xhPlus(i,:) = dbg.uvh(1);
    
    cParams = camerasParams;
    cParams.rgbPmat(i) = cParams.rgbPmat(i) - eps; 
    Cminus = calculateCost(frames.V(j,:),frames.W(j),frames.D,cParams);
    cParams = camerasParams;
    g(i) = (Cplus-Cminus)/(2*eps);
    [uvMapMinus(i,:),xyinMinus(i,1),xyinMinus(i,2),dbg] = projectVToRGB(Vj,cParams.rgbPmat,cParams.Krgb,cParams.rgbDistort);
    xhMinus(i,:) = dbg.uvh(1);
    gUv(i,:) = (uvMapPlus(i,:)-uvMapMinus(i,:))/(2*eps);
    gXy(i,:) = (xyinPlus(i,:)-xyinMinus(i,:))/(2*eps);
    dxh(i,:) = (xhPlus(i,:)-xhMinus(i,:))/(2*eps);
end
g = reshape(g,3,4);

grad
g*10


dbg.dXout_dA
reshape(gUv(:,1),3,4)


dbg.dYout_dA
reshape(gUv(:,2),3,4)



dbg.dXin_dA
reshape(gXy(:,1),3,4)
dbg.dYin_dA
reshape(gXy(:,2),3,4)


