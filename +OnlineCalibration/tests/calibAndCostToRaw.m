function calibRaw = calibAndCostToRaw(params, cost)

K = params.Krgb;
R = params.Rrgb';
T = params.Trgb;

calibRaw = [K(1,1) K(2,2) K(1,3) K(2,3) ...     
R(:)' ...
T(:)' ...
cost];

end