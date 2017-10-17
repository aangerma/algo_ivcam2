function lutOut = genJFILbiltGauss()

% 64 gaussians for spatial weights
% 6*64 -> 8bit

x = [1 11 25];
s = [0.28 0.5 3];
pSigma = polyfit(x, log(s), 2);
sigmas = exp(polyval(pSigma, 1:32));
% figure; plot(polyval(pSigma, 1:32)); hold on; plot(x, log(s), '+');
% figure; plot(sigmas); hold on; plot(x, s, '+');

% reverse the order to define index as sharpness
sigmas = fliplr(sigmas);

G = zeros(5,5,32);
G3 = zeros(13,13,32);
LUT = zeros(6,32, 'uint8');

for i=1:32
	f = fspecial('gaussian', 5, sigmas(i));
	F = round(f * 255 / max(f(:)));
	LUT(:,i) = uint8([F(3,3) F(2,2) F(1,1) F(2,1) F(3,2) F(3,1)]);
	G(:,:,i) = F;
	F3 = conv2(conv2(F,F),F);
	G3(:,:,i) = F3 / sum(F3(:)); 
end

%figure; mesh([G3(:,:,1) G3(:,:,2) G3(:,:,3); G3(:,:,4) G3(:,:,5) G3(:,:,6); G3(:,:,7) G3(:,:,8) G3(:,:,9)]);
% figure; mesh([G3(:,:,11) G3(:,:,12) G3(:,:,13); G3(:,:,14) G3(:,:,15) G3(:,:,16); G3(:,:,17) G3(:,:,18) G3(:,:,19)]);
%figure; mesh([G3(:,:,21) G3(:,:,22) G3(:,:,23); G3(:,:,24) G3(:,:,25) G3(:,:,26); G3(:,:,27) G3(:,:,28) G3(:,:,29)]);
%figure; mesh([G3(:,:,31) G3(:,:,32) G3(:,:,33); G3(:,:,34) G3(:,:,35) G3(:,:,36); G3(:,:,37) G3(:,:,38) G3(:,:,39)]);
%figure; mesh([G3(:,:,41) G3(:,:,42) G3(:,:,43); G3(:,:,44) G3(:,:,45) G3(:,:,46); G3(:,:,47) G3(:,:,48) G3(:,:,49)]);
%figure; mesh([G3(:,:,51) G3(:,:,52) G3(:,:,53); G3(:,:,54) G3(:,:,55) G3(:,:,56); G3(:,:,57) G3(:,:,58) G3(:,:,59)]);

% f = fopen('../JFILbiltGauss.lut', 'wt');
% fprintf(f,'%02x\n', LUT(:));
% fclose(f);

lutOut.lut = LUT;
lutOut.name = 'JFILbiltGauss';
end