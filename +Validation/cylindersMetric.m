function [ResultTable,Cylinders] = cylindersMetric(vertices,Iir,distance,chartType)
    
    showFigs = 1;
    if exist('chartType','var')
        fidSizeMM = [50 100];
    else
        chartType = -1;
        fidSizeMM = [35 70];
    end
    [Vsize,Hsize] = size(Iir);
    
    %vertices
    Xcam = reshape(vertices(:,1),[Vsize,Hsize]);
    Ycam = reshape(vertices(:,2),[Vsize,Hsize]);
    Zcam = reshape(vertices(:,3),[Vsize,Hsize]);
    
    %chart configuration
    switch chartType
        case -1 %old chart
            heights = 6:3:15;
            diameters = 6:3:15;
        case 1 %6/9
            heights = [ 9 6 9 6];
            diameters = [6 6 9 9];
        case 2 %12/15
            heights = [ 15 12 15 12];
            diameters = [12 12 15 15];
    end
    
    
    %fidSizes
    HFOV=70;
    fidSizePix = round((Hsize/2)/(distance*tand(HFOV/2)).*fidSizeMM./2);
    fidSizes = max([fidSizePix'-10, fidSizePix'+15],10);
    

    
    Cylinders = [];
    ResultTable = cell(5,6);
    ResultTable(1,:) = {'Distance','Cylinder','Height','Diameter','Transition','Deformation'};
    ridx=2;
    [centersIn,radiiIn] = imfindcircles(double(Iir),fidSizes(1,:),'ObjectPolarity','Bright','Sensitivity',0.85);
    [centersOut,radiiOut] = imfindcircles(double(Iir),fidSizes(2,:),'ObjectPolarity','Dark','Sensitivity',0.9);
    
    Idxs = sortFiducials(centersOut);
    centersOut = centersOut(Idxs,:);
    radiiOut = radiiOut(Idxs,:);
    
    
    Idxs = zeros(size(centersOut,1),1);
    for i=1:size(centersOut,1)
        [~,Idxs(i)] = min(sum(abs(bsxfun(@minus,centersOut(i,:),centersIn)),2));
    end
    
    centersIn = centersIn(Idxs,:);
    radiiIn = radiiIn(Idxs);
    Idxs = find(centersOut(:,1)>450);
    centersOut(Idxs,:) = [];
    centersIn(Idxs,:) = [];
    radiiOut(Idxs,:) = [];
    radiiIn(Idxs,:) = [];
    centers = (centersOut+centersIn)./2;

    if showFigs
        figure(1);clf;
        imagesc(Iir);axis image;
        hold on
        viscircles(centersOut,radiiOut,'EdgeColor','k');
        viscircles(centersIn,radiiIn,'EdgeColor','r');
        for i=1:size(centersIn,1)
            text(centers(i,1), centers(i,2), sprintf('%d: H%d x D%d',i, heights(i),diameters(i)))
        end
        hold off
    end
    
    patchFactor = 1.4;
    fidSaftyOut = 3;
    fidSaftyIn = 0;
    innerRadFactor = 1;
    
    %for each  center
    for cidx=1:size(centers,1)
        center = centers(cidx,:);
        centerR = round(center);
        radius = round(radiiOut(cidx)*patchFactor);
        patchX = Xcam(centerR(2)-radius:centerR(2)+radius,centerR(1)-radius:centerR(1)+radius);
        patchY = Ycam(centerR(2)-radius:centerR(2)+radius,centerR(1)-radius:centerR(1)+radius);
        patchZ = Zcam(centerR(2)-radius:centerR(2)+radius,centerR(1)-radius:centerR(1)+radius);
        [px,py] = ndgrid(-radius:radius,-radius:radius);
        pr2 = px.^2+py.^2;
        patchX(pr2<(radiiOut(cidx)+fidSaftyOut).^2) = NaN;
        patchY(pr2<(radiiOut(cidx)+fidSaftyOut).^2) = NaN;
        patchZ(pr2<(radiiOut(cidx)+fidSaftyOut).^2) = NaN;
        
        [n,p] =  planeFitting([patchX(~isnan(patchZ)),patchY(~isnan(patchZ)),patchZ(~isnan(patchZ))]);
        rot = noraml2rotMat(n);
        innerRad = round(radiiIn(cidx)*innerRadFactor);
        dataX = Xcam(centerR(2)-innerRad:centerR(2)+innerRad,centerR(1)-innerRad:centerR(1)+innerRad)-p(1);
        dataY = Ycam(centerR(2)-innerRad:centerR(2)+innerRad,centerR(1)-innerRad:centerR(1)+innerRad)-p(2);
        dataZ = Zcam(centerR(2)-innerRad:centerR(2)+innerRad,centerR(1)-innerRad:centerR(1)+innerRad)-p(3);
        
        [px,py] = ndgrid(-innerRad:innerRad,-innerRad:innerRad);
        pr2 = px.^2+py.^2;
        dataX(pr2>(innerRad-fidSaftyIn).^2) = NaN;
        dataY(pr2>(innerRad-fidSaftyIn).^2) = NaN;
        dataZ(pr2>(innerRad-fidSaftyIn).^2) = NaN;
        
        data = [dataX(:),dataY(:),dataZ(:)]*rot;
        data(:,3) = -data(:,3);
        dataX = reshape(data(:,1),size(dataX));
        dataY = reshape(data(:,2),size(dataY));
        dataZ = reshape(data(:,3),size(dataZ));
        
        height = heights(cidx);
        diam = diameters(cidx);
        cylinderParam = [height diam/2 5 0 0 1 1];
        
        LB = [0 0 0.9 -4 -4 0.5 0.5];
        UB = [2*height diam 20 4 4 1.75 1.75];
        %LB = [0 0 0.7 -3 -3 0.25 0.25];
        %UB = [height+2 0.75*diam 20 3 3 2 2];
        fun = @(p)(errorFunc(data,p));
        %L1%fun = @(p) sum(abs(dataZ(~isnan(dataZ(:))) - cylinder_func(dataX(~isnan(dataZ(:))),dataY(~isnan(dataZ(:))),p)));
        opt_options = optimset('MaxIter',10000,'MaxFunEvals',10000);
        %[optParam,fminres] = fminsearch(fun,cylinderParam,opt_options);
        [optParam]=fminsearchbnd(fun,cylinderParam,LB,UB,opt_options);
        
        
        if showFigs
            [cylZ] = Validation.cylinder_func(dataX(:),dataY(:),optParam);
            GTparams = cylinderParam;
            GTparams(4:5) = optParam(4:5);
            [cylGT] = Validation.cylinder_func(dataX(:),dataY(:),GTparams);
            h = figure(1+cidx);clf;
            hold on
            surf(dataX,dataY,reshape(cylGT,size(dataZ)),zeros(size(dataZ))+5,'FaceAlpha',0.1);
            surf(dataX,dataY,dataZ,'FaceAlpha',0.7);axis equal,shading interp;
            surf(dataX,dataY,reshape(cylZ,size(dataZ)),ones(size(dataZ)),'FaceAlpha',0.3);
            title (sprintf('H %d x D %d',height,diam));
            hold off
            view([20 20])
            saveas(h,sprintf('cylinder%d_%d.png',height,diam));
        end
        
        Cylinders(cidx,:) = optParam;
        
        %{
        [X,Y] = ndgrid(-15:0.1:15, -15:0.1:15);
        [Z] = cylinder_func(X(:),Y(:),optParam.*[1 1 1 0 0  1 1]);
        Z = reshape (Z,size(X));
        line = round(length(X)/2);
        figure();plot(Y(line,:),Z(line,:));
        %}
        
        ResultTable{ridx,1} = distance;
        ResultTable{ridx,2} = sprintf('H %d x D %d',height,diam);
        ResultTable{ridx,3} = optParam(1);
        ResultTable{ridx,4} = optParam(2)*2;
        ResultTable{ridx,5} = (log(0.9)-log(0.1))./optParam(3)*sqrt(optParam(5).^2+optParam(6).^2);
        ResultTable{ridx,6} = abs(optParam(5)./optParam(6));
        ridx = ridx+1;
    end
    disp(ResultTable);
    disp(Cylinders);
end

function Idxs = sortFiducials(centers)
    Idxs = zeros(size(centers,1),1);
    distFromOrigin = centers(:,1).^2 + centers(:,2).^2;
    [~,didx] = sort(distFromOrigin);
    Idxs(1) = didx(1);
    
    if centers(didx(2),2) < centers(didx(3),2)
        Idxs(2) = didx(2);
        Idxs(3) = didx(3);
    else
        Idxs(2) = didx(3);
        Idxs(3) = didx(2);
    end
    Idxs(4) = didx(4);
    
end


function [n,p] =  planeFitting( M)
    
    p = mean(M,1);
    %The samples are reduced:
    R = bsxfun(@minus,M,p);
    %Computation of the principal directions if the samples cloud
    [V,D] = eig(R'*R);
    %Extract the output from the eigenvectors
    n = V(:,1)';
    %basis
    %V = V(:,2:end);
    
end

function roti = noraml2rotMat(n)
    b = acos(n(2) / sqrt(n(1)*n(1) + n(2)*n(2)));
    bwinkel = b * 360 / 2 / pi;
    if (n(1) >= 0)
        rotb = [cos(-b) -sin(-b) 0; sin(-b) cos(-b) 0; 0 0 1];
    else
        rotb = [cos(-b) sin(-b) 0; -sin(-b) cos(-b) 0; 0 0 1];
    end
    n2 = n * rotb;
    a = acos(n2(3) / sqrt(n2(2)*n2(2) + n2(3)*n2(3)));
    awinkel = a * 360 / 2 / pi;
    rota = [1 0 0; 0 cos(-a) -sin(-a); 0 sin(-a) cos(-a)];
    roti = rotb * rota;
end

function err = errorFunc(data,p)
    dataX = data(:,1);
    dataY = data(:,2);
    dataZ = data(:,3);
    idxs = find(~isnan(dataZ));
    [cylinder,~,weightId] = Validation.cylinder_func(dataX,dataY,p);
    weights = weightId*0;
    weights(weightId == 1) = 2;
    weights(weightId == 2) = 1;
    weights(weightId == 3) = 1;
    errL1 = abs(dataZ(idxs) - cylinder(idxs)).*weights(idxs);
    errL2 = (dataZ(idxs) - cylinder(idxs)).^2.*weights(idxs);
    err = sum(errL2(weightId(idxs) ==1 | weightId(idxs) == 3)) +  sum(errL2(weightId(idxs) ==2));
end
