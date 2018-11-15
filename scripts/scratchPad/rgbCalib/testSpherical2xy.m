clear
load('regs.mat');
load('d.mat');
load('calibParams.mat');

dplus = Calibration.aux.CBTools.spherical2xy(d,regs,calibParams);


for i = 1:numel(d)
    tabplot;
    imagesc(normByMax(double(dplus(i).i)))
    hold on
    [p,~] = Calibration.aux.CBTools.findCheckerboard(normByMax(double(dplus(i).i)), [9,13]); % p - 3 checkerboard points. bsz - checkerboard dimensions.
    plot(p(:,1),p(:,2),'g*'); axis([0 640 0 480]);
    hold on
    plot(dplus(i).cbCorners(:,:,1),dplus(i).cbCorners(:,:,2),'r*'); axis([0 640 0 360]);
end