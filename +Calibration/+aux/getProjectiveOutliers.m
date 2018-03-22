function [inliers] = getProjectiveOutliers(regs,angles)
%GETPROJECTIVEOUTLIERS get the angles for the checkerboard points, try to
%fit a projective transformation to them and returns the inliers map.
[xx,yy] = Pipe.DIGG.ang2xy(int16(angles(:,:,1)),int16(angles(:,:,2)),regs,[],[]);
xx = double(xx)/2^double(regs.DIGG.bitshift);
yy = double(yy)/2^double(regs.DIGG.bitshift);


p = [xx(:),yy(:)];
bsz = size(xx);

%build optimal grid
[yg,xg]=ndgrid(linspace(-1,1,bsz(1)),linspace(-1,1,bsz(2)));
inliers=true(numel(xg),1);
% In each iteration, fit an optimal grid by projective transformation. In
% Each iteration efine the outliers as the points which has an error of
% more then i pixels. Then repeat. At the end, we have only the points that
% differ in less than one pixel.
for i=[3,2,1,1,1,1,1]
    n=nnz(inliers);
    oo= [xg(inliers) yg(inliers) ones(n,1)];
    zr = zeros(n,3);
    h=[oo zr  -oo(:,1:2).*p(inliers,1);
        zr oo  -oo(:,1:2).*p(inliers,2)
        ];
    x   = h\vec(p(inliers,:));
    hh=reshape([x;1],3,3);
    d = [xg(:) yg(:) ones(numel(xg),1)]*hh;
    d=d(:,1:2)./d(:,3);
    
    ev = sqrt(sum((d-p).^2,2));
    inliers = ev<i;
%     tabplot; histogram(ev); xlabel('pixels')
end


% [~,~,~,inliers] = Calibration.aux.evalProjectiveDisotrtion([xx(:),yy(:)],size(xx));

end

