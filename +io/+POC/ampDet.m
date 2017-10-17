function [ doubleVin,LUTlp,LUThp, hLP, hHP, LUT250, LUT500 ] = ampDet( dt,curve_type )
%====== GIVEN: =======
wanted_f = [0.25,0.5];

%    inputamp   	curve 00	curve 01	curve 00	curve 01	curve 10	  curve 11	   curve 10	    curve 11
%                   250MHz  	250MHz    	500MHz    	500MHz	    250MHz	      250MHz	   500MHz	    500MHz
curves = ...
   [2.500000E-04,2.690000E-05,1.140000E-04,4.090000E-05,6.750000E-05,1.930000E-04,2.260000E-04,9.380000E-05,9.860000E-05;
    5.000000E-04,1.240000E-04,4.680000E-04,1.590000E-04,2.660000E-04,7.810000E-04,9.080000E-04,3.710000E-04,3.910000E-04;
    1.000000E-03,5.240000E-04,1.890000E-03,6.270000E-04,1.050000E-03,3.120000E-03,3.620000E-03,1.460000E-03,1.540000E-03;
    2.000000E-03,2.100000E-03,7.250000E-03,2.390000E-03,4.070000E-03,1.190000E-02,1.370000E-02,5.670000E-03,5.960000E-03;
    4.000000E-03,6.550000E-03,2.340000E-02,7.730000E-03,1.420000E-02,3.750000E-02,4.300000E-02,1.950000E-02,2.050000E-02;
    8.000000E-03,1.240000E-02,4.300000E-02,1.500000E-02,3.210000E-02,7.080000E-02,8.440000E-02,4.840000E-02,5.170000E-02;
    1.600000E-02,1.840000E-02,5.650000E-02,2.240000E-02,4.570000E-02,9.000000E-02,1.080000E-01,7.350000E-02,8.170000E-02;
    3.200000E-02,2.610000E-02,6.770000E-02,3.190000E-02,5.710000E-02,1.040000E-01,1.230000E-01,8.900000E-02,9.880000E-02;
    4.800000E-02,3.330000E-02,7.600000E-02,3.990000E-02,6.540000E-02,1.120000E-01,1.310000E-01,9.790000E-02,1.080000E-01;
    6.400000E-02,4.040000E-02,8.350000E-02,4.740000E-02,7.280000E-02,1.200000E-01,1.380000E-01,1.050000E-01,1.150000E-01;
    1.280000E-01,7.030000E-02,1.120000E-01,7.660000E-02,1.010000E-01,1.450000E-01,1.630000E-01,1.310000E-01,1.400000E-01;
    2.560000E-01,1.360000E-01,1.700000E-01,1.380000E-01,1.590000E-01,1.960000E-01,2.090000E-01,1.830000E-01,1.890000E-01];
start_col = [2 3 6 7];
Vin = curves(:,1);

% figure
% for curve_type=0:3
curve_num = curve_type+1;
LUT250 = curves(:,start_col(curve_num));
LUT500 = curves(:,start_col(curve_num)+2);

%scaling
LUT250 = (LUT250/LUT250(end))*Vin(end);
LUT500 = (LUT500/LUT500(end))*Vin(end);
% plot(Vin,LUT250);hold on
% end

LUT_arr = [LUT250 LUT500];



% ===== BUILD 2 COMPLEMENTARY LP & HP ======
Wco = 0.375;% middle of 0.25 & 0.5
[num0, den0]=butter(1,Wco/((1/dt)/2),'low'); %wanted LP

[d0,d1]=tf_2_ca(num0,den0); p0=fliplr(d0); p1=fliplr(d1);     % transfer function of filters in coupled-allpass scheme

%the wanted filters
hLP = (tf(p0,d0)+tf(p1,d1))/2;
hHP = (tf(p0,d0)-tf(p1,d1))/2;

% ======= BUILD THE LP & HP TRANSFORMATIONS =======
%get gain (complex)
kLP = freqz_(hLP.num{:},hLP.den{:},pi*wanted_f/((1/dt)/2));
kHP = freqz_(hHP.num{:},hHP.den{:},pi*wanted_f/((1/dt)/2));


%we have T250 & T500 and we want to find LUTlp & LUThp
%c are the gain in the specific freqs of the LP & HP s.t c1+c2 = 1 &
%c3+c4=1
% c1*LUTlp+c2*LUThp = T250
% c3*LUTlp+c4*LUThp = T500
%--->
c = [kLP.' kHP.'];
inv_c = inv(c);



% LUTlp = inv_c(1,1)*LUT250 +inv_c(1,2)*LUT500;
LUTlp = abs(inv_c(1,:)*LUT_arr.');
% LUThp = inv_c(2,1)*LUT250 +inv_c(2,2)*LUT500;
LUThp = abs(inv_c(2,:)*LUT_arr.');
% figure;plot(Vin,LUT250,Vin,LUTlp,Vin,LUThp)


LUTlp = [-fliplr(LUTlp), LUTlp];
LUThp = [-fliplr(LUThp), LUThp];


doubleVin = [-fliplr(Vin.') Vin.'];


end
