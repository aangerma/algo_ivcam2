vv = V4*(params.rgbPmat');
x = vv(:,1)./vv(:,3);
y = vv(:,2)./vv(:,3);


for i = 1:2
    for j = 1:4
        pmat = params.rgbPmat;
        pmat(i,j) = pmat(i,j) + 1;
        vvv = V4*(pmat');
        xx = vvv(:,1)./vvv(:,3);
        yy = vvv(:,2)./vvv(:,3);

        [nanmean(sqrt((xx-x).^2 + (yy-y).^2)),meanDrDVar(i,j)]
        
    end
end