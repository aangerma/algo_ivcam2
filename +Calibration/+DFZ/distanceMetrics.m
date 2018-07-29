function e = distanceMetrics(v,~,verbose)
[prms,ptsOpt ]=Calibration.getTargetParams();
genDmat = @(m) sqrt(sum((permute(m,[2 3 1])-permute(m,[3 2 1])).^2,3));
optMmat = genDmat(ptsOpt );
mesMmat = genDmat(v );
emat = (mesMmat-optMmat);
e = sqrt(mean(vec(emat.^2)));

if(verbose)
    figure(sum(double(mfilename)));
    c = max(abs(emat));
    rs = @(x) reshape(x,[prms.cornersY prms.cornersX]);
    surf(rs(v(1,:)),rs(v(2,:)),rs(v(3,:)),rs(c));colorbar;
    xlabel('dim_2');
    ylabel('dim_1')
    zlabel('dim_3')
    axis vis3d

end
end
