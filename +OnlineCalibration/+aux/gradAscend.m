function [uvRMS,params] = gradAscend(frame, params)
if size(frame.V,2) ~= 3
    frame.V = frame.V';
end
uvRMS(1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
[xAlpha,xBeta,zGamma] = OnlineCalibration.aux.extractAnglesFromRotMat(params.Rrgb);

% alpha = 0:0.00005*0.5:0.002;%(0:0.0005:0.02)*50;
cMaxPrev = -inf;
for k = 1:20
    initRgbPmat = params.rgbPmat;
    initRrgb = params.Rrgb;
    initTrgb = params.Trgb;
    initXAlpha = xAlpha;
    initYBeta = xBeta;
    initZGamma = zGamma;
    [C,gradStruct,dbg] = OnlineCalibration.aux.costGrad(initRgbPmat,frame.D,frame.Dx,frame.Dy,frame.W,frame.V,params.Krgb,params.rgbDistort,'ART',initRrgb,params.Trgb);
    normTgrad = gradStruct.T/norm(gradStruct.T);
    cParams = params;
    params.xAlpha = xAlpha;
    params.xBeta = xBeta;
    params.zGamma = zGamma;
    gradStruct.A(3,:) = 0;
    [alpha] = OnlineCalibration.aux.myBacktrackingLineSearch(1,0.5,0.5,gradStruct,params,frame.V,frame.W,frame.D);%pi()/180
    xAlpha = initXAlpha + alpha*gradStruct.xAlpha;
    xBeta = initYBeta + alpha*gradStruct.yBeta;
    zGamma = initZGamma + alpha*gradStruct.zGamma;
    Rrgb = OnlineCalibration.aux.calcRmatRromAngs(xAlpha,xBeta,zGamma);
    
    Trgb = initTrgb + alpha*normTgrad;
    cParams.rgbPmat = params.Krgb*[Rrgb,Trgb];
    C = OnlineCalibration.aux.calculateCost(frame.V,frame.W,frame.D,cParams);
    if isfield(params,'verbose') && params.verbose
        figure; plot(1:numel(C),C); title(['Cost in iteration # ' num2str(k)]);
    end
    %     [cMax,mI] = max(C);
    %     if cMax == cMaxPrev || cMax < cMaxPrev || mI == 1
    %         disp('Breaking out - cost reached max');
    %         break;
    %     end
    xAlpha = initXAlpha + alpha*gradStruct.xAlpha;
    xBeta = initYBeta + alpha*gradStruct.yBeta;
    zGamma = initZGamma + alpha*gradStruct.zGamma;
    params.Rrgb = OnlineCalibration.aux.calcRmatRromAngs(xAlpha,xBeta,zGamma);
    params.Trgb = initTrgb + alpha*normTgrad;
    RgbPmat = params.Krgb*[params.Rrgb,params.Trgb];
    
    params.rgbPmat = RgbPmat;
    params.rgbPmat = RgbPmat;
    uvRMS(k+1) = OnlineCalibration.Metrics.calcUVMappingErr(frame,params,0);
    fprintf('UV RMS = %2.2f. Cost = %f.\n',uvRMS(k),C);
    cMaxPrev = C;
end

end

