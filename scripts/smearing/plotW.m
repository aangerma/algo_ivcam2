%%
www = zeros([size(irMM),9],'uint16');
IrPatch = zeros([size(irMM),9],'uint16');
for i = 1:9
    wImg = zeros(size(irMM),'uint16');
    IrIm =  zeros(size(irMM),'uint16');
    wImg(pxindOut) = squeeze(cmafWin.w(i,:));
    IrIm(pxindOut) = squeeze(cmafWin.ir(i,:));
    www(:,:,i) = wImg;
    IrPatch(:,:,i) = IrIm;
end
row = 131;
col = 159;
Ipatch = reshape(www(row,col,:),3,3)';
% a = reshape(www(row,col+1,:),3,3)';
% Ipatch(1,:) = a(1,:);
figure,imagesc(Ipatch,[0,255]); impixelinfo; title(['W for center at [X,Y]=[' num2str(col) ',' num2str(row) ']']);
% figure,imagesc(reshape(www(row,col,:),3,3)',[0,255]); impixelinfo;
IpatchIr = reshape(IrPatch(row,col,:),3,3)';
figure;imagesc(IpatchIr); impixelinfo; title(['IR for center at [X,Y]=[' num2str(col) ',' num2str(row) ']']);
%%