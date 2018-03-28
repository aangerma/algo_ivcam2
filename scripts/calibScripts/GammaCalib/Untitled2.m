base = 'PGStream_2018-02-26-112726-000';
ending = '.pgm';

I = zeros(2048,2048,10);
for i = 0:9
   path = [base num2str(i) ending];
   I(:,:,i+1) = imread(path);
   tabplot;
   imshow(I(:,:,i+1)),colormap gray
end
Im = max(I,[],3);
imagesc(Im)
imwrite(Im,'PGStreamNoLightsMax.pgm')